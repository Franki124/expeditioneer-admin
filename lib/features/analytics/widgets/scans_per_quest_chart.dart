import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/admin_journal.dart';

/// Horizontal bars — a single hue (gold) encodes magnitude, sorted
/// descending so the busiest quests read first; labels stay in text tokens,
/// only the fill uses the series color.
class ScansPerQuestChart extends StatelessWidget {
  const ScansPerQuestChart({super.key, required this.journals});

  final List<AdminJournal> journals;

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) {
      return Center(child: Text('No quests to chart yet.', style: AppTypography.body(color: AppColors.creamDim)));
    }
    final maxScans = journals.map((j) => j.scanCount).fold(0, (a, b) => a > b ? a : b);
    final sorted = [...journals]..sort((a, b) => b.scanCount.compareTo(a.scanCount));
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm14),
      itemBuilder: (context, index) {
        final journal = sorted[index];
        final fraction = maxScans == 0 ? 0.0 : journal.scanCount / maxScans;
        return Tooltip(
          message: '${journal.title}: ${journal.scanCount} scans',
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  journal.title,
                  style: AppTypography.body(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(color: AppColors.navyPanel2, borderRadius: AppRadii.pillShape),
                        ),
                        Container(
                          height: 8,
                          width: constraints.maxWidth * fraction,
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: AppRadii.pillShape),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm12),
              SizedBox(
                width: 32,
                child: Text(
                  '${journal.scanCount}',
                  style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
