import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'judge_scorecard_screen.dart';

class JudgeHomeScreen extends StatelessWidget {
  const JudgeHomeScreen({super.key});

  void _confirmLogout(BuildContext context, {int pendingSyncCount = 0}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Judge Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingSyncCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: You have $pendingSyncCount score(s) saved offline that have not synced to the server yet. Please connect to Wi-Fi first if possible.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Text(
              'Are you sure you want to log out of this device? You can re-enter anytime using your unique Judge ID.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: pendingSyncCount > 0
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.warning)
                : null,
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AppAuthProvider>().logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final judge = authProvider.currentJudge;
    final selectedEvent = authProvider.judgeAssignedEvent;

    if (judge == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired.'),
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

    // View 1: No event currently selected -> Show "My Assigned Events" Selector
    if (selectedEvent == null) {
      return _buildAssignedEventsSelector(context, judge);
    }

    // View 2: Event selected -> Stream live event and show Contestants Scorecard Dashboard
    return StreamBuilder<EventModel?>(
      stream: FirestoreService().getEventStream(selectedEvent.id),
      builder: (context, eventSnap) {
        final event = eventSnap.data ?? selectedEvent;
        return _buildEventScoringDashboard(context, judge, event);
      },
    );
  }

  // ------------------ VIEW 1: ASSIGNED EVENTS SELECTOR ------------------ //
  Widget _buildAssignedEventsSelector(BuildContext context, JudgeModel judge) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                judge.accessCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.judgeBadge,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().getAssignedEventsForJudgeStream(judge.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignedEvents = snapshot.data ?? [];

          if (assignedEvents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.judgeBadge.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        size: 56,
                        color: AppColors.judgeBadge,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Assigned Events Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are logged in as ${judge.displayName} (${judge.accessCode}).\nAs soon as the Admin links your account to an event, it will appear here automatically.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select an Event to Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'You can switch between your assigned events anytime without logging out.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...assignedEvents.map((event) {
                Color statusColor;
                switch (event.status) {
                  case EventStatus.active:
                    statusColor = AppColors.success;
                    break;
                  case EventStatus.completed:
                    statusColor = AppColors.textMuted;
                    break;
                  case EventStatus.draft:
                    statusColor = AppColors.warning;
                    break;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      context.read<AppAuthProvider>().selectJudgeEvent(event);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        event.status.displayName,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(event.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // ------------------ VIEW 2: EVENT SCORING DASHBOARD ------------------ //
  Widget _buildEventScoringDashboard(
    BuildContext context,
    JudgeModel judge,
    EventModel event,
  ) {
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

                final judgeScores = allScores
                    .where((s) =>
                        s.judgeId == judge.id &&
                        s.isSubmitted &&
                        event.isScoreValidAfterReset(
                          s,
                          judgeId: s.judgeId,
                          submittedAt: s.submittedAt,
                          updatedAt: s.updatedAt,
                        ))
                    .toList();

                final Map<String, ScoreSubmissionModel> scoreMapByContestant = {
                  for (final s in judgeScores) s.contestantId: s,
                };

                final scoredCount = scoreMapByContestant.length;
                final pendingSyncCount = scoreMapByContestant.values
                    .where((s) => s.isPendingSync)
                    .length;
                final totalContestants = contestants.length;
                final progress = totalContestants > 0 ? (scoredCount / totalContestants) : 0.0;

                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Switch Event',
                      onPressed: () {
                        context.read<AppAuthProvider>().selectJudgeEvent(null);
                      },
                    ),
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
                      TextButton.icon(
                        onPressed: () {
                          context.read<AppAuthProvider>().selectJudgeEvent(null);
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Switch Event'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Log Out',
                        onPressed: () => _confirmLogout(
                          context,
                          pendingSyncCount: pendingSyncCount,
                        ),
                      ),
                    ],
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Offline / Pending Sync Alert Banner
                      if (pendingSyncCount > 0) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                color: Color(0xFFB45309),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$pendingSyncCount Score(s) Saved Offline (Pending Sync)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'You can keep scoring offline. Queued scores will upload to the live leaderboard automatically as soon as Wi-Fi reconnects.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Your Scoring Progress',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (scoredCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: pendingSyncCount > 0
                                                ? AppColors.warning.withValues(alpha: 0.15)
                                                : AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                pendingSyncCount > 0
                                                    ? Icons.cloud_upload_outlined
                                                    : Icons.cloud_done_rounded,
                                                size: 12,
                                                color: pendingSyncCount > 0
                                                    ? const Color(0xFFB45309)
                                                    : AppColors.success,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                pendingSyncCount > 0
                                                    ? '$pendingSyncCount Pending Sync'
                                                    : 'All Synced',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: pendingSyncCount > 0
                                                      ? const Color(0xFFB45309)
                                                      : AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
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
                                  children: criteria.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final c = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${idx + 1}. ${c.name} (${c.maxScore.toStringAsFixed(0)} pts)',
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
                          final bool isPending = existingScore?.isPendingSync ?? false;

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
                                          ? (isPending
                                              ? AppColors.warning.withValues(alpha: 0.15)
                                              : AppColors.success.withValues(alpha: 0.15))
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        '#${contestant.number}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isScored
                                              ? (isPending
                                                  ? const Color(0xFFB45309)
                                                  : AppColors.success)
                                              : AppColors.primary,
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
                                          color: isPending
                                              ? AppColors.warning.withValues(alpha: 0.14)
                                              : AppColors.success.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: isPending
                                              ? Border.all(color: AppColors.warning.withValues(alpha: 0.4))
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isPending
                                                      ? Icons.cloud_upload_outlined
                                                      : Icons.check_circle_rounded,
                                                  size: 14,
                                                  color: isPending
                                                      ? const Color(0xFFB45309)
                                                      : AppColors.success,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${existingScore.totalScore.toStringAsFixed(1)} pts',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                    color: isPending
                                                        ? const Color(0xFFB45309)
                                                        : AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              isPending ? 'Pending Sync • Edit' : 'Synced • Tap to edit',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                                                color: isPending
                                                    ? const Color(0xFFB45309)
                                                    : AppColors.textMuted,
                                              ),
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
