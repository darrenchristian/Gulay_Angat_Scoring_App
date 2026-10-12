import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_session_storage.dart';
import '../models/models.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalSessionStorage _localSession = LocalSessionStorage();
  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  UserRole _role = UserRole.guest;
  JudgeSession? _judgeSession;
  EventModel? _selectedJudgeEvent;
  bool _isLoading = false;
  String? _errorMessage;

  UserRole get role => _role;
  JudgeSession? get judgeSession => _judgeSession;
  JudgeModel? get currentJudge => _judgeSession?.judge;
  EventModel? get judgeAssignedEvent => _selectedJudgeEvent ?? _judgeSession?.event;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _role == UserRole.admin;
  bool get isJudge => _role == UserRole.judge;

  AppAuthProvider() {
    _init();
  }

  bool get _hasActiveFlutterView {
    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      return dispatcher.views.isNotEmpty || dispatcher.implicitView != null;
    } catch (_) {
      return false;
    }
  }

  void _init() {
    _restoreLocalJudgeSessionIfNeeded();

    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (_isDisposed || !_hasActiveFlutterView) {
        _authSubscription?.cancel();
        _authSubscription = null;
        return;
      }
      if (user != null) {
        _role = UserRole.admin;
      } else if (_role != UserRole.judge) {
        _role = UserRole.guest;
      }
      notifyListeners();
    });
  }

  Future<void> _restoreLocalJudgeSessionIfNeeded() async {
    try {
      if (_authService.currentUser != null) return;
      final saved = await _localSession.loadJudgeSession();
      if (saved != null && _authService.currentUser == null && !_isDisposed) {
        _judgeSession = JudgeSession(
          judge: saved.judge,
          event: saved.selectedEvent,
        );
        _selectedJudgeEvent = saved.selectedEvent;
        _role = UserRole.judge;
        if (saved.selectedEvent != null) {
          FirestoreService().warmUpEventCache(saved.selectedEvent!.id);
        }
        if (_hasActiveFlutterView) {
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void selectJudgeEvent(EventModel? event) {
    _selectedJudgeEvent = event;
    if (_judgeSession != null) {
      _localSession.saveJudgeSession(
        judge: _judgeSession!.judge,
        selectedEvent: event,
      );
    }
    if (event != null) {
      FirestoreService().warmUpEventCache(event.id);
    }
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
      await _localSession.clearJudgeSession();
      _role = UserRole.admin;
      _judgeSession = null;
      _selectedJudgeEvent = null;
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

  // Admin registration via Email & Password
  Future<bool> registerAdmin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerAdmin(email: email, password: password);
      await _localSession.clearJudgeSession();
      _role = UserRole.admin;
      _judgeSession = null;
      _selectedJudgeEvent = null;
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
      _selectedJudgeEvent = session.event;
      _role = UserRole.judge;
      await _localSession.saveJudgeSession(
        judge: session.judge,
        selectedEvent: session.event,
      );
      if (session.event != null) {
        FirestoreService().warmUpEventCache(session.event!.id);
      }
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
    await _localSession.clearJudgeSession();
    _judgeSession = null;
    _selectedJudgeEvent = null;
    _role = UserRole.guest;
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifies the current admin's password; returns null on success or an error message on failure.
  Future<String?> verifyAdminPassword(String password) async {
    try {
      await _authService.verifyAdminPassword(password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getFriendlyFirebaseAuthError(e);
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
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
      case 'email-already-in-use':
        return 'An admin account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      default:
        return e.message ?? 'Authentication failed. Please check your credentials.';
    }
  }
}
