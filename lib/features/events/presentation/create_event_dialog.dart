import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../data/event_repository.dart';

/// Two-step create-event flow (form -> review/confirm), matching the design.
Future<void> showCreateEventDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<AdminAuthCubit>(),
      child: RepositoryProvider.value(
        value: context.read<EventRepository>(),
        child: const _CreateEventDialog(),
      ),
    ),
  );
}

class _CreateEventDialog extends StatefulWidget {
  const _CreateEventDialog();

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  int _step = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _nameController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _startAt != null &&
      _endAt != null &&
      _endAt!.isAfter(_startAt!);

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = (isStart ? _startAt : _endAt) ?? _startAt ?? DateTime.now();
    final earliestSelectable = isStart
        ? DateTime.now().subtract(const Duration(days: 1))
        : (_startAt ?? DateTime.now().subtract(const Duration(days: 1)));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(earliestSelectable) ? earliestSelectable : initial,
      firstDate: earliestSelectable,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (isStart && _endAt != null && !combined.isBefore(_endAt!)) {
      _showDateError('Start must be before the end time.');
      return;
    }
    if (!isStart && _startAt != null && !combined.isAfter(_startAt!)) {
      _showDateError('End must be after the start time.');
      return;
    }

    setState(() {
      if (isStart) {
        _startAt = combined;
      } else {
        _endAt = combined;
      }
    });
  }

  void _showDateError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirm() async {
    final createdBy = context.read<AdminAuthCubit>().state.profile?.uid;
    if (createdBy == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<EventRepository>().createEvent(
            name: _nameController.text.trim(),
            location: _locationController.text.trim(),
            startAt: _startAt!,
            endAt: _endAt!,
            createdBy: createdBy,
            maxParticipants: int.tryParse(_maxParticipantsController.text.trim()),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _error = 'Could not create the event. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.navyPanel2,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md24),
          child: _step == 0 ? _buildForm(context) : _buildReview(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y  h:mm a');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New event', style: AppTypography.display(fontSize: 20)),
        const SizedBox(height: AppSpacing.md20),
        TextField(
          controller: _nameController,
          style: AppTypography.body(),
          decoration: const InputDecoration(labelText: 'Event name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        TextField(
          controller: _locationController,
          style: AppTypography.body(),
          decoration: const InputDecoration(labelText: 'Location'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm14),
        TextField(
          controller: _maxParticipantsController,
          style: AppTypography.body(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Max participants (optional)'),
        ),
        const SizedBox(height: AppSpacing.sm14),
        _DateTimeRow(
          label: 'Starts',
          value: _startAt == null ? 'Select date & time' : dateFormat.format(_startAt!),
          onTap: () => _pickDateTime(isStart: true),
        ),
        const SizedBox(height: AppSpacing.xs8),
        _DateTimeRow(
          label: 'Ends',
          value: _endAt == null ? 'Select date & time' : dateFormat.format(_endAt!),
          onTap: () => _pickDateTime(isStart: false),
        ),
        const SizedBox(height: AppSpacing.md20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.xs8),
            ElevatedButton(
              onPressed: _formValid ? () => setState(() => _step = 1) : null,
              child: const Text('Review'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y  h:mm a');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & confirm', style: AppTypography.display(fontSize: 20)),
        const SizedBox(height: AppSpacing.md20),
        _ReviewRow(label: 'Name', value: _nameController.text.trim()),
        _ReviewRow(label: 'Location', value: _locationController.text.trim()),
        _ReviewRow(label: 'Starts', value: dateFormat.format(_startAt!)),
        _ReviewRow(label: 'Ends', value: dateFormat.format(_endAt!)),
        _ReviewRow(
          label: 'Max participants',
          value: _maxParticipantsController.text.trim().isEmpty
              ? 'Unlimited'
              : _maxParticipantsController.text.trim(),
        ),
        const SizedBox(height: AppSpacing.sm12),
        Text(
          'A unique join code will be generated automatically once created.',
          style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
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
              onPressed: _submitting ? null : () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
            const SizedBox(width: AppSpacing.xs8),
            ElevatedButton(
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create event'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.inputShape,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.sm14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.creamDim.withValues(alpha: 0.3)),
          borderRadius: AppRadii.inputShape,
        ),
        child: Row(
          children: [
            Text('$label: ', style: AppTypography.body(fontWeight: FontWeight.w700)),
            Expanded(child: Text(value, style: AppTypography.body())),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.creamDim),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTypography.body(color: AppColors.creamDim)),
          ),
          Expanded(child: Text(value, style: AppTypography.body(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
