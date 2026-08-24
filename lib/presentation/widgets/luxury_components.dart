// مكوّنات فاخرة مشتركة / Shared luxury components
// تدرجات ذهبية-كحلية راقية للإعدادات والبحث
// Refined gold-on-slate gradients for settings and search UI

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// عنوان قسم بشريط ذهبي جانبي / Section title with a gold side bar
class LuxurySectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const LuxurySectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: <Widget>[
          // شريط ذهبي متدرج عمودي صغير / small vertical gold gradient bar
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFE8C96A),
                  Color(0xFFB8912F),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.goldBright.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: AppColors.goldBright),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// حاوية قسم فاخرة — زجاج بحدود ذهبية خافتة وتدرج علوي مضيء
/// Luxury section container — glass w/ faint gold border + luminous top
class LuxuryPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const LuxuryPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: isDark ? 0.30 : 0.40),
          width: 1,
        ),
        // تدرج رقيق يضيء أعلى اللوحة / subtle wash lighting the panel top
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: isDark ? 0.07 : 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// حقل بحث فاخر بإطار ذهبي متوهج / Luxury search field, glowing gold frame
class LuxurySearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const LuxurySearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: isDark ? 0.45 : 0.55),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          // وهج ذهبي من أعلى اليسار / gold glow from the top-left corner
          BoxShadow(
            color: AppColors.goldBright.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              colors: <Color>[Color(0xFFE8C96A), Color(0xFFB8912F)],
            ).createShader(bounds),
            child: const Icon(Icons.search, color: Colors.white),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.75),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
