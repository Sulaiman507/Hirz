// خلفية الوضع الليلي — صورة سماء ثابتة / Dark mode background — static sky image
// حل نهائي لمشكلة "ترسب النجوم": صورة مدمجة فيها نجوم حقيقية + طبقة تظليل خفيفة
// Final fix for star-settling: bundled real-sky image, no painted stars at all
// صفر تكلفة إطارية: الصورة تُرسم مرة واحدة كخلفية Scaffold
// Zero per-frame cost: drawn once as the scaffold backdrop

import 'package:flutter/material.dart';

/// خلفية السماء الليلية الثابتة / Static night sky background
class AnimatedNightBackground extends StatelessWidget {
  final bool isDark;

  const AnimatedNightBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      // الوضع الفاتح: تدرج عاجي هادئ / Light mode: calm ivory gradient
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF7F4EE),
              Color(0xFFEDE6D6),
              Color(0xFFE2D9C4),
            ],
          ),
        ),
      );
    }

    // الوضع الليلي: صورة السماء + طبقة كحلية لتوحيد اللون مع الثيم
    // Dark: sky image + navy tint layer to blend with theme
    return Image.asset(
      'assets/images/night_sky.jpg',
      fit: BoxFit.cover,
      // تغطية الشاشة كاملة / fill the whole screen
      width: double.infinity,
      height: double.infinity,
      // فك ترميز بدقة معقولة — يمنع GPU من التعامل مع bitmap أكبر من الشاشة
      // Decode at sane resolution — avoids oversized GPU bitmap
      cacheWidth: 1080,
      // طبقة تظليل فوق الصورة لعمق أكثر ووضوح النصوص
      // dark overlay for depth and text legibility
      color: const Color(0xFF0A1128).withValues(alpha: 0.45),
      colorBlendMode: BlendMode.darken,
    );
  }
}