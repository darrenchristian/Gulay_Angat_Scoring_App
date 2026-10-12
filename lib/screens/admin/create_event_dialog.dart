import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class CreateEventDialog extends StatefulWidget {
  const CreateEventDialog({super.key});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedJudgeIds = {};
  bool _initializedSelection = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final assignedList = _selectedJudgeIds.toList();
      final newEvent = EventModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: EventStatus.draft,
        judgeCount: assignedList.length,
        assignedJudgeIds: assignedList,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createEvent(newEvent).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(
          'Connection timed out. Please check your internet connection.',
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorText = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'e.g. Clay Modelling Competition',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief summary of the competition or guidelines',
                  ),
                ),
                const SizedBox(height: 16),

                // Global Judges Pool Selector
                Flexible(
                  child: StreamBuilder<List<JudgeModel>>(
                    stream: FirestoreService().getGlobalJudgesStream(),
                    builder: (context, snapshot) {
                      final allJudges = snapshot.data ?? [];

                      // Default select all active judges on first load
                      if (!_initializedSelection && snapshot.hasData) {
                        _initializedSelection = true;
                        for (final j in allJudges.where((j) => j.isActive)) {
                          _selectedJudgeIds.add(j.id);
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Link Judges (${_selectedJudgeIds.length} selected)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (allJudges.isNotEmpty)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedJudgeIds.length == allJudges.length) {
                                        _selectedJudgeIds.clear();
                                      } else {
                                        _selectedJudgeIds.addAll(allJudges.map((j) => j.id));
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedJudgeIds.length == allJudges.length
                                        ? 'Clear All'
                                        : 'Select All',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (allJudges.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No global judges in pool yet. You can create and link judges anytime after creating the event.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.cardBorder),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: allJudges.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final judge = allJudges[index];
                                    final isChecked = _selectedJudgeIds.contains(judge.id);

                                    return CheckboxListTile(
                                      dense: true,
                                      value: isChecked,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedJudgeIds.add(judge.id);
                                          } else {
                                            _selectedJudgeIds.remove(judge.id);
                                          }
                                        });
                                      },
                                      title: Text(
                                        judge.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        judge.accessCode,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: AppColors.judgeBadge,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 44),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Event'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
