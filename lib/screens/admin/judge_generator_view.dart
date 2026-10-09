import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class JudgeGeneratorView extends StatelessWidget {
  final EventModel event;

  const JudgeGeneratorView({super.key, required this.event});

  void _showGenerateJudgesDialog(BuildContext context, int currentCount) {
    int count = currentCount > 0 ? currentCount : 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Generate Judges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specify how many judges will evaluate this event. Unique login IDs will be auto-generated.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: count > 1 ? () => setState(() => count--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$count Judges',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    onPressed: count < 20 ? () => setState(() => count++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 40),
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await FirestoreService().generateJudgesForEvent(
                    eventId: event.id,
                    count: count,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Generated $count unique judge access accounts!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error generating judges: $e'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAllCodes(BuildContext context, List<JudgeModel> judges) {
    if (judges.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Event: ${event.title}');
    buffer.writeln('Judge Login Access Codes:');
    buffer.writeln('--------------------------');
    for (final j in judges) {
      buffer.writeln('${j.displayName}: ${j.accessCode}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All judge access codes copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _editJudgeName(BuildContext context, JudgeModel judge) {
    final ctrl = TextEditingController(text: judge.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${judge.displayName} Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Judge Name',
            hintText: 'e.g. Dr. Maria Santos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = judge.copyWith(name: ctrl.text.trim());
              await FirestoreService().updateJudge(updated);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JudgeModel>>(
      stream: FirestoreService().getJudgesStream(event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final judges = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top control card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.judgeBadge.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded, color: AppColors.judgeBadge),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${judges.length} Judge Accounts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Judges log in using their unique ID only.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (judges.isNotEmpty)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.copy_all_rounded, size: 20),
                          tooltip: 'Copy All Credentials',
                          onPressed: () => _copyAllCodes(context, judges),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Judges list
                Expanded(
                  child: judges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gavel_rounded, size: 54, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Judges Generated Yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "Generate Judges" to create unique login credentials.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: judges.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final judge = judges[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.judgeBadge.withValues(alpha: 0.1),
                                      child: Text(
                                        'J${judge.judgeNumber}',
                                        style: const TextStyle(
                                          color: AppColors.judgeBadge,
                                          fontWeight: FontWeight.bold,
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
                                              Text(
                                                judge.displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _editJudgeName(context, judge),
                                                child: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Prominent Unique ID Pill
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: judge.accessCode));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Copied: ${judge.accessCode}'),
                                                  duration: const Duration(seconds: 1),
                                                  backgroundColor: AppColors.success,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF), // Blue 50
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.key_rounded, size: 14, color: AppColors.judgeBadge),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    judge.accessCode,
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      letterSpacing: 1.0,
                                                      color: AppColors.judgeBadge,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.judgeBadge),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: judge.isActive,
                                      activeTrackColor: AppColors.success,
                                      onChanged: (val) {
                                        FirestoreService().updateJudge(judge.copyWith(isActive: val));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showGenerateJudgesDialog(context, judges.length),
            backgroundColor: AppColors.judgeBadge,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(judges.isEmpty ? 'Generate Judges' : 'Re-generate Judges'),
          ),
        );
      },
    );
  }
}
