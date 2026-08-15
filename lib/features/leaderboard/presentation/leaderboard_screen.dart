import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/web/csv_export.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/participant_repository.dart';
import '../../events/domain/admin_participant.dart';
import '../../events/widgets/event_picker.dart';
import '../widgets/live_pulse_indicator.dart';
import '../widgets/rank_row.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leaderboard', style: AppTypography.display(fontSize: 24)),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: EventPicker(
                  builder: (context, event) {
                    return StreamBuilder<List<AdminParticipant>>(
                      stream: context.read<ParticipantRepository>().watchLeaderboard(event.id),
                      builder: (context, snapshot) {
                        final participants = snapshot.data ?? const <AdminParticipant>[];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const LivePulseIndicator(),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: participants.isEmpty
                                      ? null
                                      : () => exportParticipantsCsv(eventName: event.name, participants: participants),
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Export CSV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.cream,
                                    side: BorderSide(color: AppColors.cream.withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md20),
                            Expanded(
                              child: participants.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No one has joined "${event.name}" yet.',
                                        style: AppTypography.body(color: AppColors.creamDim),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: participants.length,
                                      itemBuilder: (context, index) =>
                                          RankRow(rank: index + 1, participant: participants[index]),
                                    ),
                            ),
                          ],
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
