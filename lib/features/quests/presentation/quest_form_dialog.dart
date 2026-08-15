import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/cloudinary_image.dart';
import '../../../core/web/asset_upload.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/asset_library_repository.dart';
import '../../events/data/journal_repository.dart';
import '../../events/domain/admin_journal.dart';
import '../../events/domain/asset_library_entry.dart';
import '../../events/domain/manual_code.dart';
import '../../events/domain/quiz_question.dart';
import 'asset_picker_dialog.dart';

const _minAnswers = 2;
const _maxAnswers = 4;

/// Add/edit quest form. [existingJournals] is the already-loaded quest list
/// for this event, used for local manualCode-uniqueness checks and to
/// default the new quest's display order.
///
/// A single popup covers all three quest types (Journal/Gestral/Quiz) —
/// picking Quiz swaps the body to the quiz builder and the dialog grows via
/// [AnimatedSize] rather than navigating to a separate full-screen route.
/// Display order is no longer editable here: it's implicit (append-to-end on
/// create, unchanged on edit) — reordering happens by dragging quest cards
/// in `quests_screen.dart`.
Future<void> showQuestFormDialog(
  BuildContext context, {
  required String eventId,
  required List<AdminJournal> existingJournals,
  AdminJournal? editing,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: context.read<JournalRepository>()),
        RepositoryProvider.value(value: context.read<AssetLibraryRepository>()),
      ],
      child: _QuestFormDialog(eventId: eventId, existingJournals: existingJournals, editing: editing),
    ),
  );
}

class _AnswerDraft {
  _AnswerDraft({String text = '', this.correct = false})
      : key = UniqueKey(),
        textController = TextEditingController(text: text);

  final Key key;
  final TextEditingController textController;
  bool correct;

  void dispose() => textController.dispose();
}

class _QuestionDraft {
  _QuestionDraft({
    String prompt = '',
    this.imageUrl,
    String explanation = '',
    this.answerType = AnswerType.single,
    int points = 10,
    List<_AnswerDraft>? answers,
  })  : key = UniqueKey(),
        promptController = TextEditingController(text: prompt),
        explanationController = TextEditingController(text: explanation),
        pointsController = TextEditingController(text: '$points'),
        answers = answers ?? [_AnswerDraft(), _AnswerDraft()];

  final Key key;
  final TextEditingController promptController;
  final TextEditingController explanationController;
  final TextEditingController pointsController;
  String? imageUrl;
  String answerType;
  List<_AnswerDraft> answers;

  int get points => int.tryParse(pointsController.text.trim()) ?? 0;

  bool get isValid =>
      promptController.text.trim().isNotEmpty &&
      answers.length >= _minAnswers &&
      answers.every((a) => a.textController.text.trim().isNotEmpty) &&
      answers.any((a) => a.correct);

  void dispose() {
    promptController.dispose();
    explanationController.dispose();
    pointsController.dispose();
    for (final answer in answers) {
      answer.dispose();
    }
  }
}

class _QuestFormDialog extends StatefulWidget {
  const _QuestFormDialog({required this.eventId, required this.existingJournals, this.editing});

  final String eventId;
  final List<AdminJournal> existingJournals;
  final AdminJournal? editing;

  @override
  State<_QuestFormDialog> createState() => _QuestFormDialogState();
}

class _QuestFormDialogState extends State<_QuestFormDialog> {
  final _random = Random.secure();
  late final _titleController = TextEditingController(text: widget.editing?.title ?? '');
  late final _blurbController = TextEditingController(text: widget.editing?.blurb ?? '');
  late final _pointsController = TextEditingController(text: '${widget.editing?.points ?? 10}');
  late String _type = widget.editing?.type ?? QuestType.journal;
  late String? _assetUrl = _initialAssetUrl();
  late String _manualCode = widget.editing?.manualCode ?? _generateUniqueCode();
  bool _submitting = false;
  bool _uploading = false;
  String? _error;

  // Quiz-only state.
  late final _timerMinutesController = TextEditingController(
    text: '${widget.editing?.timerSeconds != null ? (widget.editing!.timerSeconds! / 60).ceil() : 5}',
  );
  late String _difficulty = widget.editing?.difficulty ?? 'medium';
  late bool _timerEnabled = widget.editing?.timerSeconds != null;
  List<_QuestionDraft>? _questions;
  String? _uploadingQuestionKey;

  @override
  void initState() {
    super.initState();
    if (widget.editing?.type == QuestType.quiz) {
      _loadExistingQuestions();
    } else if (_type == QuestType.quiz) {
      _questions = [_QuestionDraft()];
    }
  }

  Future<void> _loadExistingQuestions() async {
    final questions =
        await context.read<JournalRepository>().watchQuestions(widget.eventId, widget.editing!.id).first;
    if (!mounted) return;
    setState(() {
      _questions = questions.isEmpty
          ? [_QuestionDraft()]
          : questions
              .map((q) => _QuestionDraft(
                    prompt: q.prompt,
                    imageUrl: q.imageUrl.isEmpty ? null : q.imageUrl,
                    explanation: q.explanation,
                    answerType: q.answerType,
                    points: q.points,
                    answers: q.options.map((o) => _AnswerDraft(text: o.text, correct: o.correct)).toList(),
                  ))
              .toList();
    });
  }

  String? _initialAssetUrl() {
    final raw = widget.editing?.type == QuestType.gestral ? widget.editing?.model3dUrl : widget.editing?.artUrl;
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  String _generateUniqueCode() {
    final taken = widget.existingJournals
        .where((j) => j.id != widget.editing?.id)
        .map((j) => normalizeManualCode(j.manualCode ?? ''))
        .toSet();
    late String code;
    do {
      code = generateManualCode(_random);
    } while (taken.contains(code));
    return code;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _blurbController.dispose();
    _pointsController.dispose();
    _timerMinutesController.dispose();
    for (final question in _questions ?? const <_QuestionDraft>[]) {
      question.dispose();
    }
    super.dispose();
  }

  bool get _formValid {
    final baseValid = _titleController.text.trim().isNotEmpty && _blurbController.text.trim().isNotEmpty;
    if (_type == QuestType.quiz) {
      return baseValid && (_questions?.isNotEmpty ?? false) && _questions!.every((q) => q.isValid);
    }
    return baseValid;
  }

  void _handleTypeChanged(String newType) {
    setState(() {
      _type = newType;
      if (newType == QuestType.quiz && _questions == null) {
        _questions = [_QuestionDraft()];
      }
    });
  }

  Future<void> _pickFromLibrary() async {
    final url = await showAssetPickerDialog(
      context,
      type: _type == QuestType.gestral ? AssetType.model3d : AssetType.image,
    );
    if (url != null) setState(() => _assetUrl = url);
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final assetType = _type == QuestType.gestral ? AssetType.model3d : AssetType.image;
      final result = await pickAndUploadAsset(assetType);
      if (result != null && mounted) {
        setState(() => _assetUrl = result.url);
        // Every quest upload also lands in the shared asset library, named
        // after the source file, so it's available to reuse on other quests.
        await context.read<AssetLibraryRepository>().addEntry(
              name: result.filename,
              url: result.url,
              type: assetType,
            );
      }
    } on CloudinaryNotConfiguredException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary isn\'t configured yet — see cloudinary_config.dart.')),
        );
      }
    } on AssetTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File is too large (max 10 MB).')));
      }
    } on AssetUploadTimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload timed out. Please try again.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _addQuestion() => setState(() => _questions!.add(_QuestionDraft()));

  void _removeQuestion(_QuestionDraft question) {
    if (_questions!.length <= 1) return;
    setState(() {
      _questions!.remove(question);
      question.dispose();
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final question = _questions!.removeAt(oldIndex);
      _questions!.insert(newIndex, question);
    });
  }

  void _addAnswer(_QuestionDraft question) {
    if (question.answers.length >= _maxAnswers) return;
    setState(() => question.answers.add(_AnswerDraft()));
  }

  void _removeAnswer(_QuestionDraft question, _AnswerDraft answer) {
    if (question.answers.length <= _minAnswers) return;
    setState(() {
      question.answers.remove(answer);
      answer.dispose();
    });
  }

  void _toggleCorrect(_QuestionDraft question, _AnswerDraft answer) {
    setState(() {
      if (question.answerType == AnswerType.single) {
        for (final a in question.answers) {
          a.correct = a == answer;
        }
      } else {
        answer.correct = !answer.correct;
      }
    });
  }

  void _setAnswerType(_QuestionDraft question, String type) {
    setState(() {
      question.answerType = type;
      // Switching to single-select could leave more than one option marked
      // correct — keep only the first.
      if (type == AnswerType.single) {
        var kept = false;
        for (final a in question.answers) {
          if (a.correct && !kept) {
            kept = true;
          } else {
            a.correct = false;
          }
        }
      }
    });
  }

  Future<void> _pickQuestionImage(_QuestionDraft question) async {
    final url = await showAssetPickerDialog(context, type: AssetType.image);
    if (url != null) setState(() => question.imageUrl = url);
  }

  Future<void> _uploadQuestionImage(_QuestionDraft question) async {
    setState(() => _uploadingQuestionKey = question.key.toString());
    try {
      final result = await pickAndUploadAsset(AssetType.image);
      if (result != null && mounted) {
        setState(() => question.imageUrl = result.url);
        await context.read<AssetLibraryRepository>().addEntry(
              name: result.filename,
              url: result.url,
              type: AssetType.image,
            );
      }
    } on CloudinaryNotConfiguredException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary isn\'t configured yet — see cloudinary_config.dart.')),
        );
      }
    } on AssetTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File is too large (max 10 MB).')));
      }
    } on AssetUploadTimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload timed out. Please try again.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _uploadingQuestionKey = null);
    }
  }

  int get _totalPoints => (_questions ?? const []).fold<int>(0, (total, q) => total + q.points);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repository = context.read<JournalRepository>();
    try {
      if (_type == QuestType.quiz) {
        final questions = _questions!
            .asMap()
            .entries
            .map((entry) => QuizQuestion(
                  id: '',
                  prompt: entry.value.promptController.text.trim(),
                  imageUrl: entry.value.imageUrl ?? '',
                  explanation: entry.value.explanationController.text.trim(),
                  answerType: entry.value.answerType,
                  points: entry.value.points,
                  order: entry.key,
                  options: entry.value.answers
                      .map((a) => QuizOption(
                            id: a.key.toString(),
                            text: a.textController.text.trim(),
                            correct: a.correct,
                          ))
                      .toList(),
                ))
            .toList();
        final timerSeconds = _timerEnabled ? (int.tryParse(_timerMinutesController.text.trim()) ?? 5) * 60 : null;

        if (widget.editing == null) {
          await repository.createQuiz(
            eventId: widget.eventId,
            title: _titleController.text.trim(),
            blurb: _blurbController.text.trim(),
            order: widget.existingJournals.length + 1,
            difficulty: _difficulty,
            timerSeconds: timerSeconds,
            manualCode: _manualCode,
            questions: questions,
          );
        } else {
          await repository.updateQuiz(
            eventId: widget.eventId,
            journalId: widget.editing!.id,
            title: _titleController.text.trim(),
            blurb: _blurbController.text.trim(),
            order: widget.editing!.order,
            difficulty: _difficulty,
            timerSeconds: timerSeconds,
            manualCode: _manualCode,
            questions: questions,
          );
        }
      } else {
        final url = _assetUrl ?? '';
        if (widget.editing == null) {
          await repository.createJournal(
            eventId: widget.eventId,
            title: _titleController.text.trim(),
            blurb: _blurbController.text.trim(),
            order: widget.existingJournals.length + 1,
            artUrl: _type == QuestType.gestral ? '' : url,
            type: _type,
            model3dUrl: _type == QuestType.gestral ? url : null,
            manualCode: _manualCode,
            points: int.tryParse(_pointsController.text.trim()) ?? 10,
          );
        } else {
          await repository.updateJournal(
            eventId: widget.eventId,
            journalId: widget.editing!.id,
            title: _titleController.text.trim(),
            blurb: _blurbController.text.trim(),
            order: widget.editing!.order,
            artUrl: _type == QuestType.gestral ? '' : url,
            type: _type,
            model3dUrl: _type == QuestType.gestral ? url : null,
            manualCode: _manualCode,
            points: int.tryParse(_pointsController.text.trim()) ?? widget.editing!.points,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _error = 'Could not save the quest. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQuiz = _type == QuestType.quiz;
    final canSubmit = _formValid && !_submitting && (!isQuiz || _questions != null);
    return Dialog(
      backgroundColor: AppColors.navyPanel2,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isQuiz ? 760 : 440,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.editing == null ? 'New quest' : 'Edit quest', style: AppTypography.display(fontSize: 20)),
                const SizedBox(height: AppSpacing.md20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: QuestType.journal, label: Text('Journal')),
                    ButtonSegment(value: QuestType.gestral, label: Text('Gestral')),
                    ButtonSegment(value: QuestType.quiz, label: Text('Quiz')),
                  ],
                  selected: {_type},
                  onSelectionChanged:
                      widget.editing == null ? (selection) => _handleTypeChanged(selection.first) : null,
                ),
                const SizedBox(height: AppSpacing.sm14),
                Flexible(
                  child: SingleChildScrollView(
                    child: isQuiz ? _buildQuizFields() : _buildQuestFields(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm12),
                  Text(_error!, style: AppTypography.body(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.md20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.xs8),
                    ElevatedButton(
                      onPressed: canSubmit ? _submit : null,
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isQuiz ? 'Save quiz' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualCodeRow() {
    return Row(
      children: [
        Text('Manual code: ', style: AppTypography.body(color: AppColors.creamDim)),
        Text(_manualCode, style: AppTypography.monospace.copyWith(color: AppColors.gold, fontSize: 15)),
        const Spacer(),
        if (widget.editing == null)
          TextButton(
            onPressed: () => setState(() => _manualCode = _generateUniqueCode()),
            child: const Text('Regenerate'),
          ),
      ],
    );
  }

  Widget _buildQuestFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          style: AppTypography.body(),
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        TextField(
          controller: _blurbController,
          style: AppTypography.body(),
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Blurb'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _pointsController,
            style: AppTypography.body(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm14),
        _buildAssetSection(),
        const SizedBox(height: AppSpacing.sm14),
        _buildManualCodeRow(),
      ],
    );
  }

  Widget _buildQuizFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          style: AppTypography.body(),
          decoration: const InputDecoration(labelText: 'Quiz name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        TextField(
          controller: _blurbController,
          style: AppTypography.body(),
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Blurb'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        Text('Difficulty', style: AppTypography.body(fontSize: 12, color: AppColors.creamDim)),
        const SizedBox(height: AppSpacing.xs4),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'easy', label: Text('Easy')),
            ButtonSegment(value: 'medium', label: Text('Medium')),
            ButtonSegment(value: 'hard', label: Text('Hard')),
          ],
          selected: {_difficulty},
          onSelectionChanged: (selection) => setState(() => _difficulty = selection.first),
        ),
        const SizedBox(height: AppSpacing.sm14),
        Row(
          children: [
            Switch(value: _timerEnabled, onChanged: (v) => setState(() => _timerEnabled = v)),
            const SizedBox(width: AppSpacing.xs8),
            Expanded(
              child: _timerEnabled
                  ? TextField(
                      controller: _timerMinutesController,
                      style: AppTypography.body(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Time limit (min)'),
                    )
                  : Text('No time limit', style: AppTypography.body(color: AppColors.creamDim)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm14),
        _buildManualCodeRow(),
        const SizedBox(height: AppSpacing.lg32),
        if (_questions == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Row(
            children: [
              Text('Questions', style: AppTypography.display(fontSize: 20)),
              const Spacer(),
              Text(
                'Total: $_totalPoints pts',
                style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm12),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: _reorderQuestions,
            children: [
              for (var i = 0; i < _questions!.length; i++)
                Padding(
                  key: _questions![i].key,
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm12),
                  child: _QuestionCard(
                    index: i,
                    question: _questions![i],
                    canRemove: _questions!.length > 1,
                    uploading: _uploadingQuestionKey == _questions![i].key.toString(),
                    onRemove: () => _removeQuestion(_questions![i]),
                    onPickImage: () => _pickQuestionImage(_questions![i]),
                    onUploadImage: () => _uploadQuestionImage(_questions![i]),
                    onClearImage: () => setState(() => _questions![i].imageUrl = null),
                    onAddAnswer: () => _addAnswer(_questions![i]),
                    onRemoveAnswer: (a) => _removeAnswer(_questions![i], a),
                    onToggleCorrect: (a) => _toggleCorrect(_questions![i], a),
                    onAnswerTypeChanged: (t) => _setAnswerType(_questions![i], t),
                    onChanged: () => setState(() {}),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm12),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cream,
              side: BorderSide(color: AppColors.cream.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssetSection() {
    final label = _type == QuestType.gestral ? '3D model' : 'Art image';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body(fontSize: 12, color: AppColors.creamDim)),
        const SizedBox(height: AppSpacing.xs4),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.creamDim.withValues(alpha: 0.3)),
            borderRadius: AppRadii.inputShape,
          ),
          child: Row(
            children: [
              if (_assetUrl != null) ...[
                _AssetPreview(url: _assetUrl!, isGestral: _type == QuestType.gestral),
                const SizedBox(width: AppSpacing.sm12),
                Expanded(
                  child: Text(
                    _assetUrl!,
                    style: AppTypography.body(fontSize: 12, color: AppColors.creamDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    'No $label attached yet.',
                    style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
                  ),
                ),
              if (_uploading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.perm_media_outlined),
                  tooltip: 'Pick from library',
                  onPressed: _pickFromLibrary,
                ),
                IconButton(
                  icon: const Icon(Icons.upload_outlined),
                  tooltip: 'Upload file',
                  onPressed: _upload,
                ),
                if (_assetUrl != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    onPressed: () => setState(() => _assetUrl = null),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs4),
        Text(
          _type == QuestType.gestral
              ? 'Recommended: a compact glTF/GLB model, ideally under 5 MB for fast loading in the app — well inside the 10 MB upload limit.'
              : 'Recommended: JPG/PNG around 1200×1200px, under 2 MB — plenty sharp for the in-app cards and well inside the 10 MB upload limit.',
          style: AppTypography.body(fontSize: 11, color: AppColors.creamDim),
        ),
      ],
    );
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({required this.url, required this.isGestral});

  final String url;
  final bool isGestral;

  @override
  Widget build(BuildContext context) {
    if (isGestral) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.inputShape),
        child: const Icon(Icons.view_in_ar, color: AppColors.teal),
      );
    }
    return ClipRRect(
      borderRadius: AppRadii.inputShape,
      child: ColoredBox(
        color: AppColors.navyPanel,
        child: Image.network(
          cloudinaryDeliveryUrl(url),
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 48,
            height: 48,
            color: AppColors.navyPanel,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.creamDim),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.canRemove,
    required this.uploading,
    required this.onRemove,
    required this.onPickImage,
    required this.onUploadImage,
    required this.onClearImage,
    required this.onAddAnswer,
    required this.onRemoveAnswer,
    required this.onToggleCorrect,
    required this.onAnswerTypeChanged,
    required this.onChanged,
  });

  final int index;
  final _QuestionDraft question;
  final bool canRemove;
  final bool uploading;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;
  final VoidCallback onUploadImage;
  final VoidCallback onClearImage;
  final VoidCallback onAddAnswer;
  final void Function(_AnswerDraft) onRemoveAnswer;
  final void Function(_AnswerDraft) onToggleCorrect;
  final void Function(String) onAnswerTypeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md20),
      decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_handle, color: AppColors.creamDim),
              const SizedBox(width: AppSpacing.xs8),
              Text('Question ${index + 1}', style: AppTypography.display(fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Remove question',
                onPressed: canRemove ? onRemove : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs8),
          _buildImageSection(context),
          const SizedBox(height: AppSpacing.sm14),
          TextField(
            controller: question.promptController,
            style: AppTypography.body(),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Prompt'),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.sm14),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: AnswerType.single, label: Text('Single-select')),
                    ButtonSegment(value: AnswerType.multiple, label: Text('Multi-select')),
                  ],
                  selected: {question.answerType},
                  onSelectionChanged: (selection) => onAnswerTypeChanged(selection.first),
                ),
              ),
              const SizedBox(width: AppSpacing.sm14),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: question.pointsController,
                  style: AppTypography.body(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm14),
          Text('Answers', style: AppTypography.body(fontSize: 12, color: AppColors.creamDim)),
          const SizedBox(height: AppSpacing.xs4),
          for (final answer in question.answers)
            Padding(
              key: answer.key,
              padding: const EdgeInsets.only(bottom: AppSpacing.xs8),
              child: Row(
                children: [
                  question.answerType == AnswerType.single
                      ? IconButton(
                          icon: Icon(
                            answer.correct ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: answer.correct ? AppColors.gold : AppColors.creamDim,
                          ),
                          tooltip: 'Mark correct',
                          onPressed: () => onToggleCorrect(answer),
                        )
                      : Checkbox(value: answer.correct, onChanged: (_) => onToggleCorrect(answer)),
                  Expanded(
                    child: TextField(
                      controller: answer.textController,
                      style: AppTypography.body(),
                      decoration: const InputDecoration(hintText: 'Answer text'),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove answer',
                    onPressed: question.answers.length > _minAnswers ? () => onRemoveAnswer(answer) : null,
                  ),
                ],
              ),
            ),
          if (question.answers.length < _maxAnswers)
            TextButton.icon(
              onPressed: onAddAnswer,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add answer'),
            ),
          const SizedBox(height: AppSpacing.xs8),
          TextField(
            controller: question.explanationController,
            style: AppTypography.body(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Explanation (shown after answering)',
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.creamDim.withValues(alpha: 0.3)),
        borderRadius: AppRadii.inputShape,
      ),
      child: Row(
        children: [
          if (question.imageUrl != null) ...[
            ClipRRect(
              borderRadius: AppRadii.inputShape,
              child: ColoredBox(
                color: AppColors.navyPanel2,
                child: Image.network(
                  cloudinaryDeliveryUrl(question.imageUrl!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.navyPanel2,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.creamDim),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm12),
            Expanded(
              child: Text(
                question.imageUrl!,
                style: AppTypography.body(fontSize: 12, color: AppColors.creamDim),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'No cover image (optional).',
                style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
              ),
            ),
          if (uploading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.perm_media_outlined),
              tooltip: 'Pick from library',
              onPressed: onPickImage,
            ),
            IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: 'Upload file',
              onPressed: onUploadImage,
            ),
            if (question.imageUrl != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remove',
                onPressed: onClearImage,
              ),
          ],
        ],
      ),
    );
  }
}
