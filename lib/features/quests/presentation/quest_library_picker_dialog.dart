import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/quest_library_repository.dart';
import '../../events/domain/admin_journal.dart' show QuestType;
import '../../events/domain/quest_template.dart';

/// Lets the admin multi-select saved quest templates to add to an event in
/// one go (copy-on-attach, not a live reference — see QuestTemplate), and
/// doubles as light management (delete) for the library itself. Returns the
/// picked templates, or null if cancelled.
Future<List<QuestTemplate>?> showQuestLibraryPickerDialog(BuildContext context) {
  return showDialog<List<QuestTemplate>>(
    context: context,
    builder: (dialogContext) => RepositoryProvider.value(
      value: context.read<QuestLibraryRepository>(),
      child: const _QuestLibraryPickerDialog(),
    ),
  );
}

class _QuestLibraryPickerDialog extends StatefulWidget {
  const _QuestLibraryPickerDialog();

  @override
  State<_QuestLibraryPickerDialog> createState() => _QuestLibraryPickerDialogState();
}

class _QuestLibraryPickerDialogState extends State<_QuestLibraryPickerDialog> {
  final Set<String> _selectedIds = {};

  Future<void> _confirmDelete(QuestTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Remove "${template.title}"?', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: const Text('This removes it from the library. Quests already created from it are unaffected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Remove', style: AppTypography.body(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _selectedIds.remove(template.id));
      context.read<QuestLibraryRepository>().deleteEntry(template.id);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleAll(List<QuestTemplate> templates) {
    setState(() {
      if (_selectedIds.length == templates.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(templates.map((t) => t.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.navyPanel2,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: StreamBuilder<List<QuestTemplate>>(
            stream: context.read<QuestLibraryRepository>().watchAll(),
            builder: (context, snapshot) {
              final templates = snapshot.data ?? const <QuestTemplate>[];
              final allSelected = templates.isNotEmpty && _selectedIds.length == templates.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Quest library', style: AppTypography.display(fontSize: 20)),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Pick one or more saved quests to add to this event.',
                    style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
                  ),
                  const SizedBox(height: AppSpacing.md20),
                  if (templates.isEmpty)
                    Text(
                      'No saved quests yet. Use "Save to library" on any quest in the Quests tab.',
                      style: AppTypography.body(color: AppColors.creamDim),
                    )
                  else ...[
                    InkWell(
                      borderRadius: AppRadii.button,
                      onTap: () => _toggleAll(templates),
                      child: Row(
                        children: [
                          Checkbox(value: allSelected, onChanged: (_) => _toggleAll(templates)),
                          Text('Select all', style: AppTypography.body(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Divider(height: AppSpacing.md20, color: AppColors.navyPanel),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: templates.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs8),
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          final selected = _selectedIds.contains(template.id);
                          return InkWell(
                            borderRadius: AppRadii.card,
                            onTap: () => _toggle(template.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs8),
                              decoration:
                                  BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
                              child: Row(
                                children: [
                                  Checkbox(value: selected, onChanged: (_) => _toggle(template.id)),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _typeColor(template.type).withValues(alpha: 0.16),
                                      borderRadius: AppRadii.pillShape,
                                    ),
                                    child: Text(
                                      template.type.toUpperCase(),
                                      style: AppTypography.body(fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.title,
                                          style: AppTypography.body(fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          template.blurb,
                                          style: AppTypography.body(fontSize: 12, color: AppColors.creamDim),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    tooltip: 'Remove from library',
                                    onPressed: () => _confirmDelete(template),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.xs8),
                      ElevatedButton(
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(
                                  templates.where((t) => _selectedIds.contains(t.id)).toList(),
                                ),
                        child: Text(_selectedIds.isEmpty ? 'Add' : 'Add ${_selectedIds.length}'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _typeColor(String type) => switch (type) {
      QuestType.gestral => AppColors.teal,
      QuestType.quiz => AppColors.error,
      _ => AppColors.gold,
    };
