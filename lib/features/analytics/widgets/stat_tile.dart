import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(AppSpacing.md20),
      decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.display(fontSize: 28, color: AppColors.gold)),
          const SizedBox(height: AppSpacing.xs4),
          Text(label, style: AppTypography.body(fontSize: 13, color: AppColors.creamDim)),
        ],
      ),
    );
  }
}
