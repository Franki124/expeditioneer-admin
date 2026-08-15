import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../domain/admin_event.dart';
import 'event_status_badge.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onActivate,
    required this.onDeactivate,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.onViewParticipants,
  });

  final AdminEvent event;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onViewParticipants;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y  h:mm a');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md20),
      decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EventStatusBadge(status: event.status),
              const Spacer(),
              IconButton(
                tooltip: 'View participants',
                icon: const Icon(Icons.people_outline, size: 20, color: AppColors.creamDim),
                onPressed: onViewParticipants,
              ),
              Text(
                event.joinCode,
                style: AppTypography.monospace.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs8),
          Text(event.name, style: AppTypography.display(fontSize: 20)),
          const SizedBox(height: AppSpacing.xs4),
          Text(event.location, style: AppTypography.body(fontSize: 16, color: AppColors.creamDim)),
          const SizedBox(height: AppSpacing.sm12),
          Wrap(
            spacing: AppSpacing.md20,
            runSpacing: AppSpacing.xs4,
            children: [
              _InfoChip(label: 'Quests', value: '${event.journalCount}'),
              _InfoChip(label: 'Auto-closes', value: dateFormat.format(event.endAt)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm12),
          Wrap(
            spacing: AppSpacing.xs8,
            runSpacing: AppSpacing.xs8,
            children: _actionsFor(event.status),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(String status) {
    switch (status) {
      case 'draft':
        return [
          _ActionButton(label: 'Activate', onPressed: onActivate),
          _ActionButton(label: 'Delete', destructive: true, onPressed: onDelete),
        ];
      case 'live':
        return [
          _ActionButton(label: 'Deactivate', onPressed: onDeactivate),
        ];
      case 'closed':
        return [
          _ActionButton(label: 'Activate', onPressed: onActivate),
          _ActionButton(label: 'Archive', onPressed: onArchive),
        ];
      case 'archived':
        return [
          _ActionButton(label: 'Restore', onPressed: onRestore),
          _ActionButton(label: 'Delete', destructive: true, onPressed: onDelete),
        ];
      default:
        return const [];
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTypography.body(fontSize: 14, color: AppColors.creamDim),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.cream),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed, this.destructive = false});

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? AppColors.error : AppColors.cream,
        side: BorderSide(color: (destructive ? AppColors.error : AppColors.cream).withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm14, vertical: AppSpacing.xs8),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
      child: Text(label, style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}
