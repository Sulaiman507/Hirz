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

  /// مواقيت اليوم (الآن ما لم يُحقن [now] للاختبار)
  Future<DailyPrayerTimes> today({
    required City city,
    required AppSettings settings,
    DateTime? now,
  }) {
    return _repository.getPrayerTimes(
      city: city,
      date: now ?? DateTime.now(),
      settings: settings,
    );
  }

  /// مواقيت الغد كتاريخ كنداري (آمن مع DST) — لا إضافة 24 ساعة
  /// Tomorrow as a calendar date (DST-safe), not +24h
  Future<DailyPrayerTimes> tomorrow({
    required City city,
    required AppSettings settings,
    DateTime? now,
  }) {
    final DateTime base = now ?? DateTime.now();
    return _repository.getPrayerTimes(
      city: city,
      date: DateTime(base.year, base.month, base.day + 1),
      settings: settings,
    );
  }
}
