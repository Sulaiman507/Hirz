// حلقة العدّاد الذهبية — بدون أنيميشن مستمر / Gold countdown ring — no continuous animation
// TweenAnimationBuilder كان يعيد الأنيميشن عند كل rebuild (كل ثانية) = تكلفة إطارية
// TweenAnimationBuilder re-animated on every second-tick = per-frame cost
// الآن: رسم مباشر، يتحدث فقط عندما تتغير القيمة فعلياً
// Now: direct paint, updates only when the value actually changes

import 'dart:math';

import 'package:flutter/material.dart';

/// حلقة تقدم دائرية مع محتوى في الوسط / Circular progress ring with center child
class CircularCountdownRing extends StatelessWidget {
  /// نسبة التقدم 0..1 (من صلاة إلى الصلاة التالية)
  /// Progress 0..1 (from previous prayer to next)
  final double progress;
  final Widget child;
  final double size;

  const CircularCountdownRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0.0, 1.0), isDark: isDark),
        child: Center(child: child),
      ),
    );
  }
}

/// رسّام الحلقة / Ring painter
class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _RingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 10;

    // مسار الخلفية — حلقة خافتة / Track — faint full circle
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    canvas.drawCircle(center, radius, trackPaint);

    // قوس التقدم — تدرج ذهبي / Progress arc — gold gradient
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 2 * pi - pi / 2,
        colors: const <Color>[
          Color(0xFFC9A227), // ذهبي هادئ / muted gold
          Color(0xFFD4AF37), // ذهبي ساطع / bright gold
          Color(0xFFE8C96A), // ذهبي فاتح / light gold
        ],
        transform: const GradientRotation(-pi / 2),
      ).createShader(arcRect);
    canvas.drawArc(
      arcRect,
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // نقطة نهاية مضيئة / Glowing end cap dot
    final double endAngle = -pi / 2 + 2 * pi * progress;
    final Offset endOffset = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );
    // طبقة blur واحدة صغيرة فقط للنقطة / single small blur layer for the dot
    final Paint dotGlow = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(endOffset, 6, dotGlow);
    canvas.drawCircle(
      endOffset,
      4,
      Paint()..color = const Color(0xFFF0D98C),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}