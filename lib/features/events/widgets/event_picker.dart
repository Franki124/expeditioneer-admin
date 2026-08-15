import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../data/event_repository.dart';
import '../domain/admin_event.dart';

/// Shared "event picker pills" header, used by Leaderboard/Participants
/// screens (Quests has its own copy since it also owns the quest-add
/// button row alongside the chips).
class EventPicker extends StatefulWidget {
  const EventPicker({
    super.key,
    required this.builder,
    this.emptyMessage = 'Create an event first.',
    this.initialEventId,
  });

  final Widget Function(BuildContext context, AdminEvent selectedEvent) builder;
  final String emptyMessage;

  /// Pre-selects this event id on first build (e.g. deep-linked from an
  /// event row's "View participants" action) instead of defaulting to the
  /// newest event.
  final String? initialEventId;

  @override
  State<EventPicker> createState() => _EventPickerState();
}

class _EventPickerState extends State<EventPicker> {
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminEvent>>(
      stream: context.read<EventRepository>().watchAllEvents(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <AdminEvent>[];
        if (events.isEmpty) {
          return Center(child: Text(widget.emptyMessage, style: AppTypography.body(color: AppColors.creamDim)));
        }
        _selectedEventId ??= widget.initialEventId ?? events.first.id;
        final selected = events.firstWhere((e) => e.id == _selectedEventId, orElse: () => events.first);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs8,
              runSpacing: AppSpacing.xs8,
              children: [
                for (final event in events)
                  ChoiceChip(
                    label: Text(event.name),
                    selected: event.id == selected.id,
                    onSelected: (_) => setState(() => _selectedEventId = event.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md20),
            Expanded(child: widget.builder(context, selected)),
          ],
        );
      },
    );
  }
}
