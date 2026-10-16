// اختبارات انحدار لإصلاحات تدقيق 2026-10-16
// Regression tests for the 2026-10-16 audit fixes

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:hirz/core/utils/format_utils.dart';
import 'package:hirz/data/datasources/prayer_times_local_datasource.dart';
import 'package:hirz/data/datasources/settings_local_datasource.dart';
import 'package:hirz/domain/entities/app_settings.dart';
import 'package:hirz/domain/entities/city.dart';
import 'package:hirz/domain/entities/prayer_time.dart';
import 'package:hirz/domain/usecases/get_prayer_times_flow.dart';

City _city({
  String id = 'audit_city',
  double lat = 21.42,
  double lon = 39.82,
  double offset = 3,
  String? tzId,
}) {
  return City(
    id: id,
    nameEn: 'Test',
    nameAr: 'اختبار',
    countryEn: 'Test',
    countryAr: 'اختبار',
    latitude: lat,
    longitude: lon,
    timezoneOffsetHours: offset,
    timezoneId: tzId,
    isCustom: tzId == null,
  );
}

AppSettings _settings() => AppSettings(
  languageCode: 'ar',
  isDarkMode: false,
  method: CalculationMethod.muslimWorldLeague,
  madhab: Madhab.shafi,
  use24HourFormat: true,
  iqamahOffsets: AppSettings.defaultIqamahOffsets,
);

void main() {
  group('normalizeArabicSearch — تطبيع البحث العربي', () {
    test('الهمزات والألف تُوحَّد', () {
      expect(normalizeArabicSearch('إسطنبول'), 'اسطنبول');
      expect(normalizeArabicSearch('أحمد'), 'احمد');
      expect(normalizeArabicSearch('آسيا'), 'اسيا');
    });

    test('التاء المربوطة والألف المقصورة', () {
      expect(normalizeArabicSearch('القاهرة'), 'القاهره');
      expect(normalizeArabicSearch('موسى'), 'موسي');
    });

    test('بحث "اسطنبول" يجد "إسطنبول" بعد التطبيع', () {
      final String q = normalizeArabicSearch('اسطنبول');
      expect(normalizeArabicSearch('إسطنبول').contains(q), isTrue);
    });

    test('النص اللاتيني لا يتأثر', () {
      expect(normalizeArabicSearch('London'), 'London');
    });
  });

  group('normalizeNumericInput — أرقام لوحة المفاتيح العربية', () {
    test('أرقام عربية مشرقية وفاصلة عربية', () {
      expect(normalizeNumericInput('٢٤٫٥'), '24.5');
      expect(normalizeNumericInput('-٣٫٥'), '-3.5');
    });

    test('أرقام فارسية/أردية', () {
      expect(normalizeNumericInput('۱۲۳'), '123');
    });

    test('مدخل لاتيني لا يتغير', () {
      expect(normalizeNumericInput('5.75'), '5.75');
      expect(normalizeNumericInput('-12'), '-12');
    });

    test('الناتج يقبله double.tryParse', () {
      expect(double.tryParse(normalizeNumericInput('٢٤٫٥')), 24.5);
      expect(double.tryParse(normalizeNumericInput('٥٫٧٥')), 5.75);
    });
  });

  group('cityUtcOffsetNow — إزاحة DST الحالية', () {
    const PrayerTimesLocalDatasource ds = PrayerTimesLocalDatasource();

    test('مدينة يدوية بلا tzid → الإزاحة الثابتة', () {
      final City manual = _city(offset: 5.75);
      expect(ds.cityUtcOffsetNow(manual), const Duration(hours: 5, minutes: 45));
    });

    test('لندن: الإزاحة من المنطقة لا من الحقل الثابت', () {
      // القيمة المخزنة 0 (توقيت قياسي) — أثناء BST يجب أن تكون +1
      // هذا الاختبار يفشل على الكود القديم الذي كان يعرض الحقل الثابت
      final City london = _city(id: 'uk_london', offset: 0, tzId: 'Europe/London');
      final Duration expected = tz.TZDateTime.now(
        tz.getLocation('Europe/London'),
      ).timeZoneOffset;
      expect(ds.cityUtcOffsetNow(london), expected);
      // والأهم: ليست القيمة الثابتة أثناء التوقيت الصيفي
      if (expected.inMinutes != 0) {
        expect(ds.cityUtcOffsetNow(london).inMinutes, isNot(0));
      }
    });
  });

  group('M1 — اتساق "الآن" للمدن الكسرية بلا tzid', () {
    const PrayerTimesLocalDatasource ds = PrayerTimesLocalDatasource();
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(ds);

    test('cityNow يعيد حقول ساعة المدينة للإزاحة الكسرية', () {
      // كاتماندو +5:45 بلا timezoneId
      final City kathmandu = _city(id: 'np_ktm', lat: 27.7, lon: 85.3, offset: 5.75);
      final DateTime now = flow.cityNow(kathmandu);
      final DateTime expectedFields = DateTime.now().toUtc().add(
        const Duration(hours: 5, minutes: 45),
      );
      // الحقول (بتسامح دقيقة واحدة لعبور الدقيقة أثناء الاختبار)
      expect(
        (now.hour * 60 + now.minute - (expectedFields.hour * 60 + expectedFields.minute)).abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('nextPrayer(cityNow) معقول — الباقي ضمن 24 ساعة وغير سالب', () async {
      final City kathmandu = _city(id: 'np_ktm', lat: 27.7, lon: 85.3, offset: 5.75);
      final DateTime now = flow.cityNow(kathmandu);
      final DailyPrayerTimes daily = await ds.getPrayerTimes(
        city: kathmandu,
        date: now,
        settings: _settings(),
      );
      final PrayerTime? next = daily.nextPrayer(now);
      if (next != null) {
        final Duration remaining = next.time.difference(now);
        expect(remaining.isNegative, isFalse);
        expect(remaining.inHours, lessThan(24));
      } else {
        // بعد العشاء: فجر الغد خلال 24 ساعة
        final DailyPrayerTimes tomorrow = await flow.tomorrow(
          city: kathmandu,
          settings: _settings(),
          now: now,
        );
        final Duration remaining = tomorrow.times.first.time.difference(now);
        expect(remaining.isNegative, isFalse);
        expect(remaining.inHours, lessThan(24));
      }
    });
  });

  group('M5 — تعقيم languageCode', () {
    Future<SettingsLocalDatasource> dsWith(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      return SettingsLocalDatasource(await SharedPreferences.getInstance());
    }

    test('قيمة فاسدة → عربية', () async {
      final SettingsLocalDatasource ds = await dsWith(
        <String, Object>{'language_code': 'fr'},
      );
      expect(ds.load().languageCode, 'ar');
    });

    test('قيمة صالحة تُحفظ', () async {
      final SettingsLocalDatasource ds = await dsWith(
        <String, Object>{'language_code': 'en'},
      );
      expect(ds.load().languageCode, 'en');
    });
  });
}
