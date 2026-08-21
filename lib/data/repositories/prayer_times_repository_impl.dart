// تنفيذ مستودع المواقيت / Prayer times repository implementation

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/prayer_times_local_datasource.dart';

/// يمرر الطلبات إلى مصدر البيانات المحلي (adhan)
/// Delegates to the local datasource (adhan)
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final PrayerTimesLocalDatasource _datasource;

  const PrayerTimesRepositoryImpl(this._datasource);

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) {
    return _datasource.getPrayerTimes(
      city: city,
      date: date,
      settings: settings,
    );
  }
}