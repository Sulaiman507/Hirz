// شارة صغيرة ذهبية فخمة / Luxury muted-gold badge
// نصها متلألئ (شعاع ضوئي يمسح الحروف) فوق خلفية بيج فاتح هادئة
// Shimmering label over a calm light-beige backdrop, top-left light

import 'package:flutter/material.dart';

import 'shimmer_text.dart';

/// شارة حالة الصلاة (الحالية/القادمة) / Prayer status badge
class PrayerBadge extends StatelessWidget {
  final String label;
  // إضاءة أقوى للحالية / brighter for "current"
  final bool bright;

  const PrayerBadge({
    super.key,
    required this.label,
    this.bright = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        // خلفية بيج فاتحة هادئة / calm light-beige backdrop
        color: isDark
            ? const Color(0xFFEFE7D6).withValues(alpha: 0.92)
            : const Color(0xFFEFE7D6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: bright ? 0.85 : 0.55),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          // وهج خفيف يطلع من أعلى اليسار / faint glow toward top-left
          BoxShadow(
            color: const Color(0xFFD4AF37)
                .withValues(alpha: bright ? 0.45 : 0.30),
            blurRadius: bright ? 10 : 6,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ShimmerText(
        label,
        enabled: bright, // الحالية فقط تتلألأ / only "current" shimmers
        baseColor: const Color(0xFF241C05),
        beamColor: const Color(0xFF8A6A14), // شعاع ذهبي غامق واضح / deep gold
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
