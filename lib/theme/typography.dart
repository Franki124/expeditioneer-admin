import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Display/heading font = Playfair Display, body/UI = Nunito Sans.
class AppTypography {
  AppTypography._();

  static TextStyle display({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.cream,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.cream,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static const monospace = TextStyle(fontFamily: 'monospace');

  static TextTheme textTheme = TextTheme(
    displayLarge: display(fontSize: 44, fontWeight: FontWeight.w800),
    displayMedium: display(fontSize: 26, fontWeight: FontWeight.w700),
    headlineSmall: display(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: body(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: body(fontSize: 16),
    bodyMedium: body(fontSize: 15),
    bodySmall: body(fontSize: 13, color: AppColors.creamDim),
    labelLarge: body(fontSize: 15, fontWeight: FontWeight.w800),
  );
}
