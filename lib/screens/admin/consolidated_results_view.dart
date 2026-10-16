import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/event_provider.dart';
import '../../services/firestore_service.dart';
import 'admin_password_confirm_dialog.dart';

class ConsolidatedResultsView extends StatefulWidget {
  final EventModel event;

  const ConsolidatedResultsView({super.key, required this.event});

  @override
  State<ConsolidatedResultsView> createState() => _ConsolidatedResultsViewState();
}

class _ConsolidatedResultsViewState extends State<ConsolidatedResultsView> {
  // null means "Overall Final Standings", otherwise contains the groupId of the category/special award
  String? _selectedGroupId;

  void _resetAllScores(BuildContext context) async {
    final confirmed = await showAdminPasswordResetDialog(
      context: context,
      title: 'Reset All Judge Scores',
      message:
          'This will permanently clear ALL judge scores submitted for "${widget.event.title}". Please enter your admin password to confirm.',
      onAuthorizedReset: () => FirestoreService().resetAllScoresForEvent(widget.event.id),
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All judge scores for this event have been reset.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showContestantDetailModal(
    BuildContext context,
    ContestantRankResult result,
    List<CriteriaGroupModel> groups,
    List<CriterionModel> criteria,
    List<JudgeModel> judges, {
    CriteriaGroupModel? selectedGroup,
  }) {
    final bool isCategoryView = selectedGroup != null;
    final List<CriterionModel> relevantCriteria = isCategoryView
        ? criteria.where((c) => c.groupId == selectedGroup.id).toList()
        : criteria;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
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

              // Contestant Header
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                result.contestant.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: result.contestant.isEliminated
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  decoration: result.contestant.isEliminated
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (result.contestant.isEliminated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  'ELIMINATED',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${result.averageScore.toStringAsFixed(2)} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          isCategoryView ? '${selectedGroup.name} Avg' : 'Overall Score',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ----------------- CASE A: CATEGORY TAB SELECTED ----------------- //
              if (isCategoryView) ...[
                // Selected Category Info Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedGroup.affectsOverallScore
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedGroup.affectsOverallScore
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedGroup.affectsOverallScore
                            ? Icons.pie_chart_rounded
                            : Icons.military_tech_rounded,
                        size: 22,
                        color: selectedGroup.affectsOverallScore
                            ? AppColors.primary
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedGroup.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              selectedGroup.affectsOverallScore
                                  ? 'Weight: ${selectedGroup.weightPercentage.toStringAsFixed(0)}% in Final Score'
                                  : 'Special Award (Independent)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${result.submittedJudgeCount}/${judges.length} Judges',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: result.submittedJudgeCount == judges.length && judges.isNotEmpty
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Criteria Breakdown for this category only
                Text(
                  'Criteria Breakdown (${selectedGroup.name})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (relevantCriteria.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No criteria assigned to this category.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...relevantCriteria.map((crit) {
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
              ]
              // ----------------- CASE B: OVERALL STANDINGS ----------------- //
              else ...[
                // If categories/groups exist, show only Categories final scores with judge counts
                if (groups.isNotEmpty) ...[
                  const Text(
                    'Categories Final Score',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...groups.map((group) {
                    final groupAvg = result.perGroupAverages[group.id] ?? 0.0;
                    final groupJudgesCount = result.perGroupJudgeCounts[group.id] ?? 0;
                    final totalJudges = judges.length;
                    final bool isGroupComplete = totalJudges > 0 && groupJudgesCount == totalJudges;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                group.affectsOverallScore
                                    ? Icons.pie_chart_rounded
                                    : Icons.military_tech_rounded,
                                size: 20,
                                color: group.affectsOverallScore ? AppColors.primary : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        group.affectsOverallScore
                                            ? 'Weight: ${group.weightPercentage.toStringAsFixed(0)}%'
                                            : 'Special Award',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isGroupComplete
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : (groupJudgesCount > 0
                                                  ? AppColors.warning.withValues(alpha: 0.12)
                                                  : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isGroupComplete
                                                  ? Icons.check_circle_rounded
                                                  : (groupJudgesCount > 0 ? Icons.schedule_rounded : Icons.pending_outlined),
                                              size: 11,
                                              color: isGroupComplete
                                                  ? AppColors.success
                                                  : (groupJudgesCount > 0 ? const Color(0xFFB45309) : AppColors.textMuted),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$groupJudgesCount/$totalJudges Judges',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isGroupComplete
                                                    ? AppColors.success
                                                    : (groupJudgesCount > 0 ? const Color(0xFFB45309) : AppColors.textMuted),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '${groupAvg.toStringAsFixed(2)} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ] else ...[
                  // Flat legacy event without groups fallback
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
                ],
              ],

              // Per-Judge Submission Matrix
              Text(
                isCategoryView
                    ? 'Judge Scores (${selectedGroup.name})'
                    : 'Per-Judge Submission Matrix',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    final judges = eventProvider.judges;
    final criteria = eventProvider.criteria;
    final groups = eventProvider.criteriaGroups;

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

    // Determine which leaderboard to show:
    // If _selectedGroupId is null, show Overall Leaderboard
    // Otherwise, show Group / Special Award Leaderboard
    final bool isOverall = _selectedGroupId == null || !groups.any((g) => g.id == _selectedGroupId);
    final CriteriaGroupModel? currentGroup = isOverall
        ? null
        : groups.firstWhere((g) => g.id == _selectedGroupId);

    final List<ContestantRankResult> leaderboard = isOverall
        ? eventProvider.getLeaderboard()
        : eventProvider.getGroupLeaderboard(currentGroup!.id);

    final hasAnySubmittedScores = leaderboard.any((item) => item.submittedJudgeCount > 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Action & Category Selection Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOverall ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                          size: 20,
                          color: isOverall ? const Color(0xFFD97706) : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOverall
                              ? 'Overall Final Standings'
                              : '${currentGroup?.name ?? "Category"} Rankings',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (hasAnySubmittedScores)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _resetAllScores(context),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset Scores', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),

                // Category Selector Filter Tabs (if groups exist)
                if (groups.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Overall Final Standings Pill
                        ChoiceChip(
                          avatar: const Icon(Icons.emoji_events_rounded, size: 16),
                          label: const Text('Overall Standings'),
                          selected: isOverall,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGroupId = null);
                            }
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isOverall ? FontWeight.bold : FontWeight.w500,
                            color: isOverall ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Chips for each category / special award
                        ...groups.map((grp) {
                          final isSelected = !isOverall && _selectedGroupId == grp.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              avatar: Icon(
                                grp.affectsOverallScore
                                    ? Icons.pie_chart_outline_rounded
                                    : Icons.military_tech_rounded,
                                size: 16,
                                color: isSelected
                                    ? (grp.affectsOverallScore ? AppColors.primary : const Color(0xFFD97706))
                                    : AppColors.textSecondary,
                              ),
                              label: Text(
                                grp.affectsOverallScore
                                    ? '${grp.name}${grp.isLocked ? " 🔒" : ""} (${grp.weightPercentage.toStringAsFixed(0)}%)'
                                    : '${grp.name}${grp.isLocked ? " 🔒" : ""} [Award]',
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedGroupId = grp.id);
                                }
                              },
                              selectedColor: grp.affectsOverallScore
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? (grp.affectsOverallScore ? AppColors.primary : const Color(0xFFB45309))
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Category Description / Badge if currently filtered
          if (!isOverall && currentGroup != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: currentGroup.affectsOverallScore
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.amber.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    currentGroup.affectsOverallScore
                        ? Icons.info_outline_rounded
                        : Icons.military_tech_rounded,
                    size: 16,
                    color: currentGroup.affectsOverallScore
                        ? AppColors.primary
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentGroup.affectsOverallScore
                          ? 'Contributing Category: Accounts for ${currentGroup.weightPercentage.toStringAsFixed(0)}% of Overall Final Score.'
                          : 'Special Award: Independent award rankings. Does not affect Overall Final Standings.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentGroup.affectsOverallScore
                            ? AppColors.primary
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Leaderboard List
          Expanded(
            child: ListView.separated(
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
                  rankBadgeColor = const Color(0xFFFEF3C7); // Gold
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
                    onTap: () => _showContestantDetailModal(
                      context,
                      item,
                      groups,
                      criteria,
                      judges,
                      selectedGroup: currentGroup,
                    ),
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
                                    Flexible(
                                      child: Text(
                                        item.contestant.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: item.contestant.isEliminated
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                          decoration: item.contestant.isEliminated
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(No. ${item.contestant.number})',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    if (item.contestant.isEliminated) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.error.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Text(
                                          'ELIMINATED',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.error,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                    if (isOverall && groups.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        '•',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.scoredCategoryCount}/${groups.where((g) => g.affectsOverallScore).length} Categories',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: item.scoredCategoryCount == groups.where((g) => g.affectsOverallScore).length
                                              ? AppColors.success
                                              : (item.scoredCategoryCount > 0 ? const Color(0xFFB45309) : AppColors.textMuted),
                                        ),
                                      ),
                                    ],
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
                              Text(
                                isOverall ? 'Overall Score' : 'Category Avg',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
          ),
        ],
      ),
    );
  }
}
