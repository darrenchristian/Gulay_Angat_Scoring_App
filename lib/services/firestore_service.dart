import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/models.dart';

/// Pure Cloud Firestore service managing events, criteria, contestants,
/// global judges pool, event-judge linking, and real-time score submissions.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Object _currentGeneration = Object();

  static void resetGeneration() {
    _currentGeneration = Object();
  }

  /// Wraps a Firestore stream so that if Flutter Web hot-restarts and disposes
  /// the previous generation's FlutterView, the underlying JS listener is
  /// immediately cancelled instead of triggering builds on a disposed view.
  Stream<T> _safeStream<T>(Stream<T> source) {
    final generation = _currentGeneration;
    late StreamController<T> controller;
    StreamSubscription<T>? sub;

    bool isGenerationAlive() {
      if (!identical(generation, _currentGeneration)) return false;
      try {
        final dispatcher = WidgetsBinding.instance.platformDispatcher;
        if (dispatcher.views.isEmpty && dispatcher.implicitView == null) {
          return false;
        }
      } catch (_) {
        return false;
      }
      return true;
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        sub = source.listen(
          (data) {
            if (!isGenerationAlive()) {
              sub?.cancel();
              sub = null;
              if (!controller.isClosed) controller.close();
              return;
            }
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!isGenerationAlive()) {
              sub?.cancel();
              sub = null;
              if (!controller.isClosed) controller.close();
              return;
            }
            if (!controller.isClosed) {
              controller.addError(error, stack);
            }
          },
        );
      },
      onCancel: () {
        sub?.cancel();
        sub = null;
      },
    );
    return controller.stream;
  }

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final part = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'JDG-$part';
  }

  // ------------------ EVENTS ------------------ //
  Stream<List<EventModel>> getEventsStream() {
    return _safeStream(
      _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList()),
    );
  }

  Stream<EventModel?> getEventStream(String eventId) {
    return _safeStream(
      _firestore
          .collection('events')
          .doc(eventId)
          .snapshots()
          .map((doc) => doc.exists ? EventModel.fromFirestore(doc) : null),
    );
  }

  /// Streams all events to which a specific judge is assigned.
  Stream<List<EventModel>> getAssignedEventsForJudgeStream(String judgeId) {
    return getEventsStream().map(
      (events) => events
          .where((e) => e.assignedJudgeIds.contains(judgeId))
          .toList(),
    );
  }

  Future<String> createEvent(EventModel event) async {
    final docRef = await _firestore.collection('events').add(event.toMap());
    return docRef.id;
  }

  Future<void> updateEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _firestore.collection('events').doc(eventId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Links/assigns a list of global Judge IDs to a specific event.
  /// Judges who are currently linked and have already submitted scores are locked
  /// and cannot be unlinked.
  Future<void> updateEventJudges(String eventId, List<String> judgeIds) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final eventSnap = await eventRef.get();
    final currentlyAssigned = (eventSnap.data()?['assignedJudgeIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    final scoresSnap = await eventRef.collection('scores').get();
    final lockedJudgeIds = <String>{};
    for (final scoreDoc in scoresSnap.docs) {
      final data = scoreDoc.data();
      final scoreJudgeId = data['judgeId']?.toString() ?? '';
      final isSubmitted = data['isSubmitted'] == true;
      if (isSubmitted && currentlyAssigned.contains(scoreJudgeId)) {
        lockedJudgeIds.add(scoreJudgeId);
      }
    }

    final finalJudgeIds = {...judgeIds, ...lockedJudgeIds}.toList();
    await eventRef.update({
      'assignedJudgeIds': finalJudgeIds,
      'judgeCount': finalJudgeIds.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final validSet = finalJudgeIds.toSet();
    final batch = _firestore.batch();
    bool hasDeletes = false;
    for (final scoreDoc in scoresSnap.docs) {
      final scoreJudgeId = scoreDoc.data()['judgeId']?.toString() ?? '';
      if (!validSet.contains(scoreJudgeId)) {
        batch.delete(scoreDoc.reference);
        hasDeletes = true;
      }
    }
    if (hasDeletes) {
      await batch.commit();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // ------------------ CRITERIA ------------------ //
  Stream<List<CriterionModel>> getCriteriaStream(String eventId) {
    return _safeStream(
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('criteria')
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => CriterionModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) {
          final cmp = a.order.compareTo(b.order);
          if (cmp != 0) return cmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return list;
      }),
    );
  }

  Future<void> addCriterion(CriterionModel criterion) async {
    final col = _firestore
        .collection('events')
        .doc(criterion.eventId)
        .collection('criteria');

    int targetOrder = criterion.order;
    if (targetOrder <= 0) {
      final existing = await col.get();
      if (existing.docs.isNotEmpty) {
        int maxOrder = -1;
        for (final doc in existing.docs) {
          final o = (doc.data()['order'] as num?)?.toInt() ?? 0;
          if (o > maxOrder) maxOrder = o;
        }
        targetOrder = maxOrder + 1;
      } else {
        targetOrder = 0;
      }
    }

    final data = criterion.toMap()..['order'] = targetOrder;

    if (criterion.id.isEmpty) {
      await col.add(data);
    } else {
      await col.doc(criterion.id).set(data);
    }
  }

  Future<void> updateCriterion(CriterionModel criterion) async {
    await _firestore
        .collection('events')
        .doc(criterion.eventId)
        .collection('criteria')
        .doc(criterion.id)
        .update(criterion.toMap());
  }

  Future<void> reorderCriteria(
    String eventId,
    List<CriterionModel> orderedCriteria,
  ) async {
    final batch = _firestore.batch();
    final col = _firestore
        .collection('events')
        .doc(eventId)
        .collection('criteria');

    for (int i = 0; i < orderedCriteria.length; i++) {
      final crit = orderedCriteria[i];
      if (crit.id.isNotEmpty) {
        batch.update(col.doc(crit.id), {'order': i});
      }
    }
    await batch.commit();
  }

  Future<void> deleteCriterion(String eventId, String criterionId) async {
    final col = _firestore
        .collection('events')
        .doc(eventId)
        .collection('criteria');
    await col.doc(criterionId).delete();

    // Normalize remaining criteria order
    final remainingSnap = await col.orderBy('order').get();
    if (remainingSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (int i = 0; i < remainingSnap.docs.length; i++) {
        batch.update(remainingSnap.docs[i].reference, {'order': i});
      }
      await batch.commit();
    }
  }

  // ------------------ CONTESTANTS ------------------ //
  Stream<List<ContestantModel>> getContestantsStream(String eventId) {
    return _safeStream(
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('contestants')
          .orderBy('number')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ContestantModel.fromFirestore(doc)).toList()),
    );
  }

  Future<void> addContestant(ContestantModel contestant) async {
    final col = _firestore
        .collection('events')
        .doc(contestant.eventId)
        .collection('contestants');

    if (contestant.id.isEmpty) {
      await col.add(contestant.toMap());
    } else {
      await col.doc(contestant.id).set(contestant.toMap());
    }
  }

  Future<void> updateContestant(ContestantModel contestant) async {
    await _firestore
        .collection('events')
        .doc(contestant.eventId)
        .collection('contestants')
        .doc(contestant.id)
        .update(contestant.toMap());
  }

  Future<void> deleteContestant(String eventId, String contestantId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('contestants')
        .doc(contestantId)
        .delete();
  }

  // ------------------ GLOBAL JUDGES POOL & EVENT LINKING ------------------ //
  /// Streams all global judges from the top-level `judges` collection.
  Stream<List<JudgeModel>> getGlobalJudgesStream() {
    return _safeStream(
      _firestore
          .collection('judges')
          .orderBy('judgeNumber')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => JudgeModel.fromFirestore(doc)).toList()),
    );
  }

  /// Creates a single global judge in the pool and indexes their access code.
  Future<JudgeModel> createGlobalJudge({
    required String name,
    int? judgeNumber,
  }) async {
    int nextNum = judgeNumber ?? 1;
    if (judgeNumber == null) {
      final existing = await _firestore.collection('judges').get();
      nextNum = existing.docs.length + 1;
    }

    final accessCode = _generateUniqueCode();
    final judgeDocRef = _firestore.collection('judges').doc();

    final judge = JudgeModel(
      id: judgeDocRef.id,
      judgeNumber: nextNum,
      accessCode: accessCode,
      name: name.trim().isNotEmpty ? name.trim() : 'Judge #$nextNum',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(judgeDocRef, judge.toMap());

    final lookupRef = _firestore.collection('judge_codes').doc(accessCode);
    batch.set(lookupRef, {
      'judgeId': judgeDocRef.id,
      'judgeNumber': nextNum,
      'name': judge.name,
      'isActive': true,
      'accessCode': accessCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return judge;
  }

  /// Batch-generates global judge accounts in the top-level `judges` pool.
  Future<List<JudgeModel>> generateGlobalJudgesBatch({
    required int count,
  }) async {
    final existingSnap = await _firestore.collection('judges').get();
    int startNum = existingSnap.docs.length + 1;

    final List<JudgeModel> generated = [];
    final batch = _firestore.batch();

    for (int i = 0; i < count; i++) {
      final num = startNum + i;
      final accessCode = _generateUniqueCode();
      final judgeDocRef = _firestore.collection('judges').doc();

      final judge = JudgeModel(
        id: judgeDocRef.id,
        judgeNumber: num,
        accessCode: accessCode,
        name: 'Judge #$num',
        isActive: true,
        createdAt: DateTime.now(),
      );

      batch.set(judgeDocRef, judge.toMap());

      final lookupRef = _firestore.collection('judge_codes').doc(accessCode);
      batch.set(lookupRef, {
        'judgeId': judgeDocRef.id,
        'judgeNumber': num,
        'name': judge.name,
        'isActive': true,
        'accessCode': accessCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      generated.add(judge);
    }

    await batch.commit();
    return generated;
  }

  /// Streams the judges linked to a specific event by watching both the event's
  /// `assignedJudgeIds` and the global `judges` pool.
  Stream<List<JudgeModel>> getJudgesStream(String eventId) {
    late StreamController<List<JudgeModel>> controller;
    StreamSubscription? eventSub;
    StreamSubscription? globalJudgesSub;

    List<String> currentAssignedIds = [];
    List<JudgeModel> allGlobalJudges = [];
    bool hasEventData = false;
    bool hasJudgesData = false;

    void emitCombined() {
      if (!hasEventData || !hasJudgesData) return;
      if (controller.isClosed) return;

      final linked = allGlobalJudges
          .where((j) => currentAssignedIds.contains(j.id))
          .toList();
      linked.sort((a, b) => a.judgeNumber.compareTo(b.judgeNumber));
      controller.add(linked);
    }

    controller = StreamController<List<JudgeModel>>.broadcast(
      onListen: () {
        eventSub = getEventStream(eventId).listen((ev) {
          currentAssignedIds = ev?.assignedJudgeIds ?? [];
          hasEventData = true;
          emitCombined();
        });

        globalJudgesSub = getGlobalJudgesStream().listen((judges) {
          allGlobalJudges = judges;
          hasJudgesData = true;
          emitCombined();
        });
      },
      onCancel: () {
        eventSub?.cancel();
        globalJudgesSub?.cancel();
      },
    );

    return _safeStream(controller.stream);
  }

  Future<void> updateJudge(JudgeModel judge) async {
    final batch = _firestore.batch();
    final judgeRef = _firestore.collection('judges').doc(judge.id);

    batch.set(judgeRef, judge.toMap(), SetOptions(merge: true));

    final lookupRef = _firestore.collection('judge_codes').doc(judge.accessCode);
    batch.set(
      lookupRef,
      {
        'judgeId': judge.id,
        'judgeNumber': judge.judgeNumber,
        'name': judge.name,
        'isActive': judge.isActive,
        'accessCode': judge.accessCode,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> deleteGlobalJudge(JudgeModel judge) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('judges').doc(judge.id));
    batch.delete(_firestore.collection('judge_codes').doc(judge.accessCode));

    final eventsSnap = await _firestore.collection('events').get();
    for (final eventDoc in eventsSnap.docs) {
      final rawAssigned = (eventDoc.data()['assignedJudgeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      if (rawAssigned.contains(judge.id)) {
        rawAssigned.remove(judge.id);
        batch.update(eventDoc.reference, {
          'assignedJudgeIds': rawAssigned,
          'judgeCount': rawAssigned.length,
        });
      }

      final scoresSnap = await eventDoc.reference
          .collection('scores')
          .where('judgeId', isEqualTo: judge.id)
          .get();
      for (final scoreDoc in scoresSnap.docs) {
        batch.delete(scoreDoc.reference);
      }
    }

    await batch.commit();
  }

  // ------------------ SCORES & REALTIME CONSOLIDATION ------------------ //
  Stream<List<ScoreSubmissionModel>> getScoresStream(String eventId) {
    return _safeStream(
      _firestore
          .collection('events')
          .doc(eventId)
          .collection('scores')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.docs
              .map((doc) => ScoreSubmissionModel.fromFirestore(doc))
              .toList()),
    );
  }

  /// Pre-fetches event criteria, contestants, and scores into Firestore's local
  /// disk cache so the Judge can continue scoring seamlessly if Wi-Fi drops.
  Future<void> warmUpEventCache(String eventId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      await Future.wait([
        eventRef.get().timeout(const Duration(seconds: 3)),
        eventRef.collection('criteria').orderBy('order').get().timeout(const Duration(seconds: 3)),
        eventRef.collection('contestants').orderBy('number').get().timeout(const Duration(seconds: 3)),
        eventRef.collection('scores').get().timeout(const Duration(seconds: 3)),
      ]);
    } catch (_) {
      // Ignore timeouts when already offline; local cache will be used automatically.
    }
  }

  /// Deletes specific score documents from an event (e.g., orphaned scores from unlinked/deleted judges).
  Future<void> deleteScoresByIds(String eventId, List<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    final batch = _firestore.batch();
    final scoresCol = _firestore.collection('events').doc(eventId).collection('scores');
    for (final id in scoreIds) {
      batch.delete(scoresCol.doc(id));
    }
    await batch.commit();
  }

  /// Resets (deletes) all score submissions for a specific judge in an event
  /// and stamps `judgeResetAt.<judgeId>` so stale offline scores from before the reset are ignored.
  Future<void> resetJudgeScoresForEvent({
    required String eventId,
    required String judgeId,
  }) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final scoresSnap = await eventRef
        .collection('scores')
        .where('judgeId', isEqualTo: judgeId)
        .get();

    final batch = _firestore.batch();
    batch.update(eventRef, {
      'judgeResetAt.$judgeId': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final doc in scoresSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Resets (deletes) all score submissions across all judges in an event
  /// and stamps `scoresResetAt` so stale offline scores from before the reset are ignored.
  Future<void> resetAllScoresForEvent(String eventId) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final scoresSnap = await eventRef.collection('scores').get();

    final batch = _firestore.batch();
    batch.update(eventRef, {
      'scoresResetAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final doc in scoresSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Submits or updates a judge's scorecard for a specific contestant.
  /// Uses a deterministic docId `{contestantId}_{judgeId}` to guarantee idempotency.
  ///
  /// Returns `true` if acknowledged by the cloud server right away, or `false`
  /// if saved to the local offline cache and queued for automatic background sync.
  Future<bool> submitScore(ScoreSubmissionModel score) async {
    final docId = ScoreSubmissionModel.generateId(
      contestantId: score.contestantId,
      judgeId: score.judgeId,
    );

    final writeFuture = _firestore
        .collection('events')
        .doc(score.eventId)
        .collection('scores')
        .doc(docId)
        .set(score.toMap(), SetOptions(merge: true));

    try {
      await writeFuture.timeout(const Duration(milliseconds: 1800));
      return true;
    } on TimeoutException {
      // Firestore has already written the score to local cache and queued it for sync.
      return false;
    }
  }
}
