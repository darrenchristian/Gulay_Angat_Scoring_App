import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/judge/judge_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  String? firebaseError;

  try {
    // Attempt Firebase initialization
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(
    ScoringApp(
      firebaseReady: firebaseReady,
      firebaseError: firebaseError,
    ),
  );
}

class ScoringApp extends StatelessWidget {
  final bool firebaseReady;
  final String? firebaseError;

  const ScoringApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'ScoreSync Live',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppNavigationRoot(),
      ),
    );
  }
}

/// Dynamic root router that navigates according to user authentication role
class AppNavigationRoot extends StatelessWidget {
  const AppNavigationRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    switch (authProvider.role) {
      case UserRole.admin:
        return const AdminHomeScreen();
      case UserRole.judge:
        return const JudgeHomeScreen();
      case UserRole.guest:
        return const LoginScreen();
    }
  }
}

/// Informative screen if Firebase initialization is pending credentials
class FirebaseConfigPendingScreen extends StatelessWidget {
  final String? errorMessage;

  const FirebaseConfigPendingScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      size: 48,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Firebase Connection Pending',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please complete the Firebase setup for project "scoring-app-8bae2" by providing google-services.json or signing in with the owner account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate anyway to preview UI in offline/mock mode
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AppNavigationRoot(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.preview_rounded, size: 20),
                    label: const Text('Preview Login UI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
