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
}
