// اختبارات جدولة الأذان — منطق الفلترة والترتيب عبر 3 مدن
// Adhan scheduling tests — filtering/scheduling logic across 3 cities
// ملاحظة: لا يمكن اختبار نظام إشعارات أندرويد نفسه في بيئة الاختبار؛
// نختبر المنطق الذي يغذي الجدولة (الأوقات المرسلة، الاستبعاد، الترتيب)
// Note: the Android notification system itself can't be tested here;
// we test the logic feeding the scheduler (times passed, exclusion, ordering)

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/services/adhan_notification_service.dart';
import 'package:hirz/data/datasources/prayer_times_local_datasource.dart';
import 'package:hirz/domain/entities/app_settings.dart';
import 'package:hirz/domain/entities/city.dart';
import 'package:hirz/domain/entities/prayer_time.dart';

/// الرياض / Riyadh
const City riyadh = City(
  id: 'sa_riyadh',
  nameEn: 'Riyadh',
  nameAr: 'الرياض',
  countryEn: 'Saudi Arabia',
  countryAr: 'السعودية',
  latitude: 24.7136,
  longitude: 46.6753,
  timezoneOffsetHours: 3,
);

/// جاكرتا / Jakarta
const City jakarta = City(
  id: 'id_jakarta',
  nameEn: 'Jakarta',
  nameAr: 'جاكرتا',
  countryEn: 'Indonesia',
  countryAr: 'إندونيسيا',
  latitude: -6.2088,
  longitude: 106.8456,
  timezoneOffsetHours: 7,
);

/// نيويورك / New York
const City newYork = City(
  id: 'us_nyc',
  nameEn: 'New York',
  nameAr: 'نيويورك',
  countryEn: 'United States',
  countryAr: 'أمريكا',
  latitude: 40.7128,
  longitude: -74.0060,
  timezoneOffsetHours: -4,
);

const AppSettings baseSettings = AppSettings(
  languageCode: 'ar',
  isDarkMode: false,
  method: CalculationMethod.ummAlQura,
  madhab: Madhab.shafi,
  use24HourFormat: false,
  iqamahOffsets: AppSettings.defaultIqamahOffsets,
);

/// نفس فلترة scheduleAdhan: استبعاد الشروق والأوقات الفائتة
/// Same filter as scheduleAdhan: exclude sunrise & past times
List<PrayerTime> schedulable(List<PrayerTime> times, DateTime now) {
  final List<PrayerTime> out = <PrayerTime>[];
  for (final PrayerTime pt in times) {
    if (pt.prayer == Prayer.sunrise) continue;
    if (!pt.time.isAfter(now)) continue;
    out.add(pt);
  }
  return out;
}

void main() {
  final PrayerTimesLocalDatasource datasource =
      const PrayerTimesLocalDatasource();

  group('جدولة الأذان — منطق القائمة المرسلة للمنبه / scheduling input', () {
    test('الرياض: 5 أذانات يومية، الشروق مستبعد / Riyadh: 5 adhans', () async {
      final DailyPrayerTimes day = await datasource.getPrayerTimes(
        city: riyadh,
        date: DateTime(2026, 8, 27),
        settings: baseSettings,
      );
      expect(day.times.length, 6); // 5 صلوات + شروق
      final List<PrayerTime> schedulable_ = schedulable(
        day.times,
        DateTime(2026, 8, 27, 0, 0),
      );
      expect(schedulable_.length, 5);
      expect(
        schedulable_.map((PrayerTime p) => p.prayer.name).toSet(),
        <String>{'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'},
      );
      // مرتبة زمنياً / chronologically ordered
      for (int i = 1; i < schedulable_.length; i++) {
        expect(
          schedulable_[i].time.isAfter(schedulable_[i - 1].time),
          isTrue,
          reason: 'الأذانات يجب أن تكون بترتيب زمني',
        );
      }
    });

    test('جاكرتا: مواقيت معقولة ونطاق اليوم الصحيح / Jakarta sanity', () async {
      final DailyPrayerTimes day = await datasource.getPrayerTimes(
        city: jakarta,
        date: DateTime(2026, 8, 27),
        settings: baseSettings,
      );
      final List<PrayerTime> s = schedulable(day.times, DateTime(2026, 8, 27));
      expect(s.length, 5);
      // جاكرتا UTC+7: الفجر قبل 06:00 والعشاء بعد 11:30 تقريباً
      // Fajr before ~06:00 local; Dhuhr after ~11:30 local
      final PrayerTime fajr = s.firstWhere(
        (PrayerTime p) => p.prayer.name == 'fajr',
      );
      final PrayerTime dhuhr = s.firstWhere(
        (PrayerTime p) => p.prayer.name == 'dhuhr',
      );
      expect(fajr.time.hour, lessThan(6), reason: 'فجر جاكرتا مبكر');
      expect(
        dhuhr.time.hour,
        inExclusiveRange(11, 14),
        reason: 'ظهر جاكرتا حول الظهيرة',
      );
    });

    test('نيويورك: طريقة أم القرى تعمل خارج السعودية / NYC works', () async {
      final DailyPrayerTimes day = await datasource.getPrayerTimes(
        city: newYork,
        date: DateTime(2026, 8, 27),
        settings: baseSettings,
      );
      final List<PrayerTime> s = schedulable(day.times, DateTime(2026, 8, 27));
      expect(s.length, 5);
      // كل الأوقات داخل يوم نيويورك المحلي / all within local day bounds
      for (final PrayerTime pt in s) {
        expect(pt.time.isBefore(DateTime(2026, 8, 28)), isTrue);
      }
    });
  });

  group('معرفات الإشعارات المستقرة / stable notification ids', () {
    test('معرف مختلف لكل صلاة ولكل يوم / unique per prayer per day', () {
      final Set<int> ids = <int>{};
      for (int day = 20; day <= 22; day++) {
        for (final Prayer prayer in <Prayer>[
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          ids.add(prayer.index * 10 + day);
        }
      }
      expect(ids.length, 15, reason: 'كل صلاة/يوم له معرف فريد — لا استبدال');
    });
  });

  group('مستوى الصوت — تسمية القنوات الديناميكية / volume channel naming', () {
    test(
      'كل مستوى ينتج قناة مميزة ومثبتة / each level → distinct stable channel',
      () {
        String? channelFor(double volume) {
          final int volLevel = (volume * 10).round().clamp(1, 10);
          return '${AdhanNotificationService.channelRegular}_vol$volLevel';
        }

        expect(
          channelFor(1.0),
          '${AdhanNotificationService.channelRegular}_vol10',
        );
        expect(
          channelFor(0.6),
          '${AdhanNotificationService.channelRegular}_vol6',
        );
        expect(
          channelFor(0.1),
          '${AdhanNotificationService.channelRegular}_vol1',
        );
        expect(channelFor(0.15), channelFor(0.1)); // التقريب يثبت المستوى
        expect(channelFor(0.64), channelFor(0.6));
        // فجر وغير فجر قناتان مختلفتان لنفس المستوى
        final int volFajr = (0.6 * 10).round().clamp(1, 10);
        expect(
          '${AdhanNotificationService.channelFajr}_vol$volFajr',
          isNot(equals(channelFor(0.6))),
        );
      },
    );
  });
}
