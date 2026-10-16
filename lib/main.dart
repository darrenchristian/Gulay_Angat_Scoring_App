import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/judge/judge_home_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_session_storage.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirestoreService.resetGeneration();

  String instanceId = '';
  String? role;
  for (final arg in args) {
    if (arg.startsWith('--instance=')) {
      instanceId = arg.replaceFirst('--instance=', '');
    } else if (arg.startsWith('--role=')) {
      role = arg.replaceFirst('--role=', '');
    } else if (arg == '--judge') {
      role = 'judge';
    } else if (arg == '--admin') {
      role = 'admin';
    }
  }

  LocalSessionStorage.instanceSuffix = instanceId;
  AppAuthProvider.configuredInstanceId = instanceId;
  AppAuthProvider.forcedRole = role;

  runApp(const ScoringApp());
}

class ScoringApp extends StatelessWidget {
  const ScoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'GulayAngat ScoreSync',
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
