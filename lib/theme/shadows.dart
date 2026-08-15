import 'package:flutter/material.dart';

import 'colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static Color scrimLight = AppColors.navyDeep.withValues(alpha: 0.7);
  static Color scrimHeavy = AppColors.navyDeep.withValues(alpha: 0.92);
}
