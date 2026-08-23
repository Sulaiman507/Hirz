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

    // مصنع utcOffset يعيد الأوقات جاهزة بتوقيت المدينة (UTC + الإزاحة)
    // لا نضيف الإزاحة مرة أخرى هنا — كانت تسبب إزاحة مزدوجة (+3 ساعات مثلاً)
    // The utcOffset factory already returns city-local times (UTC + offset).
    // Do NOT shift again — that caused the +3h double-offset bug.
    final Duration offset =
        Duration(minutes: (city.timezoneOffsetHours * 60).round());
    final adhan.PrayerTimes raw = adhan.PrayerTimes.utcOffset(
      coordinates,
      adhan.DateComponents.from(date),
      params,
      offset,
    );

    PrayerTime build(Prayer prayer, DateTime time) {
      final String key = prayer.name; // fajr..isha
      final int iqamahMinutes = settings.iqamahOffsets[key] ?? 15;
      return PrayerTime(
        prayer: prayer,
        time: time,
        iqamahTime: time.add(Duration(minutes: iqamahMinutes)),
      );
    }

    // ── تطبيع النوع / Kind normalization (إصلاح جذري) ──
    // adhan يعيد القيم بتوقيت المدينة لكن بنوع UTC (isUtc=true).
    // مزجها مع DateTime.now() المحلي يفسد المقارنات والعدّاد لباقي المدن.
    // الحل: نبني DateTime محلياً خالصاً بنفس قيم الحقول المعروضة.
    //
    // adhan returns city-local values but tagged as UTC (isUtc=true).
    // Mixing with local DateTime.now() breaks comparisons/countdown for
    // most cities. Fix: rebuild as pure local DateTimes with the same
    // displayed field values.
    DateTime normalize(DateTime t) =>
        DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);

    return DailyPrayerTimes(
      date: normalize(date),
      times: <PrayerTime>[
        build(Prayer.fajr, normalize(raw.fajr)),
        build(Prayer.sunrise, normalize(raw.sunrise)),
        build(Prayer.dhuhr, normalize(raw.dhuhr)),
        build(Prayer.asr, normalize(raw.asr)),
        build(Prayer.maghrib, normalize(raw.maghrib)),
        build(Prayer.isha, normalize(raw.isha)),
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