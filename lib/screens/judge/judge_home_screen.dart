import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'judge_scorecard_screen.dart';

class JudgeHomeScreen extends StatelessWidget {
  const JudgeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final judge = authProvider.currentJudge;
    final event = authProvider.judgeAssignedEvent;

    if (judge == null || event == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired or event unavailable.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<AppAuthProvider>().logout(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<CriterionModel>>(
      stream: FirestoreService().getCriteriaStream(event.id),
      builder: (context, criteriaSnapshot) {
        final criteria = criteriaSnapshot.data ?? [];

        return StreamBuilder<List<ContestantModel>>(
          stream: FirestoreService().getContestantsStream(event.id),
          builder: (context, contestantsSnapshot) {
            final contestants = contestantsSnapshot.data ?? [];

            return StreamBuilder<List<ScoreSubmissionModel>>(
              stream: FirestoreService().getScoresStream(event.id),
              builder: (context, scoresSnapshot) {
                final allScores = scoresSnapshot.data ?? [];

                // Filter scores submitted specifically by this judge
                final judgeScores = allScores
                    .where((s) => s.judgeId == judge.id && s.isSubmitted)
                    .toList();

                final Map<String, ScoreSubmissionModel> scoreMapByContestant = {
                  for (final s in judgeScores) s.contestantId: s,
                };

                final scoredCount = scoreMapByContestant.length;
                final totalContestants = contestants.length;
                final progress = totalContestants > 0 ? (scoredCount / totalContestants) : 0.0;

                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.judgeBadge.withValues(alpha: 0.15),
                          child: Text(
                            'J${judge.judgeNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.judgeBadge,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            judge.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Exit Session',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Exit Session'),
                              content: const Text(
                                'Are you sure you want to exit your scoring session? You can re-enter anytime using your unique Judge ID.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    context.read<AppAuthProvider>().logout();
                                  },
                                  child: const Text('Exit'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Event Info & Status Banner
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: event.isActive
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : AppColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: event.isActive
                                            ? AppColors.success.withValues(alpha: 0.4)
                                            : AppColors.warning.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: event.isActive ? AppColors.success : AppColors.warning,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          event.status.displayName,
                                          style: TextStyle(
                                            color: event.isActive ? AppColors.success : AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (event.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Your Scoring Progress',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$scoredCount / $totalContestants Scored',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: scoredCount == totalContestants && totalContestants > 0
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: scoredCount == totalContestants && totalContestants > 0
                                    ? AppColors.success
                                    : AppColors.primary,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Criteria Quick Reference Chip Bar
                      if (criteria.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.rule_folder_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            const Text(
                              'Event Criteria:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: criteria.map((c) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${c.name} (${c.maxScore.toStringAsFixed(0)} pts)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Contestants List Header
                      const Text(
                        'Contestants to Evaluate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (contestants.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No Contestants Registered Yet',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'The administrator has not registered contestants yet.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...contestants.map((contestant) {
                          final existingScore = scoreMapByContestant[contestant.id];
                          final bool isScored = existingScore != null && existingScore.isSubmitted;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (criteria.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No criteria setup for this event yet.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JudgeScorecardScreen(
                                      event: event,
                                      contestant: contestant,
                                      judge: judge,
                                      criteria: criteria,
                                      existingScore: existingScore,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isScored
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        '#${contestant.number}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isScored ? AppColors.success : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contestant.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (contestant.representation.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              contestant.representation,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                          if (contestant.bio.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              contestant.bio,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Score badge / Action
                                    if (isScored)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle_rounded,
                                                    size: 14, color: AppColors.success),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${existingScore.totalScore.toStringAsFixed(1)} pts',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Text(
                                              'Tap to edit',
                                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(80, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        onPressed: () {
                                          if (criteria.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('No criteria setup for this event yet.'),
                                                backgroundColor: AppColors.warning,
                                              ),
                                            );
                                            return;
                                          }

                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => JudgeScorecardScreen(
                                                event: event,
                                                contestant: contestant,
                                                judge: judge,
                                                criteria: criteria,
                                                existingScore: existingScore,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Score'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
