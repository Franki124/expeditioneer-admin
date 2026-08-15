import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/journal_repository.dart';
import '../../events/data/participant_repository.dart';
import '../../events/domain/admin_journal.dart';
import '../../events/domain/admin_participant.dart';
import '../../events/widgets/event_picker.dart';
import '../widgets/scans_per_quest_chart.dart';
import '../widgets/stat_tile.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
              Text('Analytics', style: AppTypography.display(fontSize: 24)),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: EventPicker(
                  builder: (context, event) {
                    return StreamBuilder<List<AdminParticipant>>(
                      stream: context.read<ParticipantRepository>().watchParticipants(event.id),
                      builder: (context, participantSnapshot) {
                        return StreamBuilder<List<AdminJournal>>(
                          stream: context.read<JournalRepository>().watchJournals(event.id),
                          builder: (context, journalSnapshot) {
                            final participants = participantSnapshot.data ?? const <AdminParticipant>[];
                            final journals = journalSnapshot.data ?? const <AdminJournal>[];

                            final totalScans = journals.fold<int>(0, (sum, j) => sum + j.scanCount);
                            final completed = participants.where((p) => p.completedAt != null).length;
                            final avgQuests = participants.isEmpty ? 0.0 : totalScans / participants.length;
                            final completionRate = participants.isEmpty ? 0.0 : completed / participants.length * 100;

                            if (participants.isEmpty && journals.isEmpty) {
                              return Center(
                                child: Text(
                                  'No activity yet for "${event.name}".',
                                  style: AppTypography.body(color: AppColors.creamDim),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm12,
                                  runSpacing: AppSpacing.sm12,
                                  children: [
                                    StatTile(label: 'Participants', value: '${participants.length}'),
                                    StatTile(label: 'Total scans', value: '$totalScans'),
                                    StatTile(label: 'Avg quests / player', value: avgQuests.toStringAsFixed(1)),
                                    StatTile(label: 'Completion rate', value: '${completionRate.toStringAsFixed(0)}%'),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md24),
                                Text('Scans per quest', style: AppTypography.body(fontWeight: FontWeight.w800)),
                                const SizedBox(height: AppSpacing.sm14),
                                Expanded(child: ScansPerQuestChart(journals: journals)),
                              ],
                            );
                          },
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
