// اختبارات كيان المواقيت — الحالات الحرجة / Prayer entity tests — critical cases
// تغطي: nextPrayer بعد العشاء، حدود اليوم، currentPrayer
// Covers: nextPrayer after isha, day boundaries, currentPrayer

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/domain/entities/prayer_time.dart';

/// بناء يوم اختباري بأوقات ثابتة / Build a test day with fixed times
DailyPrayerTimes _day(DateTime date) {
  DateTime t(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
  PrayerTime p(Prayer prayer, int h, int m) => PrayerTime(
        prayer: prayer,
        time: t(h, m),
        iqamahTime: t(h, m).add(const Duration(minutes: 15)),
      );

  return DailyPrayerTimes(
    date: date,
    times: <PrayerTime>[
      p(Prayer.fajr, 5, 0),
      p(Prayer.sunrise, 6, 30),
      p(Prayer.dhuhr, 12, 30),
      p(Prayer.asr, 15, 45),
      p(Prayer.maghrib, 18, 0),
      p(Prayer.isha, 19, 30),
    ],
  );
}

void main() {
  final DateTime day = DateTime(2026, 8, 23);

  group('nextPrayer', () {
    test('قبل الفجر → الفجر', () {
      final PrayerTime? next =
          _day(day).nextPrayer(DateTime(day.year, day.month, day.day, 4, 59));
      expect(next?.prayer, Prayer.fajr);
    });

    test('بين الشروق والظهر → الظهر', () {
      // الحالة التي كانت تكسر المؤقت (8:37 ص بعد شروق 6:04)
      // The exact case that broke the countdown (8:37am after 6:04 sunrise)
      final PrayerTime? next =
          _day(day).nextPrayer(DateTime(day.year, day.month, day.day, 8, 37));
      expect(next?.prayer, Prayer.dhuhr);
    });

    test('بعد العشاء → null (العدّاد يتحول لفجر الغد)', () {
      // عاد العشاء تماماً / right after isha begins
      final PrayerTime? next =
          _day(day).nextPrayer(DateTime(day.year, day.month, day.day, 19, 31));
      expect(next, isNull);
    });

    test('عند وقت الصلاة بالضبط → الصلاة التالية', () {
      // عند الظهر 12:30:00 حرفياً → ليس الظهر (isAfter صارم)
      final PrayerTime? next =
          _day(day).nextPrayer(DateTime(day.year, day.month, day.day, 12, 30));
      expect(next?.prayer, Prayer.asr);
    });
  });

  group('currentPrayer', () {
    test('بعد العشاء → العشاء', () {
      final PrayerTime? cur =
          _day(day).currentPrayer(DateTime(day.year, day.month, day.day, 21, 0));
      expect(cur?.prayer, Prayer.isha);
    });

    test('قبل الفجر → null', () {
      final PrayerTime? cur =
          _day(day).currentPrayer(DateTime(day.year, day.month, day.day, 3, 0));
      expect(cur, isNull);
    });
  });

  group('iqamah', () {
    test('الإقامة = الأذان + 15 دقيقة', () {
      final DailyPrayerTimes d = _day(day);
      final PrayerTime maghrib = d.times.firstWhere(
        (PrayerTime pt) => pt.prayer == Prayer.maghrib,
      );
      expect(
        maghrib.iqamahTime.difference(maghrib.time),
        const Duration(minutes: 15),
      );
    });
  });
}
