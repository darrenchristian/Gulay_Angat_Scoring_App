import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'create_event_dialog.dart';
import 'event_detail_screen.dart';
import 'global_judges_pool_view.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  void _showCreateEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateEventDialog(),
    );
  }

  void _confirmDeleteEvent(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This cannot be undone.'),
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
              await FirestoreService().deleteEvent(event.id);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/gulay_angat_logo.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedIndex == 0 ? 'GulayAngat ScoreSync • Events' : 'GulayAngat ScoreSync • Judges Pool',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out Admin',
            onPressed: () => context.read<AppAuthProvider>().logout(),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildEventsTab(context)
          : const GlobalJudgesPoolView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded, color: AppColors.primary),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded, color: AppColors.judgeBadge),
            label: 'Judges Pool',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateEvent(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Event'),
            )
          : null,
    );
  }

  Widget _buildEventsTab(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: FirestoreService().getEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Events Created Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the "+ New Event" button below to create your first competition and link judges from your pool.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 48),
                    ),
                    onPressed: () => _showCreateEvent(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Event'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];

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

            final judgeCountDisplay = event.effectiveJudgeCount;

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(event: event),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: statusColor),
                                const SizedBox(width: 5),
                                Text(
                                  event.status.displayName,
                                  style: TextStyle(
                                    color: statusColor,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('MMM d, yyyy').format(event.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.badge_outlined, size: 14, color: AppColors.judgeBadge),
                          const SizedBox(width: 4),
                          Text(
                            '$judgeCountDisplay Linked Judges',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.judgeBadge,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                            tooltip: 'Delete Event',
                            onPressed: () => _confirmDeleteEvent(context, event),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
