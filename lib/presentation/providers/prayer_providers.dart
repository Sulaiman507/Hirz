// providers المواقيت: إعادة حساب عند تغير المدينة/الإعدادات/التاريخ
// Prayer providers: recompute when city/settings/date change

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import 'app_providers.dart';
import 'city_providers.dart';
import 'settings_providers.dart';

/// مواقيت اليوم للمدينة المختارة — يُعاد حسابه تلقائياً عند أي تغيير
/// Today's times for the selected city — recomputed on any change
final FutureProvider<DailyPrayerTimes>
prayerTimesProvider = FutureProvider<DailyPrayerTimes>((Ref ref) async {
  final City city = await ref.watch(selectedCityProvider.future);
  final AppSettings settings = await ref.watch(settingsProvider.future);
  final getPrayerTimes = await ref.watch(getPrayerTimesUseCaseProvider.future);
  return getPrayerTimes(city: city, date: DateTime.now(), settings: settings);
});

/// معلومات الصلاة القادمة (الاسم + الوقت) للعدّاد التنازلي
/// Next prayer info for the countdown timer
final FutureProvider<PrayerTime?> nextPrayerInfoProvider =
    FutureProvider<PrayerTime?>((Ref ref) async {
      final DailyPrayerTimes times = await ref.watch(
        prayerTimesProvider.future,
      );
      return times.nextPrayer(DateTime.now());
    });

/// مواقيت الغد — تُستخدم عندما تنتهي صلوات اليوم (بعد العشاء)
/// Tomorrow's times — used when today's prayers are over (after isha)
final FutureProvider<DailyPrayerTimes> tomorrowTimesProvider =
    FutureProvider<DailyPrayerTimes>((Ref ref) async {
      final City city = await ref.watch(selectedCityProvider.future);
      final AppSettings settings = await ref.watch(settingsProvider.future);
      final getPrayerTimes = await ref.watch(
        getPrayerTimesUseCaseProvider.future,
      );
      return getPrayerTimes(
        city: city,
        date: DateTime.now().add(const Duration(days: 1)),
        settings: settings,
      );
    });
