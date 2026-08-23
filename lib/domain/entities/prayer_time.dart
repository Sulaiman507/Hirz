// كيانات مواقيت الصلاة — Prayer time entities (pure Dart, dart:core only)

/// الصلوات اليومية بالترتيب / The daily prayers in order
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// وقت صلاة واحدة: الأذان والإقامة / Single prayer: adhan and iqamah times
class PrayerTime {
  final Prayer prayer;
  final DateTime time; // وقت الأذان / Adhan time
  final DateTime iqamahTime; // وقت الإقامة / Iqamah time

  const PrayerTime({
    required this.prayer,
    required this.time,
    required this.iqamahTime,
  });
}

/// مواقيت يوم كامل مرتبة من الفجر إلى العشاء / Full day schedule, fajr to isha
class DailyPrayerTimes {
  final DateTime date;
  final List<PrayerTime> times; // مرتبة: فجر..عشاء / Ordered: fajr..isha

  const DailyPrayerTimes({required this.date, required this.times});

  /// أول صلاة وقتها بعد الآن، أو null إن انتهت صلوات اليوم
  /// First prayer whose time is after [now], or null if the day is over
  PrayerTime? nextPrayer(DateTime now) {
    for (final prayerTime in times) {
      if (prayerTime.time.isAfter(now)) return prayerTime;
    }
    return null;
  }

  /// آخر صلاة دخل وقتها، وقبل الفجر تكون العشاء (آخر أمس) — الشارة لا تختفي
  /// Last prayer begun; before fajr that is yesterday's isha — badge never vanishes
  PrayerTime? currentPrayer(DateTime now) {
    PrayerTime? current;
    bool found = false;
    for (final prayerTime in times) {
      if (!found && prayerTime.time.isAfter(now)) {
        // لم تبدأ أي صلاة اليوم → العشاء (آخر صلاة أمس) هي الجارية
        // no prayer started today → isha (yesterday's last) is current
        return times.last;
      }
      found = true;
      if (prayerTime.time.isAfter(now)) break;
      current = prayerTime;
    }
    return current ?? times.last;
  }
}