// شاشة الإعدادات — بدون شريط علوي، مع زر إغلاق
// Settings screen — no top bar, with close button

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_time.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/safe_margins.dart';
import '../providers/settings_providers.dart';
import '../widgets/luxury_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text(l10n.tr('error'))),
        data: (AppSettings settings) {
          final SettingsNotifier notifier = ref.read(settingsProvider.notifier);

          return Column(
            children: <Widget>[
              // صف العنوان + زر الإغلاق
              Padding(
                // المسافة الآمنة العلوية المصممة (32) — بديلة لمساحة النظام
                // Designed top safe margin (32) — replaces the system inset
                padding: const EdgeInsets.fromLTRB(
                  16,
                  kSafeMarginTop,
                  8,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.tr('settingsTitle'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.tr('close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  // مسافة سفلية آمنة (24) — العلوية مغطاة برأس الشاشة
                  // Bottom safe margin (24) — top covered by the header
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    kSafeMarginBottom,
                  ),
                  children: <Widget>[
                    // ══ مجموعة: عام / Group: General ══
                    LuxuryGroupHeader(
                      title: l10n.tr('settingsGroupGeneral'),
                      icon: Icons.tune_outlined,
                    ),
                    // ── اللغة / Language ──────────────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('language'),
                      icon: Icons.translate,
                    ),
                    LuxuryPanel(
                      child: SegmentedButton<String>(
                        segments: <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'ar',
                            label: Text(l10n.tr('arabic')),
                          ),
                          ButtonSegment<String>(
                            value: 'en',
                            label: Text(l10n.tr('english')),
                          ),
                        ],
                        selected: <String>{settings.languageCode},
                        onSelectionChanged: (Set<String> selection) =>
                            notifier.updateLanguage(selection.first),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ══ مجموعة: المواقيت والحساب / Group: Prayer times ══
                    LuxuryGroupHeader(
                      title: l10n.tr('settingsGroupPrayer'),
                      icon: Icons.schedule_outlined,
                    ),
                    // ── طريقة الحساب / Calculation method ─────────────
                    LuxurySectionTitle(
                      title: l10n.tr('calculationMethod'),
                      icon: Icons.calculate_outlined,
                    ),
                    // قابلة للطي: أول 3 طرق + زر "المزيد..."
                    // Collapsible: first 3 methods + "More..." button
                    _CalculationMethodSection(
                      groupValue: settings.method,
                      onChanged: (CalculationMethod? value) {
                        if (value != null) {
                          notifier.updateMethod(value);
                        }
                      },
                      l10n: l10n,
                    ),
                    const SizedBox(height: 22),

                    // ── المذهب / Madhab ───────────────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('madhab'),
                      icon: Icons.menu_book_outlined,
                    ),
                    LuxuryPanel(
                      child: SegmentedButton<Madhab>(
                        segments: <ButtonSegment<Madhab>>[
                          ButtonSegment<Madhab>(
                            value: Madhab.shafi,
                            label: Text(l10n.tr('shafi')),
                          ),
                          ButtonSegment<Madhab>(
                            value: Madhab.hanafi,
                            label: Text(l10n.tr('hanafi')),
                          ),
                        ],
                        selected: <Madhab>{settings.madhab},
                        onSelectionChanged: (Set<Madhab> selection) =>
                            notifier.updateMadhab(selection.first),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── تنسيق الوقت / Time format ─────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('timeFormat'),
                      icon: Icons.access_time,
                    ),
                    LuxuryPanel(
                      padding: const EdgeInsets.all(4),
                      child: SwitchListTile(
                        title: Text(l10n.tr('format24')),
                        secondary: ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: <Color>[
                              Color(0xFFE8C96A),
                              Color(0xFFB8912F),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                          ),
                        ),
                        value: settings.use24HourFormat,
                        onChanged: (bool value) =>
                            notifier.updateTimeFormat(value),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── فروق الإقامة / Iqamah offsets ─────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('iqamahOffsets'),
                      icon: Icons.timelapse_outlined,
                    ),
                    LuxuryPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        children:
                            <Prayer>[
                                  Prayer.fajr,
                                  // الشروق ليس صلاة ذات إقامة — لا يُعرض هنا
                                  // Sunrise has no iqamah — excluded here
                                  Prayer.dhuhr,
                                  Prayer.asr,
                                  Prayer.maghrib,
                                  Prayer.isha,
                                ]
                                .map(
                                  (Prayer prayer) => _IqamahOffsetRow(
                                    label: l10n.tr(prayer.name),
                                    value:
                                        settings.iqamahOffsets[prayer.name] ??
                                        15,
                                    onChanged: (int minutes) =>
                                        notifier.updateIqamahOffset(
                                          prayer.name,
                                          minutes,
                                        ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ══ مجموعة: المظهر والخط / Group: Appearance ══
                    LuxuryGroupHeader(
                      title: l10n.tr('settingsGroupAppearance'),
                      icon: Icons.palette_outlined,
                    ),
                    // ── المظهر / Theme ────────────────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('theme'),
                      icon: Icons.dark_mode_outlined,
                    ),
                    LuxuryPanel(
                      padding: const EdgeInsets.all(4),
                      child: SwitchListTile(
                        title: Text(l10n.tr('darkMode')),
                        secondary: ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: <Color>[
                              Color(0xFFE8C96A),
                              Color(0xFFB8912F),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.dark_mode_outlined,
                            color: Colors.white,
                          ),
                        ),
                        value: settings.isDarkMode,
                        onChanged: (bool value) => notifier.updateTheme(value),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── نوع الخط / Font family ─────────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('fontFamily'),
                      icon: Icons.text_fields,
                    ),
                    LuxuryPanel(
                      child: SegmentedButton<String>(
                        segments: <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'Amiri',
                            label: Text(l10n.tr('fontAmiri')),
                          ),
                          ButtonSegment<String>(
                            value: 'Cairo',
                            label: Text(l10n.tr('fontCairo')),
                          ),
                        ],
                        selected: <String>{settings.fontFamily},
                        onSelectionChanged: (Set<String> sel) =>
                            notifier.updateFontFamily(sel.first),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── سماكة الخط / Font thickness ────────────────────
                    LuxurySectionTitle(
                      title: l10n.tr('fontThickness'),
                      icon: Icons.format_bold,
                    ),
                    LuxuryPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(l10n.tr('fontThin')),
                          Expanded(
                            child: Slider(
                              value: settings.fontThickness,
                              min: 0.5,
                              max: 2.0,
                              divisions: 6,
                              label: settings.fontThickness.toStringAsFixed(1),
                              onChanged: (double v) =>
                                  notifier.updateFontThickness(v),
                            ),
                          ),
                          Text(l10n.tr('fontThick')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// صف تعديل فرق الإقامة / Iqamah offset row with +/- buttons
class _IqamahOffsetRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _IqamahOffsetRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 5) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < 120 ? () => onChanged(value + 5) : null,
          ),
        ],
      ),
    );
  }
}

/// قسم طريقة الحساب القابل للطي — يعرض أول 3 طرق + زر "المزيد..."
/// Collapsible calculation-method section — first 3 methods + "More..." button
class _CalculationMethodSection extends StatefulWidget {
  final CalculationMethod groupValue;
  final ValueChanged<CalculationMethod?> onChanged;
  final AppLocalizations l10n;

  const _CalculationMethodSection({
    required this.groupValue,
    required this.onChanged,
    required this.l10n,
  });

  @override
  State<_CalculationMethodSection> createState() =>
      _CalculationMethodSectionState();
}

class _CalculationMethodSectionState extends State<_CalculationMethodSection> {
  /// عدد الطرق الظاهرة قبل الطي / methods shown before collapsing the rest
  static const int _visibleCount = 3;

  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // إن كانت الطريقة المختارة خارج الثلاث الأولى، ابدأ موسّعاً
    // If the selected method is beyond the first three, start expanded
    _expanded = !CalculationMethod.values
        .take(_visibleCount)
        .contains(widget.groupValue);
  }

  @override
  void didUpdateWidget(covariant _CalculationMethodSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupValue != widget.groupValue &&
        !_expanded &&
        !CalculationMethod.values
            .take(_visibleCount)
            .contains(widget.groupValue)) {
      setState(() => _expanded = true);
    }
  }

  String _label(CalculationMethod method) {
    final String id = method.jsonId;
    return widget.l10n.tr(
      'method${id.substring(0, 1).toUpperCase()}${id.substring(1)}',
    );
  }

  Widget _radio(CalculationMethod method) {
    return RadioListTile<CalculationMethod>(
      title: Text(_label(method)),
      dense: true,
      value: method,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<CalculationMethod> methods = CalculationMethod.values;

    return LuxuryPanel(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RadioGroup<CalculationMethod>(
        groupValue: widget.groupValue,
        onChanged: widget.onChanged,
        child: Column(
          children: <Widget>[
            ...methods.take(_visibleCount).map(_radio),
          // زر المزيد / عرض أقل — More / show less button
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.l10n.tr(_expanded ? 'showLess' : 'showMore'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: <Widget>[
                ...methods.skip(_visibleCount).map(_radio),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          ],
        ),
      ),
    );
  }
}
