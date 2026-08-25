// ثيم حِرز — Material 3 / Hirz theme: Material 3 light + dark
// الوضع الداكن: كحلي عميق مع طبقات عمق (وليس أسود مسطح)
// Dark: rich navy depth layers (not flat black)

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract class AppTheme {
  /// الوضع الفاتح / Light theme
  static ThemeData light({String fontFamily = 'Amiri', double fontThickness = 1.0}) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.goldPrimary,
      brightness: Brightness.light,
      primary: AppColors.navySecondary,
      onPrimary: AppColors.offWhite,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.warmBlack,
      tertiary: AppColors.olivePrimary,
      surface: AppColors.lightBackground,
      // النص = لون خلفية الوضع الليلي (عكس متبادل)
      // text = dark-mode background color (inverted pair)
      onSurface: AppColors.textOnLight,
    );
    return _base(scheme, fontFamily: fontFamily, fontThickness: fontThickness);
  }

  /// الوضع الداكن / Dark theme
  static ThemeData dark({String fontFamily = 'Amiri', double fontThickness = 1.0}) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkBackground,
      brightness: Brightness.dark,
      primary: AppColors.goldBright,
      onPrimary: AppColors.warmBlack,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.warmBlack,
      tertiary: AppColors.olivePrimary,
      surface: AppColors.darkBackground,
      // النص = لون خلفية الوضع الفاتح (عكس متبادل)
      // text = light-mode background color (inverted pair)
      onSurface: AppColors.textOnDark,
    );
    return _base(scheme, fontFamily: fontFamily, fontThickness: fontThickness);
  }

  static ThemeData _base(ColorScheme scheme, {String fontFamily = 'Amiri', double fontThickness = 1.0}) {
    final bool isDark = scheme.brightness == Brightness.dark;
    // تطبيق مضاعف السماكة على كل الأوزان — بدون FontVariation (متوافق مع CI)
    // Apply thickness multiplier to every weight — no FontVariation (CI-safe)
    FontWeight thickened(FontWeight base) => _scaleWeight(base, fontThickness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? Colors.transparent : scheme.surface.withValues(alpha: 0.85),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: thickened(FontWeight.w900),
          letterSpacing: isDark ? 0.5 : 0,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontWeight: thickened(FontWeight.w900), fontSize: 32, fontFamily: fontFamily),
        headlineMedium: TextStyle(fontWeight: thickened(FontWeight.w900), fontSize: 28, fontFamily: fontFamily),
        headlineSmall: TextStyle(fontWeight: thickened(FontWeight.w900), fontSize: 24, fontFamily: fontFamily),
        titleLarge: TextStyle(fontWeight: thickened(FontWeight.w900), fontSize: 22, fontFamily: fontFamily),
        titleMedium: TextStyle(fontWeight: thickened(FontWeight.w700), fontSize: 18, fontFamily: fontFamily),
        titleSmall: TextStyle(fontWeight: thickened(FontWeight.w700), fontSize: 16, fontFamily: fontFamily),
        bodyLarge: TextStyle(fontWeight: thickened(FontWeight.w600), fontSize: 16, fontFamily: fontFamily),
        bodyMedium: TextStyle(fontWeight: thickened(FontWeight.w600), fontSize: 14, fontFamily: fontFamily),
        bodySmall: TextStyle(fontWeight: thickened(FontWeight.w600), fontSize: 12, fontFamily: fontFamily),
        labelLarge: TextStyle(fontWeight: thickened(FontWeight.w700), fontSize: 14, fontFamily: fontFamily),
        labelMedium: TextStyle(fontWeight: thickened(FontWeight.w700), fontSize: 12, fontFamily: fontFamily),
        labelSmall: TextStyle(fontWeight: thickened(FontWeight.w700), fontSize: 11, fontFamily: fontFamily),
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

  /// يضرب الوزن القاعدي بمضاعف السماكة ويقيّده بين w100 و w900
  /// Scales a base font weight by the thickness multiplier, clamped to w100–w900
  static FontWeight _scaleWeight(FontWeight base, double thickness) {
    final int step = ((base.value * thickness) / 100).round();
    if (step < 1) return FontWeight.w100;
    if (step > 9) return FontWeight.w900;
    return FontWeight.values[step - 1];
  }
}