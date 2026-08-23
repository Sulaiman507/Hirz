// مصدر بيانات المواقيت — غلاف adhan / Prayer times datasource: adhan wrapper
// ملاحظة: adhan مستوردة بـ prefix لتجنب تعارض الأسماء مع domain
// Note: adhan imported with prefix to avoid name clashes with domain
// أسماء adhan الفعلية snake_case: umm_al_qura, middle_of_the_night...
// Actual adhan enum names are snake_case

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_times_repository.dart';

/// غلاف حساب المواقيت عبر adhan — يعمل بدون إنترنت بالكامل
/// Offline prayer-times computation through the adhan library
class PrayerTimesLocalDatasource implements PrayerTimesRepository {
  const PrayerTimesLocalDatasource();

  static bool _tzInitialized = false; // تهيئة tz مرة واحدة / init once

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) async {
    final adhan.Coordinates coordinates =
        adhan.Coordinates(city.latitude, city.longitude);

    // ── اختيار طريقة الحساب ──
    // أولوية المستخدم (إعدادات "تلقائي" = null) ثم الطريقة الرسمية
    // للمدينة، وإلا الافتراضي من الإعدادات (Umm Al-Qura).
    //
    // Method selection: user override wins ("auto" = null), else the
    // city's official regional method, else the settings default.
    final adhan.CalculationParameters params =
        _parametersFor(_resolveMethod(city, settings));

    // المذهب (معامل العصر) + قاعدة خطوط العرض العليا
    // Madhab (Asr factor) and the high-latitude rule
    params.madhab = settings.madhab == Madhab.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;

    // ── الإزاحة الصحيحة حسب التاريخ (DST-aware) ──
    // إذا توفر timezoneId (IANA) نحسب الإزاحة الفعلية للتاريخ المطلوب:
    // شتوية/صيفية تلقائياً. وإلا نرجع للإزاحة الثابتة الاحتياطية.
    //
    // DST-aware offset: when a timezoneId (IANA) exists, compute the
    // actual UTC offset for the requested date (summer/winter automatic).
    // Fall back to the fixed winter offset otherwise.
    final Duration offset = _effectiveOffset(city, date);

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

  /// الإزاحة الفعلية للمدينة في التاريخ المطلوب — تدعم DST تلقائياً
  /// Effective offset for the city on the given date — DST-aware
  Duration _effectiveOffset(City city, DateTime date) {
    final String? tzId = city.timezoneId;
    if (tzId == null || tzId.isEmpty) {
      return Duration(minutes: (city.timezoneOffsetHours * 60).round());
    }
    try {
      if (!_tzInitialized) {
        tzdata.initializeTimeZones();
        _tzInitialized = true;
      }
      final tz.Location location = tz.getLocation(tzId);
      // منتصف الظهر بتاريخ المدينة — نقطة تمثيل دقيقة للإزاحة اليومية
      // Local noon on that date — accurate representative instant
      final DateTime localNoon = DateTime(
          date.year, date.month, date.day, 12);
      final int offsetMinutes =
          tz.TZDateTime.from(localNoon, location).timeZoneOffset.inMinutes;
      return Duration(minutes: offsetMinutes);
    } catch (e) {
      // معرف غير معروف → الإزاحة الاحتياطية / unknown id → fallback
      // نطبع في debug فقط لتشخيص الأخطاء الحقيقية لاحقاً
      assert(() {
        debugPrint('Hirz: timezone lookup failed for "$tzId": $e');
        return true;
      }());
      return Duration(minutes: (city.timezoneOffsetHours * 60).round());
    }
  }

  /// تحديد الطريقة: تجاوز المستخدم → طريقة المدينة الرسمية → افتراضي الإعدادات
  /// Resolve method: user override → city official → settings default
  CalculationMethod _resolveMethod(City city, AppSettings settings) {
    // "auto" يعني اتباع المدينة / "auto" means follow the city
    if (settings.method == CalculationMethod.auto) {
      final String? cityMethod = city.methodId;
      if (cityMethod != null && cityMethod.isNotEmpty) {
        final CalculationMethod? parsed =
            _methodById(cityMethod);
        if (parsed != null) return parsed;
      }
      return CalculationMethod.ummAlQura; // احتياط معقول / sane fallback
    }
    return settings.method;
  }

  /// مطابقة نص الطريقة من JSON إلى enum / Map JSON string to enum
  CalculationMethod? _methodById(String id) {
    for (final CalculationMethod m in CalculationMethod.values) {
      if (m.jsonId == id) return m;
    }
    return null;
  }

  /// مطابقة طريقة الحساب إلى adhan (أسماء snake_case)
  /// Map our method enum to adhan's (snake_case names)
  adhan.CalculationParameters _parametersFor(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.auto:
        // لا يجب الوصول لهنا — يُحل قبلها في _resolveMethod
        // Should not reach here — resolved earlier in _resolveMethod
        return adhan.CalculationMethod.umm_al_qura.getParameters();
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