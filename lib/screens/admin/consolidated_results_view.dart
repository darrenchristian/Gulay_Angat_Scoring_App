import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/event_provider.dart';

class ConsolidatedResultsView extends StatelessWidget {
  final EventModel event;

  const ConsolidatedResultsView({super.key, required this.event});

  void _showContestantDetailModal(
    BuildContext context,
    ContestantRankResult result,
    List<CriterionModel> criteria,
    List<JudgeModel> judges,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '#${result.contestant.number}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.contestant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (result.contestant.representation.isNotEmpty)
                          Text(
                            result.contestant.representation,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${result.averageScore.toStringAsFixed(2)} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Criteria Breakdown (Averages)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...criteria.map((crit) {
                final avg = result.perCriteriaAverages[crit.id] ?? 0.0;
                final percentage = crit.maxScore > 0 ? (avg / crit.maxScore) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            crit.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${avg.toStringAsFixed(1)} / ${crit.maxScore.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Per-Judge Submission Matrix',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...judges.map((judge) {
                final judgeScore = result.perJudgeScores[judge.id];
                final hasSubmitted = judgeScore != null;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    hasSubmitted ? Icons.check_circle : Icons.pending_outlined,
                    color: hasSubmitted ? AppColors.success : AppColors.textMuted,
                    size: 20,
                  ),
                  title: Text(judge.displayName),
                  trailing: Text(
                    hasSubmitted ? '${judgeScore.toStringAsFixed(2)} pts' : 'Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasSubmitted ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final leaderboard = eventProvider.getLeaderboard();
    final judges = eventProvider.judges;
    final criteria = eventProvider.criteria;

    if (eventProvider.contestants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Contestants Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Register contestants to observe real-time consolidated scores.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = leaderboard[index];
          final totalJudges = judges.length;

          // Rank badge colors
          Color rankBadgeColor = AppColors.cardBorder;
          Color rankTextColor = AppColors.textSecondary;
          if (item.rank == 1) {
            rankBadgeColor = const Color(0xFFFEF3C7); // Gold / Amber
            rankTextColor = const Color(0xFFB45309);
          } else if (item.rank == 2) {
            rankBadgeColor = const Color(0xFFF1F5F9); // Silver
            rankTextColor = const Color(0xFF475569);
          } else if (item.rank == 3) {
            rankBadgeColor = const Color(0xFFFFEDD5); // Bronze
            rankTextColor = const Color(0xFFC2410C);
          }

          final bool isComplete = totalJudges > 0 && item.submittedJudgeCount == totalJudges;

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showContestantDetailModal(context, item, criteria, judges),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Rank Indicator
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rankBadgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${item.rank}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: rankTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Contestant Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.contestant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(No. ${item.contestant.number})',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          if (item.contestant.representation.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.contestant.representation,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isComplete ? Icons.done_all_rounded : Icons.pending_rounded,
                                size: 14,
                                color: isComplete ? AppColors.success : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.submittedJudgeCount}/$totalJudges Judges',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isComplete ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Score Display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.averageScore.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Average Score',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
