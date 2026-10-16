import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/event_provider.dart';
import '../../services/firestore_service.dart';
import 'criteria_manager_view.dart';
import 'contestant_manager_view.dart';
import 'contestant_elimination_view.dart';
import 'judge_generator_view.dart';
import 'consolidated_results_view.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().setSelectedEvent(_currentEvent);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateStatus(EventStatus newStatus) async {
    setState(() {
      _currentEvent = _currentEvent.copyWith(status: newStatus);
    });
    await FirestoreService().updateEventStatus(_currentEvent.id, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event is now ${newStatus.displayName}!'),
          backgroundColor: newStatus == EventStatus.active ? AppColors.success : AppColors.primary,
        ),
      );
    }
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Change Event Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                title: const Text('Draft (Setup Phase)'),
                subtitle: const Text('Judges cannot submit scores yet'),
                trailing: _currentEvent.status == EventStatus.draft
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateStatus(EventStatus.draft);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.success),
                title: const Text('Live / Open for Scoring'),
                subtitle: const Text('Judges can evaluate and submit scores'),
                trailing: _currentEvent.status == EventStatus.active
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateStatus(EventStatus.active);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: AppColors.textMuted),
                title: const Text('Completed / Finalized'),
                subtitle: const Text('Scoring is locked and finalized'),
                trailing: _currentEvent.status == EventStatus.completed
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateStatus(EventStatus.completed);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (_currentEvent.status) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentEvent.title),
        actions: [
          // Status Action Pill
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: Icon(
                _currentEvent.status == EventStatus.active
                    ? Icons.fiber_manual_record
                    : Icons.circle,
                size: 14,
                color: statusColor,
              ),
              label: Text(
                _currentEvent.status.displayName,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.12),
              side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
              onPressed: () => _showStatusMenu(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.rule_folder_outlined), text: 'Criteria'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Contestants'),
            Tab(icon: Icon(Icons.person_off_outlined), text: 'Elimination'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'Judges'),
            Tab(icon: Icon(Icons.leaderboard_outlined), text: 'Live Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CriteriaManagerView(event: _currentEvent),
          ContestantManagerView(event: _currentEvent),
          ContestantEliminationView(event: _currentEvent),
          JudgeGeneratorView(event: _currentEvent),
          ConsolidatedResultsView(event: _currentEvent),
        ],
      ),
    );
  }
}
