// خلفية ليلية فاخرة — ثابتة للأداء / Luxury night background — static for performance
// تدرج كحلي عميق + نجوم ذهبية — تُرسم مرة واحدة فقط (صفر تكلفة إطارية)
// Deep navy gradient + gold stars — painted ONCE (zero per-frame cost)
// السبب: BackdropFilter فوق خلفية متحركة = إعادة بلور مستمرة = لاج شديد
// Why: BackdropFilter over an animated background = constant re-blur = heavy jank

import 'dart:math';

import 'package:flutter/material.dart';

/// خلفية ليلية ثابتة تُرسم مرة واحدة / Static night background, painted once
class AnimatedNightBackground extends StatelessWidget {
  final bool isDark;

  const AnimatedNightBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ClipRect + SizedBox.expand يثبتان حجم الكانفاس مهما تحرك المحتوى
    // ClipRect + expand pin the canvas size regardless of scroll
    return ClipRect(
      child: CustomPaint(
        painter: _NightPainter(isDark: isDark),
        size: Size.infinite,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// الرسّام — يرسم التدرج والنجوم والتوهج / Painter: gradient + stars + glow
class _NightPainter extends CustomPainter {
  final bool isDark;

  _NightPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // ── التدرج الكحلي العميق / Deep navy gradient ──
    final List<Color> colors = isDark
        ? <Color>[
            const Color(0xFF0A1128), // كحلي عميق / deep navy
            const Color(0xFF0F1B33), // كحلي ثانوي / secondary navy
            const Color(0xFF12100E), // أسود دافئ / warm black
          ]
        : <Color>[
            const Color(0xFFF7F4EE), // عاجي / off-white
            const Color(0xFFEDE6D6), // عاجي دافئ / warm ivory
            const Color(0xFFE2D9C4), // رملي فاتح / light sand
          ];

    final Paint gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.6),
        radius: 1.4,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // ── توهج ذهبي ناعم أعلى الشاشة / Soft gold glow at top ──
    final Rect glowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, -size.height * 0.15),
      width: size.width * 1.6,
      height: size.height * 0.7,
    );
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFD4AF37).withOpacity(isDark ? 0.10 : 0.18),
          const Color(0xFFD4AF37).withOpacity(0),
        ],
      ).createShader(glowRect);
    canvas.drawOval(glowRect, glowPaint);

    // ── النجوم الذهبية موزعة على الشاشة / Gold stars across the screen ──
    // بذرة ثابتة = نفس التوزيع الجميل كل مرة / fixed seed = same nice layout
    final Random rng = Random(42);
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 28; i++) {
      final double x = rng.nextDouble();
      final double y = rng.nextDouble() * 0.75;
      final double radius = 0.6 + rng.nextDouble() * 1.4;
      final double alpha = 0.25 + rng.nextDouble() * 0.55;
      starPaint.color =
          const Color(0xFFE8C96A).withOpacity(isDark ? alpha : alpha * 0.45);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}