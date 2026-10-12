import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class GlobalJudgesPoolView extends StatelessWidget {
  const GlobalJudgesPoolView({super.key});

  void _showAddSingleJudgeDialog(BuildContext context, int nextNumber) {
    final nameCtrl = TextEditingController(text: 'Judge #$nextNumber');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.judgeBadge),
              SizedBox(width: 8),
              Text('Add Judge Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a reusable global judge account with a unique login ID.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judge Name / Label',
                  hintText: 'e.g. Judge #1 or Dr. Maria Santos',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.judgeBadge,
                minimumSize: const Size(110, 40),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);
                      try {
                        final created = await FirestoreService().createGlobalJudge(
                          name: nameCtrl.text,
                          judgeNumber: nextNumber,
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Created ${created.displayName} (${created.accessCode})'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating judge: $e'),
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
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchGenerateDialog(BuildContext context) {
    int count = 3;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: AppColors.judgeBadge),
              SizedBox(width: 8),
              Text('Batch Generate Judges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate multiple global judge accounts at once. These accounts can be linked to any event.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: count > 1 && !isSaving ? () => setState(() => count--) : null,
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
                    onPressed: count < 20 && !isSaving ? () => setState(() => count++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 40),
                backgroundColor: AppColors.judgeBadge,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setState(() => isSaving = true);
                      try {
                        await FirestoreService().generateGlobalJudgesBatch(count: count);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Generated $count global judge accounts!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error generating judges: $e'),
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
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAllCodes(BuildContext context, List<JudgeModel> judges) {
    if (judges.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Global Judge Login Access Codes:');
    buffer.writeln('--------------------------------');
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
        title: Text('Edit ${judge.displayName}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Judge Name / Label',
            hintText: 'e.g. Judge #1 or Dr. Maria Santos',
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

  void _confirmDeleteJudge(BuildContext context, JudgeModel judge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Judge Account'),
        content: Text(
          'Are you sure you want to delete "${judge.displayName}" (${judge.accessCode}) from the global pool?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () async {
              await FirestoreService().deleteGlobalJudge(judge);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JudgeModel>>(
      stream: FirestoreService().getGlobalJudgesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final judges = snapshot.data ?? [];
        final nextNum = judges.isEmpty
            ? 1
            : (judges.map((j) => j.judgeNumber).reduce((a, b) => a > b ? a : b) + 1);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
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
                              '${judges.length} Global Judge Accounts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Create judge accounts once and link them to any event.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.group_add_rounded, size: 20),
                        tooltip: 'Batch Generate Judges',
                        onPressed: () => _showBatchGenerateDialog(context),
                      ),
                      if (judges.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.copy_all_rounded, size: 20),
                          tooltip: 'Copy All Credentials',
                          onPressed: () => _copyAllCodes(context, judges),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: judges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gavel_rounded, size: 56, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Global Judges Created Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Create judge accounts here so tablets only need to log in once across multiple events.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.judgeBadge,
                                      minimumSize: const Size(160, 44),
                                    ),
                                    onPressed: () => _showBatchGenerateDialog(context),
                                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                                    label: const Text('Batch Generate'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(160, 44),
                                    ),
                                    onPressed: () => _showAddSingleJudgeDialog(context, nextNum),
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                    label: const Text('Add Single Judge'),
                                  ),
                                ],
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
                                            ],
                                          ),
                                          const SizedBox(height: 6),
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
                                    Switch(
                                      value: judge.isActive,
                                      activeTrackColor: AppColors.success,
                                      onChanged: (val) {
                                        FirestoreService().updateJudge(judge.copyWith(isActive: val));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                      tooltip: 'Delete Judge Account',
                                      onPressed: () => _confirmDeleteJudge(context, judge),
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
            onPressed: () => _showAddSingleJudgeDialog(context, nextNum),
            backgroundColor: AppColors.judgeBadge,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Judge'),
          ),
        );
      },
    );
  }
}
