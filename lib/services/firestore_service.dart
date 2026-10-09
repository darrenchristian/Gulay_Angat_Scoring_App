import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initSampleData();
  }

  bool get _isFirebaseActive => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // In-memory store for offline/demo/pre-configured state
  final List<EventModel> _memEvents = [];
  final Map<String, List<CriterionModel>> _memCriteria = {};
  final Map<String, List<ContestantModel>> _memContestants = {};
  final Map<String, List<JudgeModel>> _memJudges = {};
  final Map<String, List<ScoreSubmissionModel>> _memScores = {};
  final Map<String, Map<String, dynamic>> _memJudgeCodes = {};

  final _eventsStreamController = StreamController<List<EventModel>>.broadcast();
  final Map<String, StreamController<List<CriterionModel>>> _criteriaControllers = {};
  final Map<String, StreamController<List<ContestantModel>>> _contestantControllers = {};
  final Map<String, StreamController<List<JudgeModel>>> _judgeControllers = {};
  final Map<String, StreamController<List<ScoreSubmissionModel>>> _scoreControllers = {};

  void _initSampleData() {
    final sampleEvent = EventModel(
      id: 'event-demo-1',
      title: 'Grand Talent Showcase 2026',
      description: 'Annual inter-department talent and creativity competition.',
      status: EventStatus.active,
      judgeCount: 3,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    _memEvents.add(sampleEvent);

    // Sample Criteria (Sum to 100%)
    _memCriteria[sampleEvent.id] = [
      CriterionModel(
        id: 'crit-1',
        eventId: sampleEvent.id,
        name: 'Talent & Technique',
        description: 'Execution, difficulty, and skill mastery.',
        maxScore: 40.0,
        weightPercentage: 40.0,
        order: 1,
      ),
      CriterionModel(
        id: 'crit-2',
        eventId: sampleEvent.id,
        name: 'Stage Presence & Poise',
        description: 'Confidence, personality, and charisma on stage.',
        maxScore: 30.0,
        weightPercentage: 30.0,
        order: 2,
      ),
      CriterionModel(
        id: 'crit-3',
        eventId: sampleEvent.id,
        name: 'Creativity & Originality',
        description: 'Uniqueness and creative interpretation.',
        maxScore: 30.0,
        weightPercentage: 30.0,
        order: 3,
      ),
    ];

    // Sample Contestants
    _memContestants[sampleEvent.id] = [
      ContestantModel(
        id: 'cont-1',
        eventId: sampleEvent.id,
        number: 1,
        name: 'Aria Montgomery',
        representation: 'College of Arts & Sciences',
        bio: 'Contemporary vocalist and acoustic composer.',
      ),
      ContestantModel(
        id: 'cont-2',
        eventId: sampleEvent.id,
        number: 2,
        name: 'The Kinetic Crew',
        representation: 'College of Engineering',
        bio: 'Robotic and hip-hop fusion dance squad.',
      ),
      ContestantModel(
        id: 'cont-3',
        eventId: sampleEvent.id,
        number: 3,
        name: 'Lucas Vance',
        representation: 'Business Administration',
        bio: 'Classical violin soloist with modern synth arrangement.',
      ),
    ];

    // Sample Judges
    final j1 = JudgeModel(
      id: 'judge-1',
      eventId: sampleEvent.id,
      judgeNumber: 1,
      accessCode: 'JDG-DEMO1',
      name: 'Judge #1 (Chief)',
      createdAt: DateTime.now(),
    );
    final j2 = JudgeModel(
      id: 'judge-2',
      eventId: sampleEvent.id,
      judgeNumber: 2,
      accessCode: 'JDG-DEMO2',
      name: 'Judge #2',
      createdAt: DateTime.now(),
    );
    final j3 = JudgeModel(
      id: 'judge-3',
      eventId: sampleEvent.id,
      judgeNumber: 3,
      accessCode: 'JDG-DEMO3',
      name: 'Judge #3',
      createdAt: DateTime.now(),
    );

    _memJudges[sampleEvent.id] = [j1, j2, j3];

    for (final j in [j1, j2, j3]) {
      _memJudgeCodes[j.accessCode] = {
        'eventId': sampleEvent.id,
        'judgeId': j.id,
        'judgeNumber': j.judgeNumber,
        'name': j.name,
        'isActive': true,
        'accessCode': j.accessCode,
      };
    }

    _memScores[sampleEvent.id] = [];
  }

  // ------------------ EVENTS ------------------ //
  Stream<List<EventModel>> getEventsStream() {
    if (_isFirebaseActive) {
      return _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
    }

    // Deliver in-memory stream
    Future.microtask(() => _eventsStreamController.add(List.from(_memEvents)));
    return _eventsStreamController.stream;
  }

  Future<String> createEvent(EventModel event) async {
    if (_isFirebaseActive) {
      final docRef = await _firestore.collection('events').add(event.toMap());
      return docRef.id;
    }

    final id = 'event-${DateTime.now().millisecondsSinceEpoch}';
    final newEvent = event.copyWith(id: id);
    _memEvents.insert(0, newEvent);
    _memCriteria[id] = [];
    _memContestants[id] = [];
    _memJudges[id] = [];
    _memScores[id] = [];
    _eventsStreamController.add(List.from(_memEvents));
    return id;
  }

  Future<void> updateEvent(EventModel event) async {
    if (_isFirebaseActive) {
      await _firestore.collection('events').doc(event.id).update(event.toMap());
      return;
    }

    final index = _memEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _memEvents[index] = event;
      _eventsStreamController.add(List.from(_memEvents));
    }
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    if (_isFirebaseActive) {
      await _firestore.collection('events').doc(eventId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final index = _memEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _memEvents[index] = _memEvents[index].copyWith(status: status);
      _eventsStreamController.add(List.from(_memEvents));
    }
  }

  Future<void> deleteEvent(String eventId) async {
    if (_isFirebaseActive) {
      await _firestore.collection('events').doc(eventId).delete();
      return;
    }

    _memEvents.removeWhere((e) => e.id == eventId);
    _eventsStreamController.add(List.from(_memEvents));
  }

  Future<EventModel?> getEvent(String eventId) async {
    if (_isFirebaseActive) {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    }

    try {
      return _memEvents.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return null;
    }
  }

  // ------------------ CRITERIA ------------------ //
  Stream<List<CriterionModel>> getCriteriaStream(String eventId) {
    if (_isFirebaseActive) {
      return _firestore
          .collection('events')
          .doc(eventId)
          .collection('criteria')
          .orderBy('order')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => CriterionModel.fromFirestore(doc)).toList());
    }

    _criteriaControllers.putIfAbsent(eventId, () => StreamController<List<CriterionModel>>.broadcast());
    Future.microtask(() {
      _criteriaControllers[eventId]?.add(List.from(_memCriteria[eventId] ?? []));
    });
    return _criteriaControllers[eventId]!.stream;
  }

  Future<void> addCriterion(CriterionModel criterion) async {
    if (_isFirebaseActive) {
      final col = _firestore
          .collection('events')
          .doc(criterion.eventId)
          .collection('criteria');

      if (criterion.id.isEmpty) {
        await col.add(criterion.toMap());
      } else {
        await col.doc(criterion.id).set(criterion.toMap());
      }
      return;
    }

    final list = _memCriteria.putIfAbsent(criterion.eventId, () => []);
    final id = criterion.id.isEmpty ? 'crit-${DateTime.now().millisecondsSinceEpoch}' : criterion.id;
    list.add(criterion.copyWith(id: id));
    _criteriaControllers[criterion.eventId]?.add(List.from(list));
  }

  Future<void> updateCriterion(CriterionModel criterion) async {
    if (_isFirebaseActive) {
      await _firestore
          .collection('events')
          .doc(criterion.eventId)
          .collection('criteria')
          .doc(criterion.id)
          .update(criterion.toMap());
      return;
    }

    final list = _memCriteria[criterion.eventId];
    if (list != null) {
      final idx = list.indexWhere((c) => c.id == criterion.id);
      if (idx != -1) {
        list[idx] = criterion;
        _criteriaControllers[criterion.eventId]?.add(List.from(list));
      }
    }
  }

  Future<void> deleteCriterion(String eventId, String criterionId) async {
    if (_isFirebaseActive) {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('criteria')
          .doc(criterionId)
          .delete();
      return;
    }

    final list = _memCriteria[eventId];
    if (list != null) {
      list.removeWhere((c) => c.id == criterionId);
      _criteriaControllers[eventId]?.add(List.from(list));
    }
  }

  // ------------------ CONTESTANTS ------------------ //
  Stream<List<ContestantModel>> getContestantsStream(String eventId) {
    if (_isFirebaseActive) {
      return _firestore
          .collection('events')
          .doc(eventId)
          .collection('contestants')
          .orderBy('number')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ContestantModel.fromFirestore(doc)).toList());
    }

    _contestantControllers.putIfAbsent(eventId, () => StreamController<List<ContestantModel>>.broadcast());
    Future.microtask(() {
      _contestantControllers[eventId]?.add(List.from(_memContestants[eventId] ?? []));
    });
    return _contestantControllers[eventId]!.stream;
  }

  Future<void> addContestant(ContestantModel contestant) async {
    if (_isFirebaseActive) {
      final col = _firestore
          .collection('events')
          .doc(contestant.eventId)
          .collection('contestants');

      if (contestant.id.isEmpty) {
        await col.add(contestant.toMap());
      } else {
        await col.doc(contestant.id).set(contestant.toMap());
      }
      return;
    }

    final list = _memContestants.putIfAbsent(contestant.eventId, () => []);
    final id = contestant.id.isEmpty ? 'cont-${DateTime.now().millisecondsSinceEpoch}' : contestant.id;
    list.add(contestant.copyWith(id: id));
    _contestantControllers[contestant.eventId]?.add(List.from(list));
  }

  Future<void> updateContestant(ContestantModel contestant) async {
    if (_isFirebaseActive) {
      await _firestore
          .collection('events')
          .doc(contestant.eventId)
          .collection('contestants')
          .doc(contestant.id)
          .update(contestant.toMap());
      return;
    }

    final list = _memContestants[contestant.eventId];
    if (list != null) {
      final idx = list.indexWhere((c) => c.id == contestant.id);
      if (idx != -1) {
        list[idx] = contestant;
        _contestantControllers[contestant.eventId]?.add(List.from(list));
      }
    }
  }

  Future<void> deleteContestant(String eventId, String contestantId) async {
    if (_isFirebaseActive) {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('contestants')
          .doc(contestantId)
          .delete();
      return;
    }

    final list = _memContestants[eventId];
    if (list != null) {
      list.removeWhere((c) => c.id == contestantId);
      _contestantControllers[eventId]?.add(List.from(list));
    }
  }

  // ------------------ JUDGES & UNIQUE ACCESS IDS ------------------ //
  Stream<List<JudgeModel>> getJudgesStream(String eventId) {
    if (_isFirebaseActive) {
      return _firestore
          .collection('events')
          .doc(eventId)
          .collection('judges')
          .orderBy('judgeNumber')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => JudgeModel.fromFirestore(doc)).toList());
    }

    _judgeControllers.putIfAbsent(eventId, () => StreamController<List<JudgeModel>>.broadcast());
    Future.microtask(() {
      _judgeControllers[eventId]?.add(List.from(_memJudges[eventId] ?? []));
    });
    return _judgeControllers[eventId]!.stream;
  }

  Future<List<JudgeModel>> generateJudgesForEvent({
    required String eventId,
    required int count,
  }) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final List<JudgeModel> generated = [];

    if (_isFirebaseActive) {
      final batch = _firestore.batch();
      for (int i = 1; i <= count; i++) {
        final randomPart = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
        final accessCode = 'JDG-$randomPart';

        final judgeDocRef = _firestore
            .collection('events')
            .doc(eventId)
            .collection('judges')
            .doc();

        final judge = JudgeModel(
          id: judgeDocRef.id,
          eventId: eventId,
          judgeNumber: i,
          accessCode: accessCode,
          name: 'Judge #$i',
          isActive: true,
          createdAt: DateTime.now(),
        );

        batch.set(judgeDocRef, judge.toMap());

        final lookupRef = _firestore.collection('judge_codes').doc(accessCode);
        batch.set(lookupRef, {
          'eventId': eventId,
          'judgeId': judgeDocRef.id,
          'judgeNumber': i,
          'name': judge.name,
          'isActive': true,
          'accessCode': accessCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        generated.add(judge);
      }

      final eventRef = _firestore.collection('events').doc(eventId);
      batch.update(eventRef, {
        'judgeCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return generated;
    }

    // In-memory generation
    final list = <JudgeModel>[];
    for (int i = 1; i <= count; i++) {
      final randomPart = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
      final accessCode = 'JDG-$randomPart';
      final judge = JudgeModel(
        id: 'judge-$i-${DateTime.now().millisecondsSinceEpoch}',
        eventId: eventId,
        judgeNumber: i,
        accessCode: accessCode,
        name: 'Judge #$i',
        isActive: true,
        createdAt: DateTime.now(),
      );
      list.add(judge);
      _memJudgeCodes[accessCode] = {
        'eventId': eventId,
        'judgeId': judge.id,
        'judgeNumber': i,
        'name': judge.name,
        'isActive': true,
        'accessCode': accessCode,
      };
    }

    _memJudges[eventId] = list;
    _judgeControllers[eventId]?.add(List.from(list));

    // Update event judge count
    final evIndex = _memEvents.indexWhere((e) => e.id == eventId);
    if (evIndex != -1) {
      _memEvents[evIndex] = _memEvents[evIndex].copyWith(judgeCount: count);
      _eventsStreamController.add(List.from(_memEvents));
    }

    return list;
  }

  Future<void> updateJudge(JudgeModel judge) async {
    if (_isFirebaseActive) {
      final batch = _firestore.batch();
      final judgeRef = _firestore
          .collection('events')
          .doc(judge.eventId)
          .collection('judges')
          .doc(judge.id);

      batch.update(judgeRef, judge.toMap());

      final lookupRef = _firestore.collection('judge_codes').doc(judge.accessCode);
      batch.update(lookupRef, {
        'name': judge.name,
        'isActive': judge.isActive,
      });

      await batch.commit();
      return;
    }

    final list = _memJudges[judge.eventId];
    if (list != null) {
      final idx = list.indexWhere((j) => j.id == judge.id);
      if (idx != -1) {
        list[idx] = judge;
        _judgeControllers[judge.eventId]?.add(List.from(list));
      }
    }
  }

  // Helper for lookup of judge codes
  Map<String, dynamic>? getMemJudgeCode(String code) => _memJudgeCodes[code];

  // ------------------ SCORES & REALTIME CONSOLIDATION ------------------ //
  Stream<List<ScoreSubmissionModel>> getScoresStream(String eventId) {
    if (_isFirebaseActive) {
      return _firestore
          .collection('events')
          .doc(eventId)
          .collection('scores')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ScoreSubmissionModel.fromFirestore(doc))
              .toList());
    }

    _scoreControllers.putIfAbsent(eventId, () => StreamController<List<ScoreSubmissionModel>>.broadcast());
    Future.microtask(() {
      _scoreControllers[eventId]?.add(List.from(_memScores[eventId] ?? []));
    });
    return _scoreControllers[eventId]!.stream;
  }

  Future<void> submitScore(ScoreSubmissionModel score) async {
    if (_isFirebaseActive) {
      final docId = ScoreSubmissionModel.generateId(
        contestantId: score.contestantId,
        judgeId: score.judgeId,
      );

      await _firestore
          .collection('events')
          .doc(score.eventId)
          .collection('scores')
          .doc(docId)
          .set(score.toMap(), SetOptions(merge: true));
      return;
    }

    final list = _memScores.putIfAbsent(score.eventId, () => []);
    final idx = list.indexWhere((s) => s.contestantId == score.contestantId && s.judgeId == score.judgeId);
    if (idx != -1) {
      list[idx] = score;
    } else {
      list.add(score);
    }
    _scoreControllers[score.eventId]?.add(List.from(list));
  }
}
