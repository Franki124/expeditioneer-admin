import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/event_repository.dart';
import '../../events/data/journal_repository.dart';
import '../../events/data/quest_library_repository.dart';
import '../../events/domain/admin_event.dart';
import '../../events/domain/admin_journal.dart';
import '../../events/domain/manual_code.dart';
import '../widgets/quest_list_tile.dart';
import 'quest_form_dialog.dart';
import 'quest_library_picker_dialog.dart';
import 'quest_qr_print_sheet.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  String? _selectedEventId;

  Future<void> _confirmDelete(BuildContext context, String eventId, AdminJournal journal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Delete "${journal.title}"?', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: const Text('This removes the quest and its QR code becomes invalid.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: AppTypography.body(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<JournalRepository>().deleteJournal(eventId: eventId, journalId: journal.id);
    }
  }

  /// Bulk-adds the picked templates directly (no per-quest review form) —
  /// the point of multi-select is speed; adjust any of them afterward via
  /// the normal edit flow if needed.
  Future<void> _addFromLibrary(BuildContext context, String eventId, List<AdminJournal> existingJournals) async {
    final templates = await showQuestLibraryPickerDialog(context);
    if (templates == null || templates.isEmpty || !context.mounted) return;

    final journalRepository = context.read<JournalRepository>();
    final libraryRepository = context.read<QuestLibraryRepository>();
    final random = Random.secure();
    final takenCodes = existingJournals.map((j) => normalizeManualCode(j.manualCode ?? '')).toSet();
    var nextOrder = existingJournals.length + 1;

    for (final template in templates) {
      late String code;
      do {
        code = generateManualCode(random);
      } while (takenCodes.contains(code));
      takenCodes.add(code);

      if (template.type == QuestType.quiz) {
        final questions = await libraryRepository.copyQuestions(template.id);
        await journalRepository.createQuiz(
          eventId: eventId,
          title: template.title,
          blurb: template.blurb,
          order: nextOrder++,
          difficulty: template.difficulty ?? 'medium',
          timerSeconds: template.timerSeconds,
          manualCode: code,
          questions: questions,
        );
      } else {
        await journalRepository.createJournal(
          eventId: eventId,
          title: template.title,
          blurb: template.blurb,
          order: nextOrder++,
          artUrl: template.artUrl,
          type: template.type,
          model3dUrl: template.model3dUrl,
          manualCode: code,
          points: template.points,
        );
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${templates.length} quest${templates.length == 1 ? '' : 's'}.')),
      );
    }
  }

  Future<void> _saveToLibrary(BuildContext context, String eventId, AdminJournal journal) async {
    final libraryRepository = context.read<QuestLibraryRepository>();
    if (journal.type == QuestType.quiz) {
      final questions = await context.read<JournalRepository>().watchQuestions(eventId, journal.id).first;
      await libraryRepository.addQuizEntry(
        title: journal.title,
        blurb: journal.blurb,
        difficulty: journal.difficulty,
        timerSeconds: journal.timerSeconds,
        questions: questions,
      );
    } else {
      await libraryRepository.addEntry(
        title: journal.title,
        blurb: journal.blurb,
        type: journal.type,
        artUrl: journal.artUrl,
        model3dUrl: journal.model3dUrl,
        points: journal.points,
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${journal.title}" saved to library.')),
      );
    }
  }

  void _editJournal(BuildContext context, String eventId, List<AdminJournal> existingJournals, AdminJournal journal) {
    showQuestFormDialog(context, eventId: eventId, existingJournals: existingJournals, editing: journal);
  }

  Future<void> _reorderJournals(
    BuildContext context,
    String eventId,
    List<AdminJournal> journals,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<AdminJournal>.from(journals);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    return context.read<JournalRepository>().reorderJournals(
          eventId: eventId,
          orderedJournalIds: reordered.map((j) => j.id).toList(),
        );
  }

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
              Text('Quests', style: AppTypography.display(fontSize: 24)),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: StreamBuilder<List<AdminEvent>>(
                stream: context.read<EventRepository>().watchAllEvents(),
                builder: (context, snapshot) {
                  final events = snapshot.data ?? const <AdminEvent>[];
                  if (events.isEmpty) {
                    return Text(
                      'Create an event first, then add its quests here.',
                      style: AppTypography.body(color: AppColors.creamDim),
                    );
                  }
                  _selectedEventId ??= events.first.id;
                  final selected = events.firstWhere(
                    (e) => e.id == _selectedEventId,
                    orElse: () => events.first,
                  );
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
                      Expanded(
                        child: StreamBuilder<List<AdminJournal>>(
                          stream: context.read<JournalRepository>().watchJournals(selected.id),
                          builder: (context, journalSnapshot) {
                            final journals = journalSnapshot.data ?? const <AdminJournal>[];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => showQuestFormDialog(
                                        context,
                                        eventId: selected.id,
                                        existingJournals: journals,
                                      ),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add quest'),
                                    ),
                                    const SizedBox(width: AppSpacing.sm12),
                                    OutlinedButton.icon(
                                      onPressed: () => _addFromLibrary(context, selected.id, journals),
                                      icon: const Icon(Icons.auto_stories_outlined, size: 18),
                                      label: const Text('Add from library'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.cream,
                                        side: BorderSide(color: AppColors.cream.withValues(alpha: 0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm12),
                                    OutlinedButton.icon(
                                      onPressed: journals.isEmpty
                                          ? null
                                          : () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => QuestQrPrintSheet(
                                                    journals: journals,
                                                    eventName: selected.name,
                                                  ),
                                                ),
                                              ),
                                      icon: const Icon(Icons.print, size: 18),
                                      label: const Text('Print QR codes'),
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
                                  child: journals.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No quests yet for "${selected.name}".',
                                            style: AppTypography.body(color: AppColors.creamDim),
                                          ),
                                        )
                                      : ReorderableListView.builder(
                                          buildDefaultDragHandles: false,
                                          itemCount: journals.length,
                                          onReorder: (oldIndex, newIndex) =>
                                              _reorderJournals(context, selected.id, journals, oldIndex, newIndex),
                                          proxyDecorator: (child, index, animation) => Material(
                                            color: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
                                            clipBehavior: Clip.antiAlias,
                                            elevation: 6,
                                            shadowColor: Colors.black.withValues(alpha: 0.5),
                                            child: child,
                                          ),
                                          itemBuilder: (context, index) {
                                            final journal = journals[index];
                                            return Padding(
                                              key: ValueKey(journal.id),
                                              padding: const EdgeInsets.only(bottom: AppSpacing.sm12),
                                              child: QuestListTile(
                                                index: index,
                                                journal: journal,
                                                onEdit: () => _editJournal(context, selected.id, journals, journal),
                                                onDelete: () => _confirmDelete(context, selected.id, journal),
                                                onSaveToLibrary: () => _saveToLibrary(context, selected.id, journal),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
