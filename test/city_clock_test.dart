// اختبارات ساعة المدينة / City-clock tests
// cityNow و timeUntilCityMidnight في PrayerTimesLocalDatasource

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:hirz/data/datasources/prayer_times_local_datasource.dart';
import 'package:hirz/domain/entities/city.dart';

City _city({
  String? timezoneId,
  required double offsetHours,
  double lat = 21.4,
  double lon = 39.8,
}) => City(
  id: 'test',
  nameEn: 'Test',
  nameAr: 'اختبار',
  countryEn: '',
  countryAr: '',
  latitude: lat,
  longitude: lon,
  timezoneOffsetHours: offsetHours,
  timezoneId: timezoneId,
);

void main() {
  tzdata.initializeTimeZones();
  const PrayerTimesLocalDatasource ds = PrayerTimesLocalDatasource();

  test('cityNow يعيد "الآن" بتوقيت المدينة لا الجهاز', () {
    final City ny = _city(timezoneId: 'America/New_York', offsetHours: -5);
    final DateTime actual = ds.cityNow(ny);
    final tz.TZDateTime expected = tz.TZDateTime.now(
      tz.getLocation('America/New_York'),
    );

    expect(actual.timeZoneName, expected.timeZoneName);
    expect(actual.timeZoneOffset, expected.timeZoneOffset);
  });

  test('cityNow لمدينة بلا timezoneId: منطقة Etc/GMT بالإزاحة الصحيحة', () {
    // +3 بلا tzid → Etc/GMT-3 (عكس إشارة POSIX) == UTC+3
    final City manual = _city(timezoneId: null, offsetHours: 3);
    final DateTime now = ds.cityNow(manual);

    expect(now.timeZoneOffset, const Duration(hours: 3));
  });

  test('cityNow لإزاحة سالبة بلا timezoneId', () {
    final City manual = _city(timezoneId: null, offsetHours: -5);
    final DateTime now = ds.cityNow(manual);

    expect(now.timeZoneOffset, const Duration(hours: -5));
  });

  test('cityNow لإزاحة كسرية بلا timezoneId: UTC مزاح يدوياً', () {
    final City manual = _city(timezoneId: null, offsetHours: 5.5);
    final DateTime now = ds.cityNow(manual);
    final DateTime utcNow = DateTime.now().toUtc();

    // الفرق عن UTC الآن ≈ 5:30 (بهامش دقيقة لزمن التنفيذ)
    final Duration diff = now.difference(utcNow).abs();
    expect(diff.inMinutes, greaterThanOrEqualTo(329));
    expect(diff.inMinutes, lessThanOrEqualTo(331));
  });

  test('timeUntilCityMidnight موجب وأقل من 26 ساعة لعدة مدن', () {
    final List<City> cities = <City>[
      _city(timezoneId: 'Asia/Riyadh', offsetHours: 3),
      _city(timezoneId: 'America/New_York', offsetHours: -5),
      _city(timezoneId: 'Pacific/Auckland', offsetHours: 12),
      _city(timezoneId: null, offsetHours: 3),
    ];
    for (final City city in cities) {
      final Duration wait = ds.timeUntilCityMidnight(city);
      expect(
        wait > Duration.zero,
        isTrue,
        reason: '${city.timezoneId} should be positive',
      );
      expect(
        wait < const Duration(hours: 26),
        isTrue,
        reason: '${city.timezoneId} should be under 26h',
      );
    }
  });

  test('timeUntilCityMidnight يصل فعلاً لمنتصف الليل بتوقيت المدينة', () {
    final City ny = _city(timezoneId: 'America/New_York', offsetHours: -5);
    final tz.Location loc = tz.getLocation('America/New_York');
    final tz.TZDateTime tznow = tz.TZDateTime.now(loc);
    final tz.TZDateTime expectedMidnight = tz.TZDateTime(
      loc,
      tznow.year,
      tznow.month,
      tznow.day + 1,
    );

    final DateTime at = ds.cityNow(ny).add(ds.timeUntilCityMidnight(ny));
    // يصل قبل منتصف الليل بثوانٍ (سباق ms بين استدعائي now)
    // Lands seconds before midnight (ms race between the two now() calls)
    final Duration gap = expectedMidnight.difference(at);
    expect(gap >= Duration.zero, isTrue);
    expect(gap < const Duration(seconds: 10), isTrue);
  });
}
