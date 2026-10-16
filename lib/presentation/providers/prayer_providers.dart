// providers المواقيت: إعادة حساب عند تغير المدينة/الإعدادات/التاريخ
// Prayer providers: recompute when city/settings/date change

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/usecases/get_prayer_times_flow.dart';
import 'app_providers.dart';
import 'city_providers.dart';
import 'settings_providers.dart';

/// مواقيت اليوم للمدينة المختارة — يُعاد حسابه تلقائياً عند أي تغيير
/// Today's times for the selected city — recomputed on any change
final FutureProvider<DailyPrayerTimes> prayerTimesProvider =
    FutureProvider<DailyPrayerTimes>((Ref ref) async {
      final City city = await ref.watch(selectedCityProvider.future);
      final AppSettings settings = await ref.watch(settingsProvider.future);
      final GetPrayerTimesFlow flow = ref.watch(getPrayerTimesFlowProvider);
      return flow.today(city: city, settings: settings);
    });

/// مواقيت الغد — تُستخدم عندما تنتهي صلوات اليوم (بعد العشاء)
/// Tomorrow's times — used when today's prayers are over (after isha)
final FutureProvider<DailyPrayerTimes> tomorrowTimesProvider =
    FutureProvider<DailyPrayerTimes>((Ref ref) async {
      final City city = await ref.watch(selectedCityProvider.future);
      final AppSettings settings = await ref.watch(settingsProvider.future);
      final GetPrayerTimesFlow flow = ref.watch(getPrayerTimesFlowProvider);
      return flow.tomorrow(city: city, settings: settings);
    });

/// نبضة كل ثانية — تُبقي الشارات والعدّاد لحظية دون انتظار إعادة بناء
/// A one-second tick — keeps badges and countdown live without waiting
/// for a provider invalidation to rebuild the screen
final StreamProvider<DateTime> nowTickProvider =
    StreamProvider<DateTime>((Ref ref) {
      return Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      );
    });

/// "الآن" بتوقيت المدينة المختارة — المرجع الوحيد للمقارنات الزمنية
/// في الواجهة (الشارات، العدّاد). يُعاد حسابه مع كل نبضة.
/// "Now" in the selected city's timezone — the single reference for UI
/// time comparisons (badges, countdown). Recomputed on every tick.
///
/// مهم: لا تستخدم DateTime.now() مباشرة للمقارنة مع المواقيت — للمدن
/// اليدوية ذات الإزاحة الكسرية بلا timezoneId تُبنى الأوقات بانزياح
/// يدوي متسق، وcityNow يعيد الانزياح نفسه.
/// NOTE: never compare prayer times against raw DateTime.now() — for
/// fractional-offset manual cities without a timezoneId the times are
/// built with a consistent manual shift, and cityNow applies the same one.
final Provider<DateTime> cityNowProvider = Provider<DateTime>((Ref ref) {
  ref.watch(nowTickProvider);
  final City? city = ref.watch(selectedCityProvider).value;
  if (city == null) return DateTime.now();
  return ref.watch(getPrayerTimesFlowProvider).cityNow(city);
});
