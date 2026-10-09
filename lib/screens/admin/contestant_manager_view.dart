import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class ContestantManagerView extends StatelessWidget {
  final EventModel event;

  const ContestantManagerView({super.key, required this.event});

  void _showAddEditContestantDialog(
    BuildContext context,
    int currentContestantCount, [
    ContestantModel? contestant,
  ]) {
    final numberCtrl = TextEditingController(
      text: (contestant?.number ?? (currentContestantCount + 1)).toString(),
    );
    final nameCtrl = TextEditingController(text: contestant?.name ?? '');
    final repCtrl = TextEditingController(text: contestant?.representation ?? '');
    final bioCtrl = TextEditingController(text: contestant?.bio ?? '');
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
                    contestant == null ? 'Add Contestant' : 'Edit Contestant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: numberCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'No. #',
                          ),
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Contestant / Group Name',
                            hintText: 'e.g. Maya Lin',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Enter contestant name' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: repCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Department / Representing',
                      hintText: 'e.g. College of Science / Team Blue',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bioCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Short Bio / Song / Piece (Optional)',
                      hintText: 'e.g. Performing "Bohemian Rhapsody"',
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
                          final number = int.parse(numberCtrl.text);

                          final updated = ContestantModel(
                            id: contestant?.id ?? '',
                            eventId: event.id,
                            number: number,
                            name: nameCtrl.text.trim(),
                            representation: repCtrl.text.trim(),
                            bio: bioCtrl.text.trim(),
                          );

                          if (contestant == null) {
                            await FirestoreService().addContestant(updated);
                          } else {
                            await FirestoreService().updateContestant(updated);
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Text(contestant == null ? 'Add' : 'Save'),
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

  void _confirmDelete(BuildContext context, ContestantModel contestant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contestant'),
        content: Text('Are you sure you want to delete #${contestant.number} ${contestant.name}?'),
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
              await FirestoreService().deleteContestant(event.id, contestant.id);
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
    return StreamBuilder<List<ContestantModel>>(
      stream: FirestoreService().getContestantsStream(event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contestants = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${contestants.length} Registered Contestants',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Ordered by sequence',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Contestants List
                Expanded(
                  child: contestants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline_rounded, size: 54, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No Contestants Registered',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+ Add Contestant" below to register candidates.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: contestants.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final contestant = contestants[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    '#${contestant.number}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  contestant.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (contestant.representation.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        contestant.representation,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                    if (contestant.bio.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        contestant.bio,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                      tooltip: 'Edit',
                                      onPressed: () => _showAddEditContestantDialog(
                                        context,
                                        contestants.length,
                                        contestant,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                      tooltip: 'Delete',
                                      onPressed: () => _confirmDelete(context, contestant),
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
            onPressed: () => _showAddEditContestantDialog(context, contestants.length),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Contestant'),
          ),
        );
      },
    );
  }
}
