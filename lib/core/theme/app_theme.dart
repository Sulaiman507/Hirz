// ثيم حِرز — Material 3 / Hirz theme: Material 3 light + dark

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract class AppTheme {
  /// الوضع الفاتح / Light theme
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navySecondary,
      brightness: Brightness.light,
      primary: AppColors.navySecondary,
      onPrimary: AppColors.offWhite,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.warmBlack,
      tertiary: AppColors.olivePrimary,
      surface: AppColors.offWhite,
      onSurface: AppColors.navyPrimary,
    );
    return _base(scheme);
  }

  /// الوضع الداكن / Dark theme
  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navyPrimary,
      brightness: Brightness.dark,
      primary: AppColors.goldBright,
      onPrimary: AppColors.warmBlack,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.warmBlack,
      tertiary: AppColors.olivePrimary,
      surface: AppColors.warmBlack,
      onSurface: AppColors.offWhite,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // انتقالات سلسة بين الشاشات / Smooth page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}