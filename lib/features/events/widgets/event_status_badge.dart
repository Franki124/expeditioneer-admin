import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.status});

  final String status; // draft | live | closed | archived

  Color get _color => switch (status) {
        'live' => AppColors.teal,
        'closed' => AppColors.error,
        'archived' => AppColors.creamDim,
        _ => AppColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: AppRadii.pillShape,
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w800, color: _color),
      ),
    );
  }
}
