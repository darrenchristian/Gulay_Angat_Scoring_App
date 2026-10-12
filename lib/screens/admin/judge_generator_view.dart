import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/event_provider.dart';
import '../../services/firestore_service.dart';
import 'admin_password_confirm_dialog.dart';

class JudgeGeneratorView extends StatelessWidget {
  final EventModel event;

  const JudgeGeneratorView({super.key, required this.event});

  void _showLinkJudgesDialog(
    BuildContext context,
    List<JudgeModel> currentlyLinked,
    Set<String> scoredJudgeIds,
  ) {
    final Set<String> selectedIds = {
      ...currentlyLinked.map((j) => j.id),
      ...scoredJudgeIds,
    };
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return StreamBuilder<List<JudgeModel>>(
            stream: FirestoreService().getGlobalJudgesStream(),
            builder: (context, snapshot) {
              final allGlobalJudges = snapshot.data ?? [];

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.link_rounded, color: AppColors.judgeBadge),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Link Judges to Event',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedIds.length} selected for this event',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final nextNum = allGlobalJudges.isEmpty
                                  ? 1
                                  : (allGlobalJudges
                                          .map((j) => j.judgeNumber)
                                          .reduce((a, b) => a > b ? a : b) +
                                      1);
                              final created = await FirestoreService().createGlobalJudge(
                                name: 'Judge #$nextNum',
                                judgeNumber: nextNum,
                              );
                              setState(() {
                                selectedIds.add(created.id);
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('New Global Judge', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (allGlobalJudges.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'No global judges in pool yet.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap "+ New Global Judge" above or batch generate 3 judges below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final createdList = await FirestoreService()
                                      .generateGlobalJudgesBatch(count: 3);
                                  setState(() {
                                    for (final j in createdList) {
                                      selectedIds.add(j.id);
                                    }
                                  });
                                },
                                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                label: const Text('Generate 3 Global Judges'),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: allGlobalJudges.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final judge = allGlobalJudges[index];
                                final hasScored = scoredJudgeIds.contains(judge.id);
                                final isChecked = selectedIds.contains(judge.id) || hasScored;

                                return CheckboxListTile(
                                  value: isChecked,
                                  activeColor: AppColors.judgeBadge,
                                  onChanged: (val) {
                                    if (hasScored && val == false) {
                                      ScaffoldMessenger.of(thisContextOr(ctx, context)).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cannot unlink ${judge.displayName} because they have already submitted scores.',
                                          ),
                                          backgroundColor: AppColors.warning,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      if (val == true) {
                                        selectedIds.add(judge.id);
                                      } else {
                                        selectedIds.remove(judge.id);
                                      }
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          judge.displayName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (hasScored) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.lock_rounded, size: 11, color: AppColors.success),
                                              SizedBox(width: 3),
                                              Text(
                                                'Scored',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    hasScored
                                        ? 'ID: ${judge.accessCode} • Locked (scores submitted)'
                                        : 'ID: ${judge.accessCode}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: AppColors.judgeBadge,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.judgeBadge,
                      minimumSize: const Size(120, 40),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);
                            try {
                              await FirestoreService().updateEventJudges(
                                event.id,
                                {...selectedIds, ...scoredJudgeIds}.toList(),
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Updated linked judges (${selectedIds.length} assigned)!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error linking judges: $e'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Links'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  BuildContext thisContextOr(BuildContext primary, BuildContext fallback) =>
      primary.mounted ? primary : fallback;

  void _copyAllCodes(BuildContext context, List<JudgeModel> judges) {
    if (judges.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Event: ${event.title}');
    buffer.writeln('Linked Judge Login Access Codes:');
    buffer.writeln('--------------------------------');
    for (final j in judges) {
      buffer.writeln('${j.displayName}: ${j.accessCode}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Linked judge access codes copied to clipboard!'),
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

  void _resetSingleJudgeScores(BuildContext context, JudgeModel judge) async {
    final confirmed = await showAdminPasswordResetDialog(
      context: context,
      title: 'Reset ${judge.displayName} Scores',
      message:
          'This will permanently clear all scores submitted by ${judge.displayName} for "${event.title}". Please enter your admin password to confirm.',
      onAuthorizedReset: () => FirestoreService().resetJudgeScoresForEvent(
        eventId: event.id,
        judgeId: judge.id,
      ),
    );

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset scores for ${judge.displayName}.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _resetAllJudgesScores(BuildContext context) async {
    final confirmed = await showAdminPasswordResetDialog(
      context: context,
      title: 'Reset All Judge Scores',
      message:
          'This will permanently clear ALL judge scores submitted for "${event.title}". Please enter your admin password to confirm.',
      onAuthorizedReset: () => FirestoreService().resetAllScoresForEvent(event.id),
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

  void _unlinkJudgeFromEvent(
    BuildContext context,
    JudgeModel judge,
    List<JudgeModel> currentJudges,
    Set<String> scoredJudgeIds,
  ) async {
    if (scoredJudgeIds.contains(judge.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot unlink ${judge.displayName} — this judge has already submitted scores.',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final remainingIds = currentJudges
        .where((j) => j.id != judge.id)
        .map((j) => j.id)
        .toList();

    await FirestoreService().updateEventJudges(event.id, remainingIds);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlinked ${judge.displayName} from this event.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = context.watch<EventProvider>().scores;
    final Set<String> scoredJudgeIds = scores
        .where((s) => s.isSubmitted)
        .map((s) => s.judgeId)
        .toSet();

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
                              '${judges.length} Linked Judges',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Judges who have submitted scores are locked to preserve scoring integrity.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (scoredJudgeIds.isNotEmpty) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _resetAllJudgesScores(context),
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: const Text('Reset All Scores', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (judges.isNotEmpty)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.copy_all_rounded, size: 20),
                          tooltip: 'Copy Linked Credentials',
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
                              Icon(Icons.link_off_rounded, size: 54, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Judges Linked to This Event',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "Link Judges" below to assign judges from your Global Judges Pool.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.judgeBadge,
                                  minimumSize: const Size(160, 44),
                                ),
                                onPressed: () => _showLinkJudgesDialog(context, judges, scoredJudgeIds),
                                icon: const Icon(Icons.link_rounded),
                                label: const Text('Link Judges'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: judges.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final judge = judges[index];
                            final hasScored = scoredJudgeIds.contains(judge.id);

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
                                              Flexible(
                                                child: Text(
                                                  judge.displayName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: AppColors.textPrimary,
                                                  ),
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
                                              if (hasScored) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Scored',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.success,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
                                                color: const Color(0xFFEFF6FF),
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
                                    if (hasScored)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.restart_alt_rounded,
                                          color: AppColors.warning,
                                          size: 20,
                                        ),
                                        tooltip: 'Reset ${judge.displayName} Scores',
                                        onPressed: () => _resetSingleJudgeScores(context, judge),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        hasScored ? Icons.lock_rounded : Icons.link_off_rounded,
                                        color: hasScored ? AppColors.textMuted : AppColors.danger,
                                        size: 20,
                                      ),
                                      tooltip: hasScored
                                          ? 'Locked (Judge has already submitted scores)'
                                          : 'Unlink from Event',
                                      onPressed: () => _unlinkJudgeFromEvent(
                                        context,
                                        judge,
                                        judges,
                                        scoredJudgeIds,
                                      ),
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
            onPressed: () => _showLinkJudgesDialog(context, judges, scoredJudgeIds),
            backgroundColor: AppColors.judgeBadge,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Link / Manage Judges'),
          ),
        );
      },
    );
  }
}
