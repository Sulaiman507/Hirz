// شاشة الإعدادات / Settings screen
// اللغة، المظهر، طريقة الحساب، المذهب، تنسيق الوقت، فروق الإقامة

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/settings_providers.dart';

/// كل الإعدادات في شاشة واحدة / All settings in one screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// مفتاح ترجمة طريقة الحساب / Localization key for a method
  String _methodKey(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.auto:
        return 'methodAuto';
      case CalculationMethod.ummAlQura:
        return 'methodUmmAlQura';
      case CalculationMethod.muslimWorldLeague:
        return 'methodMuslimWorldLeague';
      case CalculationMethod.egyptian:
        return 'methodEgyptian';
      case CalculationMethod.karachi:
        return 'methodKarachi';
      case CalculationMethod.northAmerica:
        return 'methodNorthAmerica';
      case CalculationMethod.turkey:
        return 'methodTurkey';
      case CalculationMethod.qatar:
        return 'methodQatar';
      case CalculationMethod.kuwait:
        return 'methodKuwait';
      case CalculationMethod.dubai:
        return 'methodDubai';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('settingsTitle'))),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text(l10n.tr('error'))),
        data: (AppSettings settings) {
          final SettingsNotifier notifier =
              ref.read(settingsProvider.notifier);

          return ListView(
              // نفس التمرير المرن الموحد / same unified elastic scroll
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // ── اللغة / Language ──────────────────────────────
              _sectionTitle(context, l10n.tr('language')),
              SegmentedButton<String>(
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
              const SizedBox(height: 24),

              // ── المظهر / Theme ────────────────────────────────
              _sectionTitle(context, l10n.tr('theme')),
              SwitchListTile(
                title: Text(l10n.tr('darkMode')),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: settings.isDarkMode,
                onChanged: (bool value) => notifier.updateTheme(value),
              ),
              const SizedBox(height: 24),

              // ── طريقة الحساب / Calculation method ─────────────
              _sectionTitle(context, l10n.tr('calculationMethod')),
              ...CalculationMethod.values.map(
                (CalculationMethod method) => RadioListTile<CalculationMethod>(
                  title: Text(l10n.tr(_methodKey(method))),
                  value: method,
                  groupValue: settings.method,
                  onChanged: (CalculationMethod? value) {
                    if (value != null) notifier.updateMethod(value);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── المذهب / Madhab ───────────────────────────────
              _sectionTitle(context, l10n.tr('madhab')),
              SegmentedButton<Madhab>(
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
              const SizedBox(height: 24),

              // ── تنسيق الوقت / Time format ─────────────────────
              _sectionTitle(context, l10n.tr('timeFormat')),
              SwitchListTile(
                title: Text(l10n.tr('format24')),
                secondary: const Icon(Icons.access_time),
                value: settings.use24HourFormat,
                onChanged: (bool value) => notifier.updateTimeFormat(value),
              ),
              const SizedBox(height: 24),

              // ── فروق الإقامة / Iqamah offsets ─────────────────
              _sectionTitle(context, l10n.tr('iqamahOffsets')),
              ...<Prayer>[
                Prayer.fajr,
                Prayer.sunrise,
                Prayer.dhuhr,
                Prayer.asr,
                Prayer.maghrib,
                Prayer.isha,
              ].map(
                (Prayer prayer) => _IqamahOffsetRow(
                  prayerKey: prayer.name,
                  label: l10n.tr(prayer.name),
                  value: settings.iqamahOffsets[prayer.name] ?? 15,
                  onChanged: (int minutes) =>
                      notifier.updateIqamahOffset(prayer.name, minutes),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
              style: Theme.of(context).textTheme.titleMedium,
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