// ثيم حِرز — Material 3 / Hirz theme: Material 3 light + dark
// الوضع الداكن: كحلي عميق مع طبقات عمق (وليس أسود مسطح)
// Dark: rich navy depth layers (not flat black)

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
      surface: AppColors.navyPrimary, // كحلي عميق بدل الأسود / navy not black
      onSurface: AppColors.offWhite,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final bool isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // خط Amiri الفاخر للعناوين / Luxury Amiri font for display text
      fontFamily: 'Amiri',
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? Colors.transparent : scheme.surface.withValues(alpha: 0.85),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: isDark ? 0.5 : 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.goldBright.withValues(alpha: isDark ? 0.25 : 0.35),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.goldBright.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.goldBright,
            width: 2,
          ),
        ),
      ),
      // الأزرار: تعبئة ذهبية واحدة للإجراء الأساسي
      // Buttons: single gold fill for the primary action
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldBright,
          foregroundColor: AppColors.warmBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      // شرائح الأزرار بلمسة ذهبية / Segmented buttons with gold touch
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(
              color: AppColors.goldBright.withValues(alpha: 0.5),
            ),
          ),
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