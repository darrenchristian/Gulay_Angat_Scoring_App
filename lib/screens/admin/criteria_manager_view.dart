import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class CriteriaManagerView extends StatelessWidget {
  final EventModel event;

  const CriteriaManagerView({super.key, required this.event});

  // ---------------------------------------------------------
  // ADD / EDIT GROUP DIALOG
  // ---------------------------------------------------------
  void _showAddEditGroupDialog(
    BuildContext context, {
    CriteriaGroupModel? group,
    int nextOrder = 0,
  }) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final descCtrl = TextEditingController(text: group?.description ?? '');
    final weightCtrl = TextEditingController(
      text: (group != null)
          ? group.weightPercentage.toStringAsFixed(0)
          : '25',
    );
    bool affectsOverall = group?.affectsOverallScore ?? true;
    bool isLocked = group?.isLocked ?? false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            group == null ? Icons.create_new_folder_outlined : Icons.folder_open_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group == null ? 'Add Criteria Group / Award' : 'Edit Criteria Group',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          hintText: 'e.g. Question & Answer, Swimsuit, Talent',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter group name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g. Special award category or preliminary stage',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Affects Final Score Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: affectsOverall
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: affectsOverall
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    affectsOverall
                                        ? 'Counts Toward Overall Final Score'
                                        : 'Special Award Only (Separate)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: affectsOverall ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    affectsOverall
                                        ? 'This group has a percentage weight in the overall final title/winner.'
                                        : 'Scores are used for an independent award (e.g. Best in Swimsuit) and do not affect final rankings.',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: affectsOverall,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) {
                                setDialogState(() {
                                  affectsOverall = val;
                                  if (!val) {
                                    weightCtrl.text = '0';
                                  } else if (weightCtrl.text == '0') {
                                    weightCtrl.text = '25';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      if (affectsOverall) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Weight Percentage in Final Score (%)',
                            hintText: 'e.g. 30',
                            suffixText: '%',
                            helperText: 'Total of all contributing groups should sum to 100%',
                          ),
                          validator: (v) {
                            if (!affectsOverall) return null;
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0 || val > 100) return 'Enter 1 - 100%';
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Category Lock toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? AppColors.danger.withValues(alpha: 0.06)
                              : AppColors.success.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLocked
                                ? AppColors.danger.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                              size: 20,
                              color: isLocked ? AppColors.danger : AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLocked ? 'Category is Locked' : 'Category is Open',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isLocked ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    isLocked
                                        ? 'Judges cannot score this category until unlocked.'
                                        : 'Judges can view and score contestants in this category.',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isLocked,
                              activeThumbColor: AppColors.danger,
                              onChanged: (val) {
                                setDialogState(() {
                                  isLocked = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final weight = affectsOverall
                                  ? (double.tryParse(weightCtrl.text) ?? 0.0)
                                  : 0.0;

                              final updated = CriteriaGroupModel(
                                id: group?.id ?? '',
                                eventId: event.id,
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                affectsOverallScore: affectsOverall,
                                weightPercentage: weight,
                                order: group?.order ?? nextOrder,
                                isLocked: isLocked,
                              );

                              if (group == null) {
                                await FirestoreService().addCriteriaGroup(updated);
                              } else {
                                await FirestoreService().updateCriteriaGroup(updated);
                              }

                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            child: Text(group == null ? 'Create Group' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, CriteriaGroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Criteria Group'),
        content: Text(
          'Are you sure you want to delete the group "${group.name}"?\n\n'
          'Existing criteria in this group will NOT be deleted; they will be moved to General / Uncategorized.',
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
              await FirestoreService().deleteCriteriaGroup(event.id, group.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveGroup(
    List<CriteriaGroupModel> groups,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex < 0 || newIndex >= groups.length || oldIndex == newIndex) {
      return;
    }
    final updated = List<CriteriaGroupModel>.from(groups);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await FirestoreService().reorderCriteriaGroups(event.id, updated);
  }

  // ---------------------------------------------------------
  // ADD / EDIT CRITERION DIALOG
  // ---------------------------------------------------------
  void _showAddEditCriterionDialog(
    BuildContext context, {
    CriterionModel? criterion,
    String? defaultGroupId,
    required List<CriteriaGroupModel> availableGroups,
    int nextOrder = 0,
  }) {
    final nameCtrl = TextEditingController(text: criterion?.name ?? '');
    final descCtrl = TextEditingController(text: criterion?.description ?? '');
    final maxScoreCtrl = TextEditingController(text: (criterion?.maxScore ?? 100).toString());
    final weightCtrl = TextEditingController(text: (criterion?.weightPercentage ?? 100).toString());
    String selectedGroupId = criterion?.groupId ?? (defaultGroupId ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        criterion == null ? 'Add Criterion' : 'Edit Criterion',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Group selector dropdown if groups are available
                      if (availableGroups.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: availableGroups.any((g) => g.id == selectedGroupId)
                              ? selectedGroupId
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Category / Group',
                            prefixIcon: Icon(Icons.folder_outlined, size: 20),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('General / Uncategorized'),
                            ),
                            ...availableGroups.map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(
                                  '${g.name}${g.affectsOverallScore ? " (${g.weightPercentage.toStringAsFixed(0)}% Overall)" : " (Special Award)"}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedGroupId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Criterion Name',
                          hintText: 'e.g. Stage Presence & Poise',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter criterion name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g. Charisma, posture, and confidence',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: maxScoreCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Max Points',
                                hintText: '100',
                              ),
                              validator: (v) {
                                final val = double.tryParse(v ?? '');
                                if (val == null || val <= 0) return 'Invalid points';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: weightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: availableGroups.isNotEmpty
                                    ? 'Weight in Group (%)'
                                    : 'Weight (%)',
                                hintText: '30',
                                suffixText: '%',
                              ),
                              validator: (v) {
                                final val = double.tryParse(v ?? '');
                                if (val == null || val <= 0 || val > 100) return '1 - 100%';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final maxScore = double.parse(maxScoreCtrl.text);
                              final weight = double.parse(weightCtrl.text);

                              final updated = CriterionModel(
                                id: criterion?.id ?? '',
                                eventId: event.id,
                                groupId: selectedGroupId,
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                maxScore: maxScore,
                                weightPercentage: weight,
                                order: criterion?.order ?? nextOrder,
                              );

                              if (criterion == null) {
                                await FirestoreService().addCriterion(updated);
                              } else {
                                await FirestoreService().updateCriterion(updated);
                              }

                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            child: Text(criterion == null ? 'Add' : 'Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCriterion(BuildContext context, CriterionModel criterion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Criterion'),
        content: Text('Are you sure you want to delete "${criterion.name}"?'),
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
              await FirestoreService().deleteCriterion(event.id, criterion.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCriterion(
    List<CriterionModel> criteria,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex < 0 || newIndex >= criteria.length || oldIndex == newIndex) {
      return;
    }
    final updated = List<CriterionModel>.from(criteria);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await FirestoreService().reorderCriteria(event.id, updated);
  }

  Future<void> _applyQuickSort(
    BuildContext context,
    List<CriterionModel> criteria,
    String sortType,
  ) async {
    if (criteria.length < 2) return;
    final sorted = List<CriterionModel>.from(criteria);
    switch (sortType) {
      case 'weight_desc':
        sorted.sort((a, b) => b.weightPercentage.compareTo(a.weightPercentage));
        break;
      case 'weight_asc':
        sorted.sort((a, b) => a.weightPercentage.compareTo(b.weightPercentage));
        break;
      case 'points_desc':
        sorted.sort((a, b) => b.maxScore.compareTo(a.maxScore));
        break;
      case 'name_asc':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    await FirestoreService().reorderCriteria(event.id, sorted);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Criteria order updated for all judges.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CriteriaGroupModel>>(
      stream: FirestoreService().getCriteriaGroupsStream(event.id),
      builder: (context, groupSnapshot) {
        final groups = groupSnapshot.data ?? [];

        return StreamBuilder<List<CriterionModel>>(
          stream: FirestoreService().getCriteriaStream(event.id),
          builder: (context, critSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting &&
                critSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final criteria = critSnapshot.data ?? [];

            // Calculate metrics
            final contributingGroups = groups.where((g) => g.affectsOverallScore).toList();
            final specialAwardGroups = groups.where((g) => !g.affectsOverallScore).toList();
            final totalContributingWeight = contributingGroups.fold<double>(
              0.0,
              (sum, g) => sum + g.weightPercentage,
            );
            final flatCriteriaWeight = criteria.fold<double>(
              0.0,
              (sum, c) => sum + c.weightPercentage,
            );

            final bool hasGroups = groups.isNotEmpty;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Info & Controls Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasGroups
                              ? ((totalContributingWeight == 100.0)
                                  ? AppColors.success.withValues(alpha: 0.5)
                                  : AppColors.warning.withValues(alpha: 0.5))
                              : ((flatCriteriaWeight == 100.0)
                                  ? AppColors.success.withValues(alpha: 0.5)
                                  : AppColors.warning.withValues(alpha: 0.5)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasGroups
                                ? ((totalContributingWeight == 100.0)
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded)
                                : ((flatCriteriaWeight == 100.0)
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded),
                            color: hasGroups
                                ? ((totalContributingWeight == 100.0)
                                    ? AppColors.success
                                    : AppColors.warning)
                                : ((flatCriteriaWeight == 100.0)
                                    ? AppColors.success
                                    : AppColors.warning),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasGroups) ...[
                                  Text(
                                    'Final Score Contributing Weight: ${totalContributingWeight.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: (totalContributingWeight == 100.0)
                                          ? AppColors.success
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    (totalContributingWeight == 100.0)
                                        ? '${contributingGroups.length} contributing categories total 100% perfectly. (${specialAwardGroups.length} standalone awards).'
                                        : 'Target: 100%. Currently ${totalContributingWeight.toStringAsFixed(1)}% across ${contributingGroups.length} contributing categories.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ] else ...[
                                  Text(
                                    'Total Criteria Weight: ${flatCriteriaWeight.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: (flatCriteriaWeight == 100.0)
                                          ? AppColors.success
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    (flatCriteriaWeight == 100.0)
                                        ? 'Criteria weights total 100% perfectly. Drag or use arrows to sort.'
                                        : 'Target is 100% (currently ${flatCriteriaWeight.toStringAsFixed(1)}%). Or add categories for grouped scoring.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // + New Category Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _showAddEditGroupDialog(
                              context,
                              nextOrder: groups.length,
                            ),
                            icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                            label: const Text('+ Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),

                          if (!hasGroups && criteria.length > 1) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Quick Sort Criteria',
                              onSelected: (val) => _applyQuickSort(context, criteria, val),
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'weight_desc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.trending_down_rounded, size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Sort by Weight (High → Low)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'weight_asc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.trending_up_rounded, size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Sort by Weight (Low → High)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'points_desc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.score_outlined, size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Sort by Max Points (High → Low)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'name_asc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sort_by_alpha_rounded, size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Sort Alphabetically (A → Z)'),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sort_rounded, size: 16, color: AppColors.textPrimary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sort',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Criteria Content (Grouped vs Flat)
                    Expanded(
                      child: hasGroups
                          ? _buildGroupedCriteriaView(context, groups, criteria)
                          : _buildFlatCriteriaView(context, criteria, groups),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddEditCriterionDialog(
                  context,
                  availableGroups: groups,
                  nextOrder: criteria.length,
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Criterion'),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------
  // GROUPED VIEW (When 1 or more CriteriaGroupModels exist)
  // ---------------------------------------------------------
  Widget _buildGroupedCriteriaView(
    BuildContext context,
    List<CriteriaGroupModel> groups,
    List<CriterionModel> criteria,
  ) {
    // Separate criteria by groupId
    final Map<String, List<CriterionModel>> criteriaByGroup = {};
    final List<CriterionModel> unassignedCriteria = [];

    for (final crit in criteria) {
      if (crit.groupId.isNotEmpty && groups.any((g) => g.id == crit.groupId)) {
        criteriaByGroup.putIfAbsent(crit.groupId, () => []).add(crit);
      } else {
        unassignedCriteria.add(crit);
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        ...groups.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final group = entry.value;
          final groupCriteria = criteriaByGroup[group.id] ?? [];
          final subCriteriaWeight = groupCriteria.fold<double>(0.0, (s, c) => s + c.weightPercentage);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: group.affectsOverallScore
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: group.affectsOverallScore
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          group.affectsOverallScore ? Icons.pie_chart_rounded : Icons.military_tech_rounded,
                          color: group.affectsOverallScore ? AppColors.primary : const Color(0xFFD97706),
                          size: 22,
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
                                    group.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: group.affectsOverallScore
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    group.affectsOverallScore
                                        ? '${group.weightPercentage.toStringAsFixed(0)}% Weight in Final'
                                        : 'Special Award (Independent)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: group.affectsOverallScore
                                          ? AppColors.primary
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                group.description,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Internal Weight Sum: ${subCriteriaWeight.toStringAsFixed(1)}% '
                              '(${groupCriteria.length} criteria)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: (subCriteriaWeight == 100.0)
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Reorder Group / Edit / Delete buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock / Open status switch button
                          Tooltip(
                            message: group.isLocked
                                ? 'Category is LOCKED. Tap to unlock for judges.'
                                : 'Category is OPEN. Tap to lock from judges.',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final newLocked = !group.isLocked;
                                await FirestoreService().setCriteriaGroupLock(
                                  eventId: event.id,
                                  groupId: group.id,
                                  isLocked: newLocked,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newLocked
                                            ? '${group.name} is now LOCKED. Judges cannot score this category.'
                                            : '${group.name} is now OPEN. Judges can score this category.',
                                      ),
                                      backgroundColor: newLocked ? AppColors.warning : AppColors.success,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: group.isLocked
                                      ? AppColors.danger.withValues(alpha: 0.1)
                                      : AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: group.isLocked
                                        ? AppColors.danger.withValues(alpha: 0.35)
                                        : AppColors.success.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      group.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                      size: 13,
                                      color: group.isLocked ? AppColors.danger : AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      group.isLocked ? 'Locked' : 'Open',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: group.isLocked ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (groups.length > 1) ...[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                              tooltip: 'Move Category Up',
                              onPressed: groupIndex > 0
                                  ? () => _moveGroup(groups, groupIndex, groupIndex - 1)
                                  : null,
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                              tooltip: 'Move Category Down',
                              onPressed: groupIndex < groups.length - 1
                                  ? () => _moveGroup(groups, groupIndex, groupIndex + 1)
                                  : null,
                            ),
                          ],
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                            tooltip: 'Edit Category',
                            onPressed: () => _showAddEditGroupDialog(context, group: group),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                            tooltip: 'Delete Category',
                            onPressed: () => _confirmDeleteGroup(context, group),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Criteria within this group
                  if (groupCriteria.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Text(
                            'No criteria in this group yet.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _showAddEditCriterionDialog(
                              context,
                              defaultGroupId: group.id,
                              availableGroups: groups,
                              nextOrder: criteria.length,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Criterion to this Category'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...groupCriteria.asMap().entries.map((cEntry) {
                      final cIndex = cEntry.key;
                      final crit = cEntry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${cIndex + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crit.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (crit.description.isNotEmpty)
                                    Text(
                                      crit.description,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                '${crit.maxScore.toStringAsFixed(0)} pts',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${crit.weightPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                              tooltip: 'Edit Criterion',
                              onPressed: () => _showAddEditCriterionDialog(
                                context,
                                criterion: crit,
                                availableGroups: groups,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                              tooltip: 'Delete Criterion',
                              onPressed: () => _confirmDeleteCriterion(context, crit),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showAddEditCriterionDialog(
                          context,
                          defaultGroupId: group.id,
                          availableGroups: groups,
                          nextOrder: criteria.length,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Another Criterion to Category'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        // Backward compatibility: Unassigned / Legacy Criteria Section
        if (unassignedCriteria.isNotEmpty) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.warning, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Unassigned / General Criteria',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${unassignedCriteria.length} Criteria',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These criteria are not assigned to any category. Edit each to assign it to a category, or they will be grouped into general scoring.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 18),
                  ...unassignedCriteria.map((crit) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crit.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  if (crit.description.isNotEmpty)
                                    Text(
                                      crit.description,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${crit.weightPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                              tooltip: 'Assign to Category',
                              onPressed: () => _showAddEditCriterionDialog(
                                context,
                                criterion: crit,
                                availableGroups: groups,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                              tooltip: 'Delete Criterion',
                              onPressed: () => _confirmDeleteCriterion(context, crit),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------
  // FLAT VIEW (When NO groups exist yet - 100% backward compatible)
  // ---------------------------------------------------------
  Widget _buildFlatCriteriaView(
    BuildContext context,
    List<CriterionModel> criteria,
    List<CriteriaGroupModel> groups,
  ) {
    if (criteria.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule_folder_outlined, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Criteria Added Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "+ Add Criterion" below or "+ Category" above to get started.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: criteria.length,
      onReorderItem: (oldIndex, newIndex) async {
        await _moveCriterion(criteria, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final crit = criteria[index];
        return Card(
          key: ValueKey(crit.id.isNotEmpty ? crit.id : '${crit.name}_$index'),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              crit.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crit.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    crit.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Max: ${crit.maxScore.toStringAsFixed(0)} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Weight: ${crit.weightPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (criteria.length > 1) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    tooltip: 'Move Up',
                    onPressed: index > 0
                        ? () => _moveCriterion(criteria, index, index - 1)
                        : null,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    tooltip: 'Move Down',
                    onPressed: index < criteria.length - 1
                        ? () => _moveCriterion(criteria, index, index + 1)
                        : null,
                  ),
                ],
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  tooltip: 'Edit',
                  onPressed: () => _showAddEditCriterionDialog(
                    context,
                    criterion: crit,
                    availableGroups: groups,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDeleteCriterion(context, crit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
