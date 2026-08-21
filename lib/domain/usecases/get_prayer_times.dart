// حالة استخدام: جلب مواقيت الصلاة / Use case: get prayer times

import '../entities/app_settings.dart';
import '../entities/city.dart';
import '../entities/prayer_time.dart';
import '../repositories/prayer_times_repository.dart';

/// حساب مواقيت يوم لمدينة حسب الإعدادات
/// Compute a day's times for a city per settings
class GetPrayerTimes {
  final PrayerTimesRepository _repository;

  const GetPrayerTimes(this._repository);

  Future<DailyPrayerTimes> call({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) {
    return _repository.getPrayerTimes(
      city: city,
      date: date,
      settings: settings,
    );
  }
}