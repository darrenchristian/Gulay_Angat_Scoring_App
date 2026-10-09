import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/judge_model.dart';
import '../models/event_model.dart';
import 'firestore_service.dart';

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
  bool get _isFirebaseActive => Firebase.apps.isNotEmpty;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    if (_isFirebaseActive) {
      return _auth.authStateChanges();
    }
    return const Stream.empty();
  }

  User? get currentUser {
    if (_isFirebaseActive) {
      return _auth.currentUser;
    }
    return null;
  }

  // ------------------ ADMIN AUTH ------------------ //
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (_isFirebaseActive) {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return;
    }

    // Fallback/Demo admin verification
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email and password cannot be empty.');
    }
    // Allow any demo admin credentials
    return;
  }

  Future<void> signOutAdmin() async {
    if (_isFirebaseActive) {
      await _auth.signOut();
    }
  }

  // ------------------ JUDGE AUTH (UNIQUE ID) ------------------ //
  Future<JudgeSession> verifyJudgeCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('Please enter your unique Judge ID.');
    }

    if (_isFirebaseActive) {
      final codeDoc = await _firestore.collection('judge_codes').doc(code).get();

      if (!codeDoc.exists) {
        final query = await _firestore
            .collectionGroup('judges')
            .where('accessCode', isEqualTo: code)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception('Invalid Judge ID. Please verify with the event admin.');
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

    // In-Memory / Pre-populated lookup
    final memCode = FirestoreService().getMemJudgeCode(code);
    if (memCode == null) {
      throw Exception('Invalid Judge ID: "$code". Try demo IDs: JDG-DEMO1, JDG-DEMO2, or JDG-DEMO3.');
    }

    final bool isActive = memCode['isActive'] as bool? ?? true;
    if (!isActive) {
      throw Exception('This judge account is currently deactivated.');
    }

    final String eventId = memCode['eventId'] as String;
    final event = await FirestoreService().getEvent(eventId);
    if (event == null) {
      throw Exception('Event not found.');
    }

    final judge = JudgeModel(
      id: memCode['judgeId'] as String,
      eventId: eventId,
      judgeNumber: memCode['judgeNumber'] as int,
      accessCode: code,
      name: memCode['name'] as String,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    return JudgeSession(judge: judge, event: event);
  }
}
