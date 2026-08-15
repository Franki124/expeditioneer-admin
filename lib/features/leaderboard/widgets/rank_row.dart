import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/admin_participant.dart';

class RankRow extends StatelessWidget {
  const RankRow({super.key, required this.rank, required this.participant});

  final int rank;
  final AdminParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs10),
      decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppColors.gold : AppColors.navyPanel2,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: AppTypography.body(
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? AppColors.navyDeep : AppColors.creamDim,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm12),
          Expanded(
            child: Text(participant.displayName, style: AppTypography.body(fontWeight: FontWeight.w700)),
          ),
          Text(
            '${participant.totalPoints} pts',
            style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
