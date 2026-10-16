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

/// طباعة تشخيصية في وضع التطوير فقط / debug-only logging
void _debugLog(String message) {
  if (kDebugMode) debugPrint(message);
}

/// غلاف حساب المواقيت عبر adhan — يعمل بدون إنترنت بالكامل
/// Offline prayer-times computation through the adhan library
class PrayerTimesLocalDatasource implements PrayerTimesRepository {
  const PrayerTimesLocalDatasource();

  static bool _tzInitialized = false; // تهيئة tz مرة واحدة / init once

  /// مطابقة نص الطريقة من JSON إلى enum — بحث O(1)
  /// JSON method id → enum lookup (O(1))
  static final Map<String, CalculationMethod> _methodById =
      <String, CalculationMethod>{
        for (final CalculationMethod m in CalculationMethod.values) m.jsonId: m,
      };

  /// تهيئة قاعدة بيانات المناطق الزمنية مرة واحدة / init tz DB once
  static void _ensureTzInitialized() {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) async {
    final adhan.Coordinates coordinates = adhan.Coordinates(
      city.latitude,
      city.longitude,
    );

    // ── اختيار طريقة الحساب ──
    // أولوية المستخدم (إعدادات "تلقائي" = null) ثم الطريقة الرسمية
    // للمدينة، وإلا الافتراضي من الإعدادات (Umm Al-Qura).
    //
    // Method selection: user override wins ("auto" = null), else the
    // city's official regional method, else the settings default.
    final adhan.CalculationParameters params = _parametersFor(
      _resolveMethod(city, settings),
    );

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

    // ── توحيد المنطقة الزمنية / timezone-aware normalization ──
    // adhan يرجع الأوقات بتوقيت المدينة لكن بنوع UTC (isUtc=true) — أي أن
    // الحقول (ساعة/دقيقة) صحيحة محلياً للمدينة لكن الـ epoch كأنها UTC.
    // مزجها مع DateTime.now() المحلي يفسد المقارنات والعدّاد لأي مدينة
    // وقتها يختلف عن وقت الجهاز.
    //
    // الحل: نعيد بناء كل وقت كـ TZDateTime في منطقة المدينة من حقول
    // wall-clock نفسها. TZDateTime يحمل الـ instant الصحيح (epoch) مع
    // مجلدات محلية للمدينة — فيتعامل معها العدّاد والمقارنات صح مهما كانت
    // منطقة الجهاز، وتُعرض الأوقات بتوقيت المدينة دائماً.
    //
    // adhan returns city-local times tagged as UTC (fields = city wall-clock,
    // epoch interpreted as UTC). Mixing with device-local DateTime.now()
    // breaks comparisons for any city whose offset differs from the device.
    // Fix: rebuild each time as a TZDateTime in the city's zone from the same
    // wall-clock fields — correct instant (epoch) + city-local fields.
    final tz.Location cityLoc = _locationFor(city);
    tz.TZDateTime inCityZone(DateTime t) => tz.TZDateTime(
      cityLoc,
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
    );

    return DailyPrayerTimes(
      date: inCityZone(date),
      times: <PrayerTime>[
        build(Prayer.fajr, inCityZone(raw.fajr)),
        build(Prayer.sunrise, inCityZone(raw.sunrise)),
        build(Prayer.dhuhr, inCityZone(raw.dhuhr)),
        build(Prayer.asr, inCityZone(raw.asr)),
        build(Prayer.maghrib, inCityZone(raw.maghrib)),
        build(Prayer.isha, inCityZone(raw.isha)),
      ],
    );
  }

  /// منطقة المدينة: IANA الحقيقي، أو منطقة Etc/GMT ذات إزاحة ثابتة
  /// (بعكس إشارة POSIX: Etc/GMT-3 == UTC+3) للمدن اليدوية بلا timezoneId،
  /// أو null للإزاحات الكسرية النادرة بلا timezoneId
  /// City zone: real IANA id, a fixed-offset Etc/GMT zone (POSIX sign flip:
  /// Etc/GMT-3 == UTC+3) for manual cities without one, or null for the rare
  /// fractional-offset case without a timezoneId
  tz.Location? _zoneOrNull(City city) {
    final String? tzId = city.timezoneId;
    if (tzId != null && tzId.isNotEmpty) {
      try {
        return tz.getLocation(tzId);
      } catch (_) {}
    }
    final double hours = city.timezoneOffsetHours;
    if (hours == hours.roundToDouble()) {
      final int h = hours.round();
      try {
        return tz.getLocation('Etc/GMT${h <= 0 ? '+' : '-'}${h.abs()}');
      } catch (_) {}
    }
    return null;
  }

  /// منطقة المدينة — صالحة دائماً (Etc/UTC كملاذ أخير)
  /// City zone — always valid (Etc/UTC as last resort)
  tz.Location _locationFor(City city) {
    _ensureTzInitialized();
    return _zoneOrNull(city) ?? tz.getLocation('Etc/UTC');
  }

  @override
  DateTime cityNow(City city) {
    _ensureTzInitialized();
    final tz.Location? zone = _zoneOrNull(city);
    if (zone != null) return tz.TZDateTime.now(zone);
    // إزاحة كسرية بلا timezoneId: UTC الآن مزاحاً يدوياً
    // Fractional offset without tzid: manually shifted UTC now
    return DateTime.now().toUtc().add(
      Duration(minutes: (city.timezoneOffsetHours * 60).round()),
    );
  }

  @override
  Duration timeUntilCityMidnight(City city) {
    _ensureTzInitialized();
    final tz.Location? zone = _zoneOrNull(city);
    if (zone != null) {
      final tz.TZDateTime now = tz.TZDateTime.now(zone);
      // منتصف الليل القادم بتقويم المدينة (آمن مع DST — لا +24 ساعة)
      // Next midnight on the city's calendar (DST-safe — not +24h)
      final tz.TZDateTime midnight = tz.TZDateTime(
        zone,
        now.year,
        now.month,
        now.day + 1,
      );
      return midnight.difference(now);
    }
    final DateTime now = DateTime.now().toUtc().add(
      Duration(minutes: (city.timezoneOffsetHours * 60).round()),
    );
    return DateTime.utc(now.year, now.month, now.day + 1).difference(now);
  }

  /// الإزاحة الفعلية للمدينة في التاريخ المطلوب — تدعم DST تلقائياً
  /// Effective offset for the city on the given date — DST-aware
  Duration _effectiveOffset(City city, DateTime date) {
    _ensureTzInitialized();
    final String? tzId = city.timezoneId;
    if (tzId == null || tzId.isEmpty) {
      return Duration(minutes: (city.timezoneOffsetHours * 60).round());
    }
    try {
      final tz.Location location = tz.getLocation(tzId);
      // منتصف الظهر بتاريخ المدينة — نقطة تمثيل دقيقة للإزاحة اليومية
      // Local noon on that date — accurate representative instant
      final DateTime localNoon = DateTime(date.year, date.month, date.day, 12);
      final int offsetMinutes = tz.TZDateTime.from(
        localNoon,
        location,
      ).timeZoneOffset.inMinutes;
      return Duration(minutes: offsetMinutes);
    } catch (e) {
      // معرف غير معروف → الإزاحة الاحتياطية / unknown id → fallback
      _debugLog('Hirz: timezone lookup failed for "$tzId": $e');
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
        final CalculationMethod? parsed = _methodById[cityMethod];
        if (parsed != null) return parsed;
      }
      return CalculationMethod.ummAlQura; // احتياط معقول / sane fallback
    }
    return settings.method;
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
