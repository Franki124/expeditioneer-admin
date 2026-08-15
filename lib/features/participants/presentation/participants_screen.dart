import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/participant_repository.dart';
import '../../events/domain/admin_participant.dart';
import '../../events/widgets/event_picker.dart';

class ParticipantsScreen extends StatelessWidget {
  const ParticipantsScreen({super.key, this.initialEventId});

  final String? initialEventId;

  Future<void> _grantPoints(BuildContext context, String eventId, AdminParticipant participant) async {
    final controller = TextEditingController();
    final points = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text(
          'Grant points to ${participant.displayName}',
          style: AppTypography.body(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          style: AppTypography.body(),
          decoration: const InputDecoration(labelText: 'Points (negative to correct)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
            child: const Text('Grant'),
          ),
        ],
      ),
    );
    if (points == null || points == 0 || !context.mounted) return;
    try {
      await context.read<ParticipantRepository>().grantBonusPoints(
            eventId: eventId,
            participantId: participant.uid,
            points: points,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${points > 0 ? '+$points' : '$points'} points ${points > 0 ? 'granted to' : 'corrected for'} '
              '${participant.displayName}.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not grant points. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Participants', style: AppTypography.display(fontSize: 24)),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: EventPicker(
                  initialEventId: initialEventId,
                  builder: (context, event) {
                    return StreamBuilder<List<AdminParticipant>>(
                      stream: context.read<ParticipantRepository>().watchParticipants(event.id),
                      builder: (context, snapshot) {
                        final participants = snapshot.data ?? const <AdminParticipant>[];
                        if (participants.isEmpty) {
                          return Center(
                            child: Text(
                              'No one has joined "${event.name}" yet.',
                              style: AppTypography.body(color: AppColors.creamDim),
                            ),
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingTextStyle: AppTypography.body(fontWeight: FontWeight.w800, color: AppColors.creamDim),
                                dataTextStyle: AppTypography.body(),
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Joined')),
                                  DataColumn(label: Text('Points')),
                                  DataColumn(label: Text('Bonus')),
                                  DataColumn(label: Text('Collected')),
                                  DataColumn(label: Text('Last scan')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('')),
                                ],
                                rows: [
                                  for (final participant in participants)
                                    DataRow(cells: [
                                      DataCell(Text(participant.displayName)),
                                      DataCell(Text(dateFormat.format(participant.joinedAt))),
                                      DataCell(Text('${participant.totalPoints}')),
                                      DataCell(Text(
                                        participant.bonusPoints == 0 ? '—' : '${participant.bonusPoints}',
                                        style: TextStyle(
                                          color: participant.bonusPoints == 0 ? AppColors.creamDim : AppColors.gold,
                                        ),
                                      )),
                                      DataCell(Text('${participant.collectedCount}')),
                                      DataCell(Text(
                                        participant.lastScanAt == null ? '—' : dateFormat.format(participant.lastScanAt!),
                                      )),
                                      DataCell(Text(
                                        participant.completedAt != null ? 'Completed' : 'In progress',
                                        style: TextStyle(
                                          color: participant.completedAt != null ? AppColors.teal : AppColors.creamDim,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        tooltip: 'Grant points',
                                        onPressed: () => _grantPoints(context, event.id, participant),
                                      )),
                                    ]),
                                ],
                              ),
                            ),
                          ),
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
