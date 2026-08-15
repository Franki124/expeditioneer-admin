import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/admin_journal.dart';
import 'quest_qr_code.dart';

class QuestListTile extends StatefulWidget {
  const QuestListTile({
    super.key,
    required this.index,
    required this.journal,
    required this.onEdit,
    required this.onDelete,
    required this.onSaveToLibrary,
  });

  final int index;
  final AdminJournal journal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function() onSaveToLibrary;

  @override
  State<QuestListTile> createState() => _QuestListTileState();
}

class _QuestListTileState extends State<QuestListTile> {
  bool _saving = false;
  bool _savedToLibrary = false;

  Future<void> _handleSaveToLibrary() async {
    setState(() => _saving = true);
    await widget.onSaveToLibrary();
    if (mounted) {
      setState(() {
        _saving = false;
        _savedToLibrary = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md20),
      decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: widget.index,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm12, top: 4),
              child: Icon(Icons.drag_indicator, color: AppColors.creamDim),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: journal.type),
                    if (journal.type == QuestType.quiz && journal.difficulty != null) ...[
                      const SizedBox(width: AppSpacing.xs8),
                      _DifficultyBadge(difficulty: journal.difficulty!),
                    ],
                    const SizedBox(width: AppSpacing.xs8),
                    Expanded(
                      child: Text(journal.title, style: AppTypography.display(fontSize: 20)),
                    ),
                    Text(
                      '${journal.points} pts',
                      style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  journal.blurb,
                  style: AppTypography.body(fontSize: 16, color: AppColors.creamDim),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (journal.type == QuestType.quiz) ...[
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    '${journal.questionCount} question${journal.questionCount == 1 ? '' : 's'}'
                    '${journal.timerSeconds != null ? ' · ${(journal.timerSeconds! / 60).ceil()} min limit' : ''}',
                    style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
                  ),
                ],
                if (!journal.hasAsset) ...[
                  const SizedBox(height: AppSpacing.xs8),
                  Text(
                    'Attach an image/model URL to generate a QR code.',
                    style: AppTypography.body(fontSize: 13, color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (journal.hasAsset && journal.manualCode != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      journal.manualCode!,
                      style: AppTypography.monospace.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    QuestQrCode(data: journal.manualCode!, title: journal.title),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm12),
              ],
              Column(
                children: [
                  _SquareIconButton(icon: Icons.edit, tooltip: 'Edit quest', onPressed: widget.onEdit),
                  const SizedBox(height: AppSpacing.xs8),
                  _SquareIconButton(
                    icon: _savedToLibrary ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                    tooltip: _savedToLibrary ? 'Saved to library' : 'Save to library',
                    color: AppColors.teal,
                    loading: _saving,
                    onPressed: _saving || _savedToLibrary ? null : _handleSaveToLibrary,
                  ),
                  const SizedBox(height: AppSpacing.xs8),
                  _SquareIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete quest',
                    color: AppColors.error,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.cream,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final effectiveColor = disabled && !loading ? color.withValues(alpha: 0.5) : color;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.button,
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadii.button,
              border: Border.all(color: effectiveColor.withValues(alpha: 0.4)),
            ),
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: effectiveColor),
                  )
                : Icon(icon, size: 22, color: effectiveColor),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      QuestType.gestral => AppColors.teal,
      QuestType.quiz => AppColors.error,
      _ => AppColors.gold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadii.pillShape,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      'hard' => AppColors.error,
      'medium' => AppColors.gold,
      _ => AppColors.teal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadii.pillShape,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
