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

/// حقل بحث فاخر بإطار ذهبي متوهج + زر مسح / Luxury search field, gold frame + clear button
class LuxurySearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  /// تحكم اختياري من الأب لمسح النص خارجياً / optional parent controller for external clearing
  final TextEditingController? controller;

  const LuxurySearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  State<LuxurySearchField> createState() => _LuxurySearchFieldState();
}

class _LuxurySearchFieldState extends State<LuxurySearchField> {
  TextEditingController? _internal;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internal ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant LuxurySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_refresh);
      widget.controller?.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_refresh);
    _internal?.dispose();
    super.dispose();
  }

  /// يعيد البناء عند تغير النص لإظهار/إخفاء زر المسح
  /// Rebuild on text change to toggle the clear button
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasText = _effectiveController.text.isNotEmpty;

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
        controller: _effectiveController,
        onChanged: widget.onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              colors: <Color>[Color(0xFFE8C96A), Color(0xFFB8912F)],
            ).createShader(bounds),
            child: const Icon(Icons.search, color: Colors.white),
          ),
          // زر مسح يظهر فقط مع نص / clear button only when text exists
          suffixIcon: hasText
              ? IconButton(
                  iconSize: 18,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    _effectiveController.clear();
                    widget.onChanged('');
                  },
                )
              : null,
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
