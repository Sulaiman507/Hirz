// الشاشة الرئيسية / Home screen
// التاريخ + العدّاد التنازلي + مواقيت الصلاة + التنقل

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/city_providers.dart';
import '../providers/prayer_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/date_header.dart';
import '../widgets/prayer_card.dart';
import 'city_selection_screen.dart';
import 'settings_screen.dart';

/// الشاشة الرئيسية: التاريخ، العدّاد، المواقيت / Home: date, countdown, times
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);
    final AsyncValue<City> cityAsync = ref.watch(selectedCityProvider);
    final AsyncValue<DailyPrayerTimes> timesAsync =
        ref.watch(prayerTimesProvider);

    final AppSettings settings =
        settingsAsync.valueOrNull ?? const AppSettings(
      languageCode: 'ar',
      isDarkMode: false,
      method: CalculationMethod.ummAlQura,
      madhab: Madhab.shafi,
      use24HourFormat: false,
      iqamahOffsets: AppSettings.defaultIqamahOffsets,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.tr('appName')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.tr('settingsTitle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // الخلفية الليلية — RepaintBoundary يمنع إعادة رسمها عند التمرير
          // Night background — RepaintBoundary prevents repaint on scroll
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedNightBackground(isDark: settings.isDarkMode),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
            // التاريخ الهجري والميلادي / Hijri + Gregorian date
            DateHeader(
              date: DateTime.now(),
              languageCode: settings.languageCode,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            // زر المدينة / City button
            cityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => const SizedBox.shrink(),
              data: (City city) => _CityButton(city: city),
            ),
            const SizedBox(height: 16),
            // العدّاد التنازلي / Countdown
            const CountdownTimer().animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                ),
            const SizedBox(height: 20),
            // قائمة المواقيت / Prayer times list
            timesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (Object e, StackTrace s) => Center(
                child: Text(l10n.tr('error')),
              ),
              data: (DailyPrayerTimes daily) {
                final PrayerTime? next = daily.nextPrayer(DateTime.now());
                // بدون fadeIn لكل بطاقة — كان يسبب "ترسب" النجوم عند التمرير
                // (البطاقة شفافة أثناء الأنيميشن فتظهر النجوم خلفها فجأة)
                // No per-card fadeIn — it made stars appear through the
                // translucent card during animation, then "settle"
                return Column(
                  children: <Widget>[
                    for (final PrayerTime pt in daily.times)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PrayerCard(
                          prayerTime: pt,
                          isNext: next != null && next.prayer == pt.prayer,
                          use24Hour: settings.use24HourFormat,
                          languageCode: settings.languageCode,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

/// زر عرض وتغيير المدينة / Shows + changes the city
class _CityButton extends ConsumerWidget {
  final City city;

  const _CityButton({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String languageCode =
        ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar';
    final String cityName = languageCode == 'ar' ? city.nameAr : city.nameEn;
    final String countryName =
        languageCode == 'ar' ? city.countryAr : city.countryEn;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(
          cityName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(countryName),
        trailing: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CitySelectionScreen(),
            ),
          ),
          child: Text(l10n.tr('changeCity')),
        ),
      ),
    );
  }
}