// ألوان حِرز الفاخرة / Hirz luxury palette
// خلفيتان متعاكستان + ذهبي: نص الوضع الليلي = خلفية الفاتح والعكس
// Two inverted backgrounds + gold: dark-mode text = light bg and vice versa

import 'package:flutter/material.dart';

abstract class AppColors {
  // خلفية الوضع الفاتح / Light mode background
  static const Color lightBackground = Color(0xFFFAF8F4);

  // خلفية الوضع الليلي / Dark mode background
  static const Color darkBackground = Color(0xFF36454F);

  // النص في الوضع الليلي = خلفية الفاتح (عكس متبادل)
  // Text on dark = the light background color
  static const Color textOnDark = lightBackground;

  // النص في الوضع الفاتح = خلفية الليلي (عكس متبادل)
  // Text on light = the dark background color
  static const Color textOnLight = darkBackground;

  // أسماء قديمة للتوافق / legacy aliases
  static const Color navyPrimary = darkBackground;
  static const Color navySecondary = Color(0xFF2C383F);
  static const Color offWhite = lightBackground;

  // الذهبي / Gold
  static const Color goldPrimary = Color(0xFFC9A227);
  static const Color goldBright = Color(0xFFD4AF37);

  // الأخضر الزيتي / Olive
  static const Color olivePrimary = Color(0xFF6B8E23);
  static const Color oliveDeep = Color(0xFF556B2F);

  // الأسود الدافئ / Warm black (on-gold text)
  static const Color warmBlack = Color(0xFF12100E);
}
