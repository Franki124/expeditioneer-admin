import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../data/event_repository.dart';
import '../domain/admin_event.dart';
import '../widgets/event_card.dart';
import 'create_event_dialog.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, required this.onViewParticipants});

  final void Function(AdminEvent event) onViewParticipants;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';

  Future<void> _confirmDelete(BuildContext context, AdminEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Delete "${event.name}"?', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: Text(
          'This permanently deletes the event and its quests. This cannot be undone.',
          style: AppTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: AppTypography.body(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EventRepository>().deleteEvent(event.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EventRepository>();
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Events', style: AppTypography.display(fontSize: 24)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => showCreateEventDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New event'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md20),
              TextField(
                style: AppTypography.body(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search events',
                ),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: StreamBuilder<List<AdminEvent>>(
                  stream: repository.watchAllEvents(),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? const <AdminEvent>[];
                    final filtered = _query.isEmpty
                        ? events
                        : events
                            .where((event) =>
                                event.name.toLowerCase().contains(_query) ||
                                event.location.toLowerCase().contains(_query) ||
                                event.joinCode.toLowerCase().contains(_query))
                            .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          events.isEmpty ? 'No events yet.' : 'No events match your search.',
                          style: AppTypography.body(color: AppColors.creamDim),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm12),
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return EventCard(
                          event: event,
                          onActivate: () => repository.updateStatus(event.id, 'live'),
                          onDeactivate: () => repository.updateStatus(event.id, 'closed'),
                          onArchive: () => repository.updateStatus(event.id, 'archived'),
                          onRestore: () => repository.updateStatus(event.id, 'draft'),
                          onDelete: () => _confirmDelete(context, event),
                          onViewParticipants: () => widget.onViewParticipants(event),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
