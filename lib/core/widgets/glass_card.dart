// بطاقة زجاجية فاخرة / Luxury glassmorphism card
// زجاج حقيقي: blur + حافة علوية مضيئة + ظل عميق
// Real glass: blur + luminous top edge + deep shadow

import 'dart:ui';

import 'package:flutter/material.dart';

/// بطاقة شفافة بتأثير الزجاج مع حدود ذهبية خفيفة
/// Frosted-glass card with a subtle gold border
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // RepaintBoundary يحبس طبقة الـ blur داخل حدود البطاقة —
    // بدونها يختفي البلور عند التمرير (إعادة تركيب الطبقات في الـ ListView)
    // RepaintBoundary pins the blur layer inside the card bounds —
    // without it the blur vanishes on scroll (layer recomposition in ListView)
    final Widget card = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // ملاحظة: طبقة blur واحدة هنا — ضمن ميزانية GPU
        // Note: single blur layer here — within GPU budget
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // زجاج داكن/فاتح حسب الوضع / dark/light glass per mode
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD4AF37)
                    .withValues(alpha: isDark ? 0.28 : 0.45),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: isDark ? 0.10 : 0.35),
                  Colors.white.withValues(alpha: isDark ? 0.03 : 0.15),
                ],
              ),
              boxShadow: <BoxShadow>[
                // ظل عميق للفصل عن الخلفية / deep shadow for separation
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                // وهج داخلي علوي — الضوء يلامس المادة
                // inner top glow — light catching the material
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.5),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
    );
  }
}