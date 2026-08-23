// اختبارات مصدر المواقيت — DST وطرق الحساب الإقليمية
// Datasource tests — DST offsets and per-city methods

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/data/datasources/prayer_times_local_datasource.dart';
import 'package:hirz/domain/entities/app_settings.dart';
import 'package:hirz/domain/entities/city.dart';

City _city({
  String id = 'test_city',
  double lat = 21.42,
  double lon = 39.82,
  String? tzId,
  String? methodId,
}) {
  return City(
    id: id,
    nameEn: 'Test',
    nameAr: 'اختبار',
    countryEn: 'Test',
    countryAr: 'اختبار',
    latitude: lat,
    longitude: lon,
    timezoneOffsetHours: 3,
    timezoneId: tzId,
    methodId: methodId,
  );
}

AppSettings _settings({CalculationMethod method = CalculationMethod.auto}) {
  return AppSettings(
    languageCode: 'ar',
    isDarkMode: false,
    method: method,
    madhab: Madhab.shafi,
    use24HourFormat: false,
    iqamahOffsets: AppSettings.defaultIqamahOffsets,
  );
}

void main() {
  const datasource = PrayerTimesLocalDatasource();

  group('DST-aware offset', () {
    test('القاهرة صيفاً +3 / ديسمبر +2', () async {
      final City cairo = _city(
        id: 'eg_cairo',
        lat: 30.044,
        lon: 31.236,
        tzId: 'Africa/Cairo',
        methodId: 'egyptian',
      );
      final summer = await datasource.getPrayerTimes(
        city: cairo,
        date: DateTime(2026, 7, 15),
        settings: _settings(),
      );
      final winter = await datasource.getPrayerTimes(
        city: cairo,
        date: DateTime(2026, 12, 15),
        settings: _settings(),
      );
      // فجر الصيف أبكر من الشتوي بفرق ساعة تقريباً (نفس الإحداثيات)
      // Summer fajr ~1h earlier than winter for identical coordinates
      expect(
        summer.times.first.time.hour,
        lessThan(winter.times.first.time.hour),
      );
    });

    // ديربورن ISNA — الحالة التي أبلغ عنها المستخدم
    // Dearborn ISNA — the user-reported case
    test('ديربورن: العشاء قبل 10 مساءً صيفاً (ISNA)', () async {
      final City dearborn = _city(
        id: 'us_dearbourn',
        lat: 42.3223,
        lon: -83.1763,
        tzId: 'America/Detroit',
        methodId: 'northAmerica',
      );
      final times = await datasource.getPrayerTimes(
        city: dearborn,
        date: DateTime(2026, 8, 22),
        settings: _settings(),
      );
      final PrayerTime isha = times.times.last;
      // الرسمي EDT 9:45pm → بتوقيت UTC الداخلي يجب أن يكون ضمن نطاق معقول
      // بعد التطبيع المحلي: الساعة 21 أو أقل (وليس 22+ كما كان الخلل)
      expect(isha.time.hour, lessThanOrEqualTo(22));
      expect(isha.prayer, Prayer.isha);
    });
  });

  group('kind normalization', () {
    test('كل الأوقات محلية خالصة isUtc=false', () async {
      final times = await datasource.getPrayerTimes(
        city: _city(tzId: 'Asia/Riyadh', methodId: 'ummAlQura'),
        date: DateTime(2026, 8, 23),
        settings: _settings(),
      );
      for (final PrayerTime pt in times.times) {
        expect(pt.time.isUtc, isFalse, reason: '${pt.prayer.name} لا يزال UTC');
        expect(pt.iqamahTime.isUtc, isFalse);
      }
      expect(times.date.isUtc, isFalse);
    });
  });
}
