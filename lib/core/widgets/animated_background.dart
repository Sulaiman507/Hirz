// خلفية ليلية متحركة — Canvas / Animated night background via CustomPaint
// تدرج كحلي يتنفس + نجوم ذهبية خافتة + نبض ضوء ناعم
// Breathing navy gradient + faint gold stars + soft glow pulse
// ميزانية GPU: ≤3 طبقات blur، الجزيئات تُنشأ مرة واحدة فقط
// GPU budget: ≤3 blur layers, particles generated once

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// خلفية متحركة للشاشة الرئيسية / Animated app background
class AnimatedNightBackground extends StatefulWidget {
  final bool isDark;

  const AnimatedNightBackground({super.key, required this.isDark});

  @override
  State<AnimatedNightBackground> createState() =>
      _AnimatedNightBackgroundState();
}

class _AnimatedNightBackgroundState extends State<AnimatedNightBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift; // انجراف التدرج / gradient drift
  late final AnimationController _twinkle; // وميض النجوم / star twinkle
  late final AnimationController _glow; // نبض الضوء / glow pulse
  late List<_Star> _stars;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // احترام إعداد تقليل الحركة / Respect reduced-motion accessibility
    _reduceMotion = SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.reduceMotion;

    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (!_reduceMotion) {
      _drift.repeat();
      _twinkle.repeat();
      _glow.repeat(reverse: true);
    } else {
      // إطار ثابت كامل بدون حركة / static but complete frame
      _drift.value = 0.2;
      _twinkle.value = 0.5;
      _glow.value = 0.5;
    }

    // النجوم تُولَّد مرة واحدة / stars generated once
    final Random rng = Random(42);
    _stars = List<_Star>.generate(48, (int i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.75, // النجوم في الأعلى فقط / upper area only
        radius: 0.6 + rng.nextDouble() * 1.4,
        phase: rng.nextDouble(),
        speed: 0.5 + rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    _twinkle.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_drift, _twinkle, _glow]),
      builder: (BuildContext context, Widget? _) {
        return CustomPaint(
          painter: _NightPainter(
            drift: _drift.value,
            twinkle: _twinkle.value,
            glow: _glow.value,
            stars: _stars,
            isDark: widget.isDark,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// نجمة واحدة / A single star particle
class _Star {
  final double x;
  final double y;
  final double radius;
  final double phase;
  final double speed;

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.speed,
  });
}

/// الرسّام — يرسم التدرج والنجوم والتوهج / Painter: gradient + stars + glow
class _NightPainter extends CustomPainter {
  final double drift;
  final double twinkle;
  final double glow;
  final List<_Star> stars;
  final bool isDark;

  _NightPainter({
    required this.drift,
    required this.twinkle,
    required this.glow,
    required this.stars,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── التدرج الكحلي المتنفس / Breathing navy gradient ──
    // نقطة المركز تنجرف ببطء مع drift / center drifts slowly
    final Offset center = Offset(
      size.width * (0.5 + 0.15 * sin(drift * 2 * pi)),
      size.height * (0.25 + 0.1 * cos(drift * 2 * pi)),
    );

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
        center: Alignment(
          (center.dx / size.width) * 2 - 1,
          (center.dy / size.height) * 2 - 1,
        ),
        radius: 1.4,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // ── توهج ذهبي نابض أعلى الشاشة / Pulsing gold glow at top ──
    final double glowAlpha = (isDark ? 0.10 : 0.18) * (0.6 + 0.4 * glow);
    final Rect glowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, -size.height * 0.15),
      width: size.width * 1.6,
      height: size.height * 0.7,
    );
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFD4AF37).withOpacity(glowAlpha),
          const Color(0xFFD4AF37).withOpacity(0),
        ],
      ).createShader(glowRect);
    canvas.drawOval(glowRect, glowPaint);

    // ── النجوم الذهبية الوامضة / Twinkling gold stars ──
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (final _Star star in stars) {
      // كل نجمة تومض بطورها الخاص / each star twinkles on its own phase
      final double a =
          0.25 + 0.55 * (0.5 + 0.5 * sin((twinkle + star.phase) * 2 * pi));
      starPaint.color =
          const Color(0xFFE8C96A).withOpacity(isDark ? a : a * 0.45);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) {
    // يعيد الرسم فقط عند تغير القيم الفعلية / repaint only when values change
    return oldDelegate.drift != drift ||
        oldDelegate.twinkle != twinkle ||
        oldDelegate.glow != glow ||
        oldDelegate.isDark != isDark;
  }
}