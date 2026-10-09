import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserRole _role = UserRole.guest;
  JudgeSession? _judgeSession;
  bool _isLoading = false;
  String? _errorMessage;

  UserRole get role => _role;
  JudgeSession? get judgeSession => _judgeSession;
  JudgeModel? get currentJudge => _judgeSession?.judge;
  EventModel? get judgeAssignedEvent => _judgeSession?.event;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _role == UserRole.admin;
  bool get isJudge => _role == UserRole.judge;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _role = UserRole.admin;
      } else if (_role != UserRole.judge) {
        _role = UserRole.guest;
      }
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Admin login via Email & Password
  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInAdmin(email: email, password: password);
      _role = UserRole.admin;
      _judgeSession = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getFriendlyFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Judge login via Unique ID only
  Future<bool> loginJudge({
    required String accessCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authService.verifyJudgeCode(accessCode);
      _judgeSession = session;
      _role = UserRole.judge;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_role == UserRole.admin) {
      await _authService.signOutAdmin();
    }
    _judgeSession = null;
    _role = UserRole.guest;
    _errorMessage = null;
    notifyListeners();
  }

  String _getFriendlyFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      default:
        return e.message ?? 'Authentication failed. Please check your credentials.';
    }
  }
}
