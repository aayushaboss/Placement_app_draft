import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

/// Single source of truth for the app's ThemeData.
/// Overrides Material's default TextTheme entirely so no fallback/system
/// font can ever appear — every text style here is explicitly Poppins.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.yellow,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: kFontFamily,
    );

    return base.copyWith(
      textTheme: _poppinsTextTheme(base.textTheme),
      primaryTextTheme: _poppinsTextTheme(base.primaryTextTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: AppTextStyles.h3,
      ),
    );
  }

  static TextTheme _poppinsTextTheme(TextTheme base) {
    return base.apply(fontFamily: kFontFamily).copyWith(
          displayLarge: AppTextStyles.display,
          displayMedium: AppTextStyles.h1,
          displaySmall: AppTextStyles.h2,
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          headlineSmall: AppTextStyles.h3,
          titleLarge: AppTextStyles.h3,
          titleMedium: AppTextStyles.bodyLg,
          titleSmall: AppTextStyles.label,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelLarge: AppTextStyles.label,
          labelMedium: AppTextStyles.label,
          labelSmall: AppTextStyles.caption,
        );
  }
}
