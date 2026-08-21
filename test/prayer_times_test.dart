// اختبارات حساب المواقيت / Prayer times computation tests
// ملاحظة: هذه الاختبارات تتطلب adhan — تعمل في CI فقط
// Note: these tests require adhan — they run in CI only

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/data/datasources/prayer_times_local_datasource.dart';
import 'package:hirz/domain/entities/app_settings.dart';
import 'package:hirz/domain/entities/city.dart';
import 'package:hirz/domain/entities/prayer_time.dart';

/// مكة المكرمة / Makkah
const City makkah = City(
  id: 'sa_makkah',
  nameEn: 'Makkah',
  nameAr: 'مكة المكرمة',
  countryEn: 'Saudi Arabia',
  countryAr: 'السعودية',
  latitude: 21.4225,
  longitude: 39.8262,
  timezoneOffsetHours: 3,
);

/// القاهرة / Cairo
const City cairo = City(
  id: 'eg_cairo',
  nameEn: 'Cairo',
  nameAr: 'القاهرة',
  countryEn: 'Egypt',
  countryAr: 'مصر',
  latitude: 30.0444,
  longitude: 31.2357,
  timezoneOffsetHours: 2,
);

/// لندن / London
const City london = City(
  id: 'gb_london',
  nameEn: 'London',
  nameAr: 'لندن',
  countryEn: 'United Kingdom',
  countryAr: 'بريطانيا',
  latitude: 51.5074,
  longitude: -0.1278,
  timezoneOffsetHours: 0,
);

/// أوسلو (خط عرض عليا) / Oslo (high latitude)
const City oslo = City(
  id: 'no_oslo',
  nameEn: 'Oslo',
  nameAr: 'أوسلو',
  countryEn: 'Norway',
  countryAr: 'النرويج',
  latitude: 59.9139,
  longitude: 10.7522,
  timezoneOffsetHours: 1,
);

const AppSettings defaultSettings = AppSettings(
  languageCode: 'ar',
  isDarkMode: false,
  method: CalculationMethod.ummAlQura,
  madhab: Madhab.shafi,
  use24HourFormat: false,
  iqamahOffsets: AppSettings.defaultIqamahOffsets,
);

void main() {
  late PrayerTimesLocalDatasource datasource;

  setUp(() {
    datasource = const PrayerTimesLocalDatasource();
  });

  group('ترتيب الأوقات / Time ordering', () {
    test('مكة 2026-01-15: الفجر < الشروق < الظهر < العصر < المغرب < العشاء', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: makkah,
        date: DateTime(2026, 1, 15),
        settings: defaultSettings,
      );
      expect(times.times.length, 6);
      for (int i = 0; i < times.times.length - 1; i++) {
        expect(
          times.times[i].time.isBefore(times.times[i + 1].time),
          isTrue,
          reason: '${times.times[i].prayer} should be before ${times.times[i + 1].prayer}',
        );
      }
    });

    test('القاهرة 2026-01-15: ترتيب صحيح', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: cairo,
        date: DateTime(2026, 1, 15),
        settings: defaultSettings,
      );
      for (int i = 0; i < times.times.length - 1; i++) {
        expect(times.times[i].time.isBefore(times.times[i + 1].time), isTrue);
      }
    });

    test('لندن 2026-01-15: ترتيب صحيح', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: london,
        date: DateTime(2026, 1, 15),
        settings: defaultSettings,
      );
      for (int i = 0; i < times.times.length - 1; i++) {
        expect(times.times[i].time.isBefore(times.times[i + 1].time), isTrue);
      }
    });
  });

  group('الإقامة = الأذان + الفرق / Iqamah = Adhan + offset', () {
    test('الفجر: +20 دقيقة', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: makkah,
        date: DateTime(2026, 1, 15),
        settings: defaultSettings,
      );
      final PrayerTime fajr = times.times.first;
      final Duration diff = fajr.iqamahTime.difference(fajr.time);
      expect(diff.inMinutes, 20);
    });

    test('المغرب: +10 دقائق', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: makkah,
        date: DateTime(2026, 1, 15),
        settings: defaultSettings,
      );
      final PrayerTime maghrib = times.times[4];
      final Duration diff = maghrib.iqamahTime.difference(maghrib.time);
      expect(diff.inMinutes, 10);
    });
  });

  group('خطوط العرض العليا / High latitudes', () {
    test('أوسلو لا ترمي استثناء', () async {
      final DailyPrayerTimes times = await datasource.getPrayerTimes(
        city: oslo,
        date: DateTime(2026, 6, 21), // منتصف الصيف
        settings: defaultSettings,
      );
      expect(times.times.length, 6);
      // كل الأوقات يجب أن تكون صالحة
      for (final PrayerTime pt in times.times) {
        expect(pt.time.year, 2026);
      }
    });
  });
}