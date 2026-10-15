// عقد مستودع مواقيت الصلاة / Prayer times repository contract
// الطبقات الخارجية (data) تنفّذ هذا العقد / Outer layers (data) implement it

import '../entities/app_settings.dart';
import '../entities/city.dart';
import '../entities/prayer_time.dart';

abstract class PrayerTimesRepository {
  /// حساب مواقيت يوم كامل لمدينة وإعدادات محددة
  /// Compute a full day's times for a city and settings
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  });

  /// "الآن" بتوقيت المدينة (لحدود اليوم التقويمي) — يدعم DST، ويرجع للإزاحة
  /// الثابتة للمدن اليدوية بلا timezoneId
  /// "Now" in the city's timezone (for calendar-day boundaries) — DST-aware,
  /// falling back to the fixed offset for manual cities without a timezoneId
  DateTime cityNow(City city);

  /// المدة حتى منتصف الليل القادم بتوقيت المدينة (لجدولة التحديث اليومي)
  /// Duration until the next midnight in the city's timezone (for daily refresh)
  Duration timeUntilCityMidnight(City city);
}
