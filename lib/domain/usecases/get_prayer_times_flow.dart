// حالة استخدام: تجميع مواقيت اليوم والغد معاً لأي مدينة/إعدادات
// Use case: bundle today's + tomorrow's times for a city/settings
// يجمع منطق «الغد كتاريخ كنداري DST-آمن» كان مكرراً في الطبقة التقديمية
// ويتيح حقن `now` للاختبار دون تغيير سلوك الإنتاج (التواريخ نفسها).

import '../entities/app_settings.dart';
import '../entities/city.dart';
import '../entities/prayer_time.dart';
import '../repositories/prayer_times_repository.dart';

/// تجميع مواقيت اليوم والغد
/// Bundles today's + tomorrow's times via the repository contract
class GetPrayerTimesFlow {
  final PrayerTimesRepository _repository;

  const GetPrayerTimesFlow(this._repository);

  /// مواقيت اليوم — "اليوم" بتقويم المدينة نفسها (لا بتوقيت الجهاز)،
  /// والـ now الاختياري للاختبار فقط
  /// Today's times — "today" on the CITY's calendar (not the device's);
  /// optional [now] is for tests only
  Future<DailyPrayerTimes> today({
    required City city,
    required AppSettings settings,
    DateTime? now,
  }) {
    return _repository.getPrayerTimes(
      city: city,
      date: now ?? _repository.cityNow(city),
      settings: settings,
    );
  }

  /// مواقيت الغد كتاريخ كنداري بتقويم المدينة (آمن مع DST) — لا إضافة 24 ساعة
  /// Tomorrow as a calendar date on the city's calendar (DST-safe), not +24h
  Future<DailyPrayerTimes> tomorrow({
    required City city,
    required AppSettings settings,
    DateTime? now,
  }) {
    final DateTime base = now ?? _repository.cityNow(city);
    return _repository.getPrayerTimes(
      city: city,
      date: DateTime(base.year, base.month, base.day + 1),
      settings: settings,
    );
  }

  /// المدة حتى منتصف الليل القادم بتوقيت المدينة (لجدولة التحديث اليومي)
  /// Duration until the next midnight in the city's timezone (daily refresh)
  Duration timeUntilCityMidnight(City city) =>
      _repository.timeUntilCityMidnight(city);
}
