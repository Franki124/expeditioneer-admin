import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.navy,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.navy,
      primary: AppColors.gold,
      secondary: AppColors.teal,
      error: AppColors.error,
      onPrimary: AppColors.navyDeep,
      onSurface: AppColors.cream,
    ),
    textTheme: AppTypography.textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDeep,
        textStyle: AppTypography.body(
          fontWeight: FontWeight.w800,
          color: AppColors.navyDeep,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
