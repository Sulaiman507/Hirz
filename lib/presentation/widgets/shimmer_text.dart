// نص متلألئ — شعاع ضوئي يمسح الحروف من اليسار إلى اليمين
// Shimmer text — a light beam sweeps across letters left-to-right
// خفيف الأداء: ShaderMask + AnimationController واحد فقط
// Lightweight: single AnimationController + ShaderMask, no per-frame layout

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// نص بلمعان ماسح / Sweeping-shimmer text
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  // مدة المسحة الواحدة / duration of one sweep
  final Duration period;
  final bool enabled;

  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.period = const Duration(milliseconds: 2600),
    this.enabled = true,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base = (widget.style ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                )) ??
        const TextStyle(fontSize: 16);

    if (!widget.enabled) return Text(widget.text, style: base);

    // النص الأساسي بلون هادئ + طبقة شعاع فوقه عبر ShaderMask
    // calm base text + a sweeping beam layered via ShaderMask
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final double t = _ctrl.value;
        // الشعاع يدخل من يسار النص ويخرج من يمينه (-0.6 → 1.6)
        // beam enters from the left edge and exits right (-0.6 → 1.6)
        final double x = -0.6 + t * 2.2;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double w = bounds.width;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const <Color>[
                Color(0xFFFFFFFF), // أساس / base
                Color(0xFFFFF3D6), // مقدمة الشعاع / beam lead
                Color(0xFFD4AF37), // قلب ذهبي لامع / bright gold core
                Color(0xFFFFF3D6), // ذيل الشعاع / beam tail
                Color(0xFFFFFFFF), // أساس / base
              ],
              stops: <double>[
                0.0,
                (x - 0.18).clamp(0.0, 1.0),
                x.clamp(0.0, 1.0),
                (x + 0.18).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: base,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
