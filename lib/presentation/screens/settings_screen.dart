// شاشة الإعدادات — بدون شريط علوي، مع زر إغلاق
// Settings screen — no top bar, with close button

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_time.dart';
import '../../core/l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../providers/notification_provider.dart';
import '../widgets/luxury_components.dart';
import '../widgets/notification_settings_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);
    final AsyncValue<NotificationSettings> notifAsync = ref.watch(
      notificationProvider,
    );

    return Scaffold(
      backgroundColor: null,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text(l10n.tr('error'))),
        data: (AppSettings settings) {
          final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
          final NotificationSettings notifSettings =
              notifAsync.valueOrNull ?? NotificationSettings.defaults();

          return Column(
            children: <Widget>[
              // صف العنوان + زر الإغلاق
              Padding(
                // SafeArea يدوية: ارتفاع شريط الحالة + التنفس الأصلي
                // Manual SafeArea: status-bar height + original breathing room
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 12,
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
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
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
                    const SizedBox(height: 22),

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

                    // ── طريقة الحساب / Calculation method ─────────────
                    LuxurySectionTitle(
                      title: l10n.tr('calculationMethod'),
                      icon: Icons.calculate_outlined,
                    ),
                    LuxuryPanel(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: CalculationMethod.values
                            .map(
                              (
                                CalculationMethod method,
                              ) => RadioListTile<CalculationMethod>(
                                title: Text(
                                  l10n.tr(
                                    'method${method.jsonId.substring(0, 1).toUpperCase()}${method.jsonId.substring(1)}',
                                  ),
                                ),
                                dense: true,
                                value: method,
                                groupValue: settings.method,
                                onChanged: (CalculationMethod? value) {
                                  if (value != null)
                                    notifier.updateMethod(value);
                                },
                              ),
                            )
                            .toList(),
                      ),
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
                                  Prayer.sunrise,
                                  Prayer.dhuhr,
                                  Prayer.asr,
                                  Prayer.maghrib,
                                  Prayer.isha,
                                ]
                                .map(
                                  (Prayer prayer) => _IqamahOffsetRow(
                                    prayerKey: prayer.name,
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
                    const SizedBox(height: 22),

                    // ── إشعارات الصلوات / Prayer notifications ────────
                    LuxurySectionTitle(
                      title: l10n.tr('notifTitle'),
                      icon: Icons.notifications_active,
                    ),
                    LuxuryPanel(
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            title: Text(l10n.tr('notifEnable')),
                            value: notifSettings.masterEnabled,
                            onChanged: (bool v) => ref
                                .read(notificationProvider.notifier)
                                .toggleMaster(v),
                          ),
                          const Divider(height: 1),
                          // قائمة الصلوات
                          ...Prayer.values.where((Prayer p) => p != Prayer.sunrise).map(
                                (Prayer prayer) => PrayerNotificationTile(
                                  prayer: prayer,
                                  label: l10n.tr(prayer.name),
                                ),
                              ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(l10n.tr('notifIqamah')),
                            subtitle: Text(l10n.tr('notifIqamahNote')),
                            value: notifSettings.iqamahEnabled,
                            onChanged: (bool v) => ref
                                .read(notificationProvider.notifier)
                                .toggleIqamah(v),
                          ),
                        ],
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
  final String prayerKey;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _IqamahOffsetRow({
    required this.prayerKey,
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
