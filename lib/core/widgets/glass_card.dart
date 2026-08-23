// بطاقة زجاجية فاخرة — نسخة عالية الأداء / Luxury glass card — high-performance
// بدون BackdropFilter: الـ blur الحقيقي كان يعاد حسابه لكل بطاقة في كل إطار
// أثناء التمرير = تقطيع شديد. البديل: تعتيم نصف شفاف + حدود ذهبية — نفس
// الإحساس البصري فوق صورة السماء الداكنة، بصفر تكلفة GPU إضافية.
//
// No BackdropFilter: real blur was recomputed per-card per-frame while
// scrolling = severe jank. Replacement: semi-opaque tint + gold border —
// same visual feel over the dark sky image, zero extra GPU cost.

import 'package:flutter/material.dart';

/// بطاقة شفافة بتأثير الزجاج مع حدود ذهبية خفيفة
/// Frosted-glass card with a subtle gold border
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  // لون خلفية بديل (مثلاً بيج للحالية) — null = الزجاج الافتراضي
  // optional backdrop override (e.g. beige for current) — null = default glass
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // RepaintBoundary يبقي رسم البطاقة معزولاً — لا يعاد رسمها عند تحرك الجيران
    // RepaintBoundary keeps the card's paint isolated from scrolling neighbors
    final Widget card = RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          // زجاج مائل — أو لون بديل إن قُدّم / tinted glass or explicit color
          color: backgroundColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.65)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37)
                .withValues(alpha: isDark ? 0.35 : 0.45),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
              Colors.white.withValues(alpha: isDark ? 0.03 : 0.10),
            ],
          ),
          boxShadow: <BoxShadow>[
            // ظل معتدل — 24px كان مكلفاً ×8 بطاقات أثناء التمرير
            // moderate shadow — 24px was costly across 8 cards while scrolling
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            // وهج داخلي علوي — الضوء يلامس المادة
            // inner top glow — light catching the material
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: child,
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
