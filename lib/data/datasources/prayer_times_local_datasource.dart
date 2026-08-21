// مصدر بيانات المواقيت — غلاف adhan / Prayer times datasource: adhan wrapper
// ملاحظة: adhan مستوردة بـ prefix لتجنب تعارض الأسماء مع domain
// Note: adhan imported with prefix to avoid name clashes with domain
// أسماء adhan الفعلية snake_case: umm_al_qura, middle_of_the_night...
// Actual adhan enum names are snake_case

import 'package:adhan/adhan.dart' as adhan;

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_times_repository.dart';

/// غلاف حساب المواقيت عبر adhan — يعمل بدون إنترنت بالكامل
/// Offline prayer-times computation through the adhan library
class PrayerTimesLocalDatasource implements PrayerTimesRepository {
  const PrayerTimesLocalDatasource();

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) async {
    final adhan.Coordinates coordinates =
        adhan.Coordinates(city.latitude, city.longitude);
    final adhan.CalculationParameters params = _parametersFor(settings.method);

    // المذهب (معامل العصر) + قاعدة خطوط العرض العليا
    // Madhab (Asr factor) and the high-latitude rule
    params.madhab = settings.madhab == Madhab.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;

    // adhan تُرجع الأوقات بالتوقيت العالمي — نحولها لتوقيت المدينة
    // adhan returns UTC times; shift to the city's fixed offset
    final adhan.PrayerTimes raw = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents.from(date),
      params,
    );
    final Duration offset =
        Duration(minutes: (city.timezoneOffsetHours * 60).round());

    DateTime toLocal(DateTime utcTime) => utcTime.add(offset);

    PrayerTime build(Prayer prayer, DateTime utcTime) {
      final DateTime time = toLocal(utcTime);
      final String key = prayer.name; // fajr..isha
      final int iqamahMinutes = settings.iqamahOffsets[key] ?? 15;
      return PrayerTime(
        prayer: prayer,
        time: time,
        iqamahTime: time.add(Duration(minutes: iqamahMinutes)),
      );
    }

    return DailyPrayerTimes(
      date: date,
      times: <PrayerTime>[
        build(Prayer.fajr, raw.fajr),
        build(Prayer.sunrise, raw.sunrise),
        build(Prayer.dhuhr, raw.dhuhr),
        build(Prayer.asr, raw.asr),
        build(Prayer.maghrib, raw.maghrib),
        build(Prayer.isha, raw.isha),
      ],
    );
  }

  /// مطابقة طريقة الحساب إلى adhan (أسماء snake_case)
  /// Map our method enum to adhan's (snake_case names)
  adhan.CalculationParameters _parametersFor(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.ummAlQura:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case CalculationMethod.muslimWorldLeague:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case CalculationMethod.egyptian:
        return adhan.CalculationMethod.egyptian.getParameters();
      case CalculationMethod.karachi:
        return adhan.CalculationMethod.karachi.getParameters();
      case CalculationMethod.northAmerica:
        return adhan.CalculationMethod.north_america.getParameters();
      case CalculationMethod.turkey:
        return adhan.CalculationMethod.turkey.getParameters();
      case CalculationMethod.qatar:
        return adhan.CalculationMethod.qatar.getParameters();
      case CalculationMethod.kuwait:
        return adhan.CalculationMethod.kuwait.getParameters();
      case CalculationMethod.dubai:
        return adhan.CalculationMethod.dubai.getParameters();
    }
  }
}