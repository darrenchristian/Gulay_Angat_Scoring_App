import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------ EVENTS ------------------ //
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
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

  Future<void> deleteEvent(String eventId) async {
    // Note: In production or larger apps, recursively clean subcollections.
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // ------------------ CRITERIA ------------------ //
  Stream<List<CriterionModel>> getCriteriaStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('criteria')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CriterionModel.fromFirestore(doc)).toList());
  }

  Future<void> addCriterion(CriterionModel criterion) async {
    final col = _firestore
        .collection('events')
        .doc(criterion.eventId)
        .collection('criteria');

    if (criterion.id.isEmpty) {
      await col.add(criterion.toMap());
    } else {
      await col.doc(criterion.id).set(criterion.toMap());
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

  Future<void> deleteCriterion(String eventId, String criterionId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('criteria')
        .doc(criterionId)
        .delete();
  }

  // ------------------ CONTESTANTS ------------------ //
  Stream<List<ContestantModel>> getContestantsStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('contestants')
        .orderBy('number')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ContestantModel.fromFirestore(doc)).toList());
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

  // ------------------ JUDGES & UNIQUE ACCESS IDS ------------------ //
  Stream<List<JudgeModel>> getJudgesStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('judges')
        .orderBy('judgeNumber')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JudgeModel.fromFirestore(doc)).toList());
  }

  /// Generates a set of unique judge accounts with clean memorable alphanumeric codes
  Future<List<JudgeModel>> generateJudgesForEvent({
    required String eventId,
    required int count,
  }) async {
    final List<JudgeModel> generated = [];
    final batch = _firestore.batch();
    final random = Random();

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars (0, O, 1, I)

    for (int i = 1; i <= count; i++) {
      // Create code e.g. "JDG-7X4K"
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

      // Write to global lookup index
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

    // Also update judgeCount in the event doc
    final eventRef = _firestore.collection('events').doc(eventId);
    batch.update(eventRef, {
      'judgeCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return generated;
  }

  Future<void> updateJudge(JudgeModel judge) async {
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
  }

  // ------------------ SCORES & REALTIME CONSOLIDATION ------------------ //
  Stream<List<ScoreSubmissionModel>> getScoresStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('scores')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoreSubmissionModel.fromFirestore(doc))
            .toList());
  }

  Stream<ScoreSubmissionModel?> getJudgeContestantScoreStream({
    required String eventId,
    required String contestantId,
    required String judgeId,
  }) {
    final docId = ScoreSubmissionModel.generateId(
      contestantId: contestantId,
      judgeId: judgeId,
    );

    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('scores')
        .doc(docId)
        .snapshots()
        .map((doc) => doc.exists ? ScoreSubmissionModel.fromFirestore(doc) : null);
  }

  Future<void> submitScore(ScoreSubmissionModel score) async {
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
  }
}
