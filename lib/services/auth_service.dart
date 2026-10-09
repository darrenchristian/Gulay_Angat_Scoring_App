import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/judge_model.dart';
import '../models/event_model.dart';

enum UserRole {
  guest,
  admin,
  judge,
}

class JudgeSession {
  final JudgeModel judge;
  final EventModel event;

  JudgeSession({required this.judge, required this.event});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ------------------ ADMIN AUTH ------------------ //
  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOutAdmin() async {
    await _auth.signOut();
  }

  // ------------------ JUDGE AUTH (UNIQUE ID) ------------------ //
  /// Verifies a unique judge access code (e.g. "JDG-9021").
  /// Returns the corresponding JudgeSession containing the JudgeModel and EventModel.
  Future<JudgeSession> verifyJudgeCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('Please enter your unique Judge ID.');
    }

    // 1. Check the lookup index 'judge_codes'
    final codeDoc = await _firestore.collection('judge_codes').doc(code).get();

    if (!codeDoc.exists) {
      // Fallback search across events' judges subcollections in case index wasn't populated
      final query = await _firestore
          .collectionGroup('judges')
          .where('accessCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Invalid Judge ID. Please check with the event admin.');
      }

      final judgeDoc = query.docs.first;
      final judge = JudgeModel.fromFirestore(judgeDoc);
      if (!judge.isActive) {
        throw Exception('This judge account is currently deactivated.');
      }

      final eventDoc = await _firestore.collection('events').doc(judge.eventId).get();
      if (!eventDoc.exists) {
        throw Exception('The associated event could not be found.');
      }
      final event = EventModel.fromFirestore(eventDoc);

      return JudgeSession(judge: judge, event: event);
    }

    final codeData = codeDoc.data()!;
    final bool isActive = codeData['isActive'] as bool? ?? true;
    if (!isActive) {
      throw Exception('This judge account is currently deactivated.');
    }

    final String eventId = codeData['eventId'] as String;
    final String judgeId = codeData['judgeId'] as String;

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('The associated event was not found or has been removed.');
    }
    final event = EventModel.fromFirestore(eventDoc);

    final judgeDoc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('judges')
        .doc(judgeId)
        .get();

    if (!judgeDoc.exists) {
      throw Exception('Judge profile not found.');
    }
    final judge = JudgeModel.fromFirestore(judgeDoc);

    return JudgeSession(judge: judge, event: event);
  }
}
