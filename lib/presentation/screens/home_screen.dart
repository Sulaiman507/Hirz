// الشاشة الرئيسية / Home screen
// التاريخ + العدّاد التنازلي + مواقيت الصلاة + التنقل

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnightRefresh();
  }

  /// تحديث التاريخ والمواقيت عند منتصف الليل تلقائياً
  /// Auto-refresh date + times at midnight
  void _scheduleMidnightRefresh() {
    final DateTime now = DateTime.now();
    final DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer?.cancel();
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      ref.invalidate(prayerTimesProvider);
      ref.invalidate(tomorrowTimesProvider);
      ref.invalidate(nextPrayerInfoProvider);
      setState(() {}); // تحديث التاريخ / refresh the date header
      _scheduleMidnightRefresh(); // جدولة الليلة القادمة / schedule next night
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(settingsProvider);
    final AsyncValue<City> cityAsync = ref.watch(selectedCityProvider);
    final AsyncValue<DailyPrayerTimes> timesAsync =
        ref.watch(prayerTimesProvider);

    final AppSettings settings =
        settingsAsync.valueOrNull ?? const AppSettings(
      languageCode: 'ar',
      isDarkMode: false,
      method: CalculationMethod.auto,
      madhab: Madhab.shafi,
      use24HourFormat: false,
      iqamahOffsets: AppSettings.defaultIqamahOffsets,
    );

    return Scaffold(
      // الخلفية من الثيم مباشرة (سطح داكن/فاتح) — بلا صور ولا Stack
      // background from theme surface directly — no image, no stack
      backgroundColor: null,
      // الوضع الليلي: AppBar يغطي أعلى الصورة / dark: bar covers image top
      appBar: AppBar(
        backgroundColor: settings.isDarkMode
            ? const Color(0xFF0A1128)
            : AppColors.offWhite,
        scrolledUnderElevation: 0,
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
      body: SafeArea(
        child: ListView(
          // تمرير iOS المرن — انزلاق ناعم وارتداد مطاطي عند الأطراف
          // iOS-style elastic scroll — smooth glide + gentle edge bounce
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // التاريخ الهجري والميلادي — من تاريخ المواقيت المحسوبة
            // (مصدر حقيقة واحد يتبع تحديث منتصف الليل تلقائياً)
            // Date header — from computed times date (single source of
            // truth, follows midnight refresh automatically)
            DateHeader(
              date: timesAsync.valueOrNull?.date ?? DateTime.now(),
              languageCode: settings.languageCode,
            ),
            const SizedBox(height: 16),
            // زر المدينة / City button
            cityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => const SizedBox.shrink(),
              data: (City city) => _CityButton(city: city),
            ),
            const SizedBox(height: 16),
            // العدّاد التنازلي — بدون animate: كان يعيد الأنيميشن مع كل tick
            // Countdown — no animate wrapper: re-animated on every second tick
            const CountdownTimer(),
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
                // بدون fadeIn لكل بطاقة — يسبب وميضاً عند دخول الشاشة
                // No per-card fadeIn — it flickered when scrolling into view
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