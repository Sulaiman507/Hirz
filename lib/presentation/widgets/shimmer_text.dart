// نص متلألئ — شعاع ضوئي يمسح الحروف من اليسار إلى اليمين
// Shimmer text — a light beam sweeps across letters left-to-right
// خفيف الأداء: ShaderMask + AnimationController واحد فقط
// Lightweight: single AnimationController + ShaderMask, no per-frame layout

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// نص بلمعان ماسح / Sweeping-shimmer text
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  // مدة المسحة الواحدة / duration of one sweep
  final Duration period;
  final bool enabled;
  // لون النص الأساسي (بين المسحات) / resting glyph color between sweeps
  final Color? baseColor;
  // لون الشعاع الماسح / the sweeping beam color
  final Color? beamColor;

  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.period = const Duration(milliseconds: 2600),
    this.enabled = true,
    this.baseColor,
    this.beamColor,
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
    final TextStyle effective =
        (widget.style ??
            Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)) ??
        const TextStyle(fontSize: 16);

    final Color base =
        widget.baseColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);
    final Color beam = widget.beamColor ?? AppColors.goldBright;

    if (!widget.enabled) {
      return Text(
        widget.text,
        style: effective.copyWith(color: base),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // النص بلونه الأساسي + شعاع يمسحه عبر ShaderMask
    // base-colored text + a beam swept across via ShaderMask
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // الشعاع يدخل من يسار النص ويخرج من يمينه (-0.6 → 1.6)
        // beam enters from the left edge and exits right (-0.6 → 1.6)
        final double x = -0.6 + _ctrl.value * 2.2;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final List<double> stops = <double>[
              0.0,
              (x - 0.22).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.22).clamp(0.0, 1.0),
              1.0,
            ];
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[base, base, beam, base, base],
              stops: stops,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: effective.copyWith(color: base),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
