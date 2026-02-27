import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData build() {
    return ThemeData(
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.appBackground,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF10707E),
      ),
    );
  }
}
