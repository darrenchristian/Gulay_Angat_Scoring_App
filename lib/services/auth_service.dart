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
  final EventModel? event;

  JudgeSession({required this.judge, this.event});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ------------------ ADMIN AUTH (FIREBASE AUTH) ------------------ //
  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerAdmin({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOutAdmin() async {
    await _auth.signOut();
  }

  /// Verifies the currently signed-in admin's password before sensitive actions
  /// such as resetting judge scores.
  Future<void> verifyAdminPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw Exception('No active admin account found. Please sign in again.');
    }
    if (password.isEmpty) {
      throw Exception('Please enter your admin password.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // ------------------ JUDGE AUTH (UNIQUE ID IN GLOBAL POOL) ------------------ //
  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocWithCacheFallback(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get().timeout(const Duration(seconds: 3));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.cache));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getQueryWithCacheFallback(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get().timeout(const Duration(seconds: 3));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  /// Verifies a unique judge access code (e.g. "JDG-9021") strictly against
  /// the global `judges` pool in Cloud Firestore (with local cache fallback if offline).
  Future<JudgeSession> verifyJudgeCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('Please enter your unique Judge ID.');
    }

    // 1. Check `judge_codes/{code}` index
    try {
      final codeDoc = await _getDocWithCacheFallback(
        _firestore.collection('judge_codes').doc(code),
      );

      if (codeDoc.exists) {
        final codeData = codeDoc.data()!;
        final String judgeId = codeData['judgeId'] as String? ?? '';

        if (judgeId.isNotEmpty) {
          final globalJudgeDoc = await _getDocWithCacheFallback(
            _firestore.collection('judges').doc(judgeId),
          );
          if (globalJudgeDoc.exists) {
            final judge = JudgeModel.fromFirestore(globalJudgeDoc);
            if (!judge.isActive) {
              throw Exception('This judge account is currently deactivated by the admin.');
            }
            return JudgeSession(judge: judge);
          } else {
            // Stale legacy code pointing to an old event subcollection judge -> remove stale index
            try {
              await _firestore
                  .collection('judge_codes')
                  .doc(code)
                  .delete()
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
          }
        }
      }
    } on FirebaseException catch (_) {
      // Fall through to direct query
    }

    // 2. Direct query on top-level global `judges` collection
    try {
      final globalQuery = await _getQueryWithCacheFallback(
        _firestore
            .collection('judges')
            .where('accessCode', isEqualTo: code)
            .limit(1),
      );

      if (globalQuery.docs.isNotEmpty) {
        final judge = JudgeModel.fromFirestore(globalQuery.docs.first);
        if (!judge.isActive) {
          throw Exception('This judge account is currently deactivated by the admin.');
        }
        return JudgeSession(judge: judge);
      }
    } on FirebaseException catch (_) {
      throw Exception(
        'Cannot verify Judge ID while offline unless this device has previously loaded the judge pool. Please connect to Wi-Fi once to sign in.',
      );
    }

    throw Exception('Invalid Judge ID: "$code". Please use a valid Global Judge ID.');
  }
}
