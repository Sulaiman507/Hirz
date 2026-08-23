// شارة صغيرة ذهبية فخمة / Luxury muted-gold badge
// تدرج معدني يطلع نور من أعلى اليسار + حواف ناعمة
// Metallic gradient with a top-left light source + soft edges

import 'package:flutter/material.dart';

/// شارة حالة الصلاة (القادمة/الحالية) / Prayer status badge
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // ذهبي مطفي بتدرج من نور أعلى اليسار إلى ظل أسفل اليمين
        // muted gold, light sweeping from top-left to bottom-right
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFE8C96A), // نقطة الضوء / highlight point
            Color(0xFFB8912F), // الذهبي المطفي الأساسي / base muted gold
            Color(0xFF96762A), // ظل خافت / soft shadow edge
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          // وهج خفيف يقلد انبعاث الضوء من الزاوية / faint glow from the corner
          BoxShadow(
            color: const Color(0xFFD4AF37)
                .withValues(alpha: bright ? 0.45 : 0.30),
            blurRadius: bright ? 10 : 6,
            offset: const Offset(-2, -2), // نحو أعلى اليسار / toward top-left
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              // نص داكن فوق الذهب للتباين / dark text on gold for contrast
              color: const Color(0xFF241C05),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
