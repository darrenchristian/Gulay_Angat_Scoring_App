import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class JudgeHomeScreen extends StatelessWidget {
  const JudgeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final judge = authProvider.currentJudge;
    final event = authProvider.judgeAssignedEvent;

    return Scaffold(
      appBar: AppBar(
        title: Text(judge?.displayName ?? 'Judge Scorecard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Leave Session',
            onPressed: () {
              context.read<AppAuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.judgeBadge.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 48,
                  color: AppColors.judgeBadge,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                judge?.displayName ?? 'Judge Portal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.judgeBadge.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Code: ${judge?.accessCode ?? "N/A"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.judgeBadge,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Assigned Event: ${event?.title ?? "Loading..."}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Digital scoring sheet and contestant carousel will be configured in Phase 4.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AppAuthProvider>().logout(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Exit Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
