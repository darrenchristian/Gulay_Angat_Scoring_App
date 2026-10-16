import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class ContestantEliminationView extends StatelessWidget {
  final EventModel event;

  const ContestantEliminationView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContestantModel>>(
      stream: FirestoreService().getContestantsStream(event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contestants = snapshot.data ?? [];
        final totalCount = contestants.length;
        final eliminatedCount = contestants.where((c) => c.isEliminated).length;
        final activeCount = totalCount - eliminatedCount;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_off_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contestant Elimination',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Control which contestants advance to the next rounds',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Disabled (eliminated) contestants are moved to the bottom of judges\' scoring lists with an [Eliminated] badge and locked from further scoring. Any previously submitted scores in other categories remain intact on the live leaderboard.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 5),
                              Text(
                                '$activeCount Active',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: eliminatedCount > 0
                                ? AppColors.danger.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: eliminatedCount > 0
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_off_rounded,
                                size: 14,
                                color: eliminatedCount > 0 ? AppColors.danger : AppColors.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$eliminatedCount Eliminated',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: eliminatedCount > 0 ? AppColors.danger : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contestants List Header
            const Text(
              'Contestants Status',
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
                          'No Contestants Registered',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add contestants in the Contestants tab first.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...contestants.map((contestant) {
                final bool isEliminated = contestant.isEliminated;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isEliminated
                              ? Colors.grey.shade200
                              : AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            '#${contestant.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isEliminated ? AppColors.textMuted : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      contestant.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isEliminated
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                        decoration: isEliminated
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (isEliminated) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.danger.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'Eliminated',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (contestant.representation.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  contestant.representation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isEliminated
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Enable / Disable Switch Toggle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isEliminated ? 'Disabled' : 'Enabled',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isEliminated
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              value: !isEliminated,
                              activeThumbColor: AppColors.success,
                              inactiveThumbColor: AppColors.danger,
                              inactiveTrackColor: AppColors.danger.withValues(alpha: 0.25),
                              onChanged: (isActive) async {
                                final bool newEliminated = !isActive;
                                await FirestoreService().setContestantElimination(
                                  eventId: event.id,
                                  contestantId: contestant.id,
                                  isEliminated: newEliminated,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newEliminated
                                            ? '#${contestant.number} ${contestant.name} has been ELIMINATED'
                                            : '#${contestant.number} ${contestant.name} has been RE-ACTIVATED',
                                      ),
                                      backgroundColor: newEliminated
                                          ? AppColors.danger
                                          : AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
