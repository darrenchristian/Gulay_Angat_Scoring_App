import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class CriteriaManagerView extends StatelessWidget {
  final EventModel event;

  const CriteriaManagerView({super.key, required this.event});

  void _showAddEditCriterionDialog(
    BuildContext context, {
    CriterionModel? criterion,
    int nextOrder = 0,
  }) {
    final nameCtrl = TextEditingController(text: criterion?.name ?? '');
    final descCtrl = TextEditingController(text: criterion?.description ?? '');
    final maxScoreCtrl = TextEditingController(text: (criterion?.maxScore ?? 100).toString());
    final weightCtrl = TextEditingController(text: (criterion?.weightPercentage ?? 100).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
                          decoration: const InputDecoration(
                            labelText: 'Weight (%)',
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, CriterionModel criterion) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CriterionModel>>(
      stream: FirestoreService().getCriteriaStream(event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final criteria = snapshot.data ?? [];
        final totalWeight = criteria.fold<double>(0.0, (sum, c) => sum + c.weightPercentage);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Weight & Sort Controls Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (totalWeight == 100.0)
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (totalWeight == 100.0)
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: (totalWeight == 100.0) ? AppColors.success : AppColors.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Weight: ${totalWeight.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: (totalWeight == 100.0) ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              (totalWeight == 100.0)
                                  ? 'Criteria weights total 100% perfectly. Drag or use arrows to sort.'
                                  : 'Ideal sum is 100% (currently ${totalWeight.toStringAsFixed(1)}%). Drag or use arrows to sort.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (criteria.length > 1) ...[
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
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${criteria.length} Criteria',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Criteria Reorderable List
                Expanded(
                  child: criteria.isEmpty
                      ? Center(
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
                                'Tap "+ Add Criterion" below to setup scoring criteria.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
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
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                      tooltip: 'Delete',
                                      onPressed: () => _confirmDelete(context, crit),
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
            onPressed: () => _showAddEditCriterionDialog(
              context,
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
  }
}
