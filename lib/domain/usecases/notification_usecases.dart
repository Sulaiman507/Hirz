// حالات استخدام الإشعارات / Notification use cases
// تفصل منطق الجدولة عن الـ provider

import 'package:timezone/timezone.dart' as tz;

import '../../core/services/adhan_notification_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/prayer_time.dart';

/// نتيجة الجدولة / scheduling result
class ScheduleResult {
  final int scheduled;
  final int failed;
  final bool exactAlarmGranted;

  const ScheduleResult({
    required this.scheduled,
    required this.failed,
    required this.exactAlarmGranted,
  });
}

/// جدولة أذانات أسبوع كامل / Schedule a full week of adhans
class ScheduleAdhansUseCase {
  final AdhanNotificationService _service;

  ScheduleAdhansUseCase(this._service);

  Future<ScheduleResult> call({
    required List<PrayerTime> times,
    required NotificationSettings settings,
    required Map<String, int> iqamahOffsets,
    required String? timezoneId,
  }) async {
    if (!settings.masterEnabled) {
      await _service.cancelAll();
      return const ScheduleResult(
        scheduled: 0,
        failed: 0,
        exactAlarmGranted: false,
      );
    }

    await _service.cancelAll();

    final bool? exactGranted = await _service.canScheduleExact();
    final tz.Location location = timezoneId != null && timezoneId.isNotEmpty
        ? tz.getLocation(timezoneId)
        : tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);

    int scheduled = 0;
    int failed = 0;

    for (final PrayerTime pt in times) {
      if (pt.prayer == Prayer.sunrise) continue;
      final tz.TZDateTime when = tz.TZDateTime.from(pt.time, location);
      if (!when.isAfter(now)) continue;

      final PrayerNotification? pn = settings.prayers[pt.prayer];
      if (pn == null || !pn.enabled) continue;

      // معرف مستقر: صلاة + تاريخ / stable id: prayer + date
      final int id = pt.prayer.index * 100000 +
          when.year * 400 +
          when.month * 31 +
          when.day;

      try {
        await _service.scheduleAdhan(
          id: id,
          prayerName: pt.prayer.name,
          when: when,
          isFajr: pt.prayer == Prayer.fajr,
          alertType: pn.type,
        );
        scheduled++;
      } catch (_) {
        failed++;
      }

      // الإقامة اختيارية / iqamah is optional
      if (settings.iqamahEnabled) {
        final int offsetMin = iqamahOffsets[pt.prayer.name] ?? 15;
        final tz.TZDateTime iqamahWhen = when.add(
          Duration(minutes: offsetMin),
        );
        if (iqamahWhen.isAfter(now)) {
          try {
            await _service.scheduleIqamah(
              id: id + 500000,
              prayerName: pt.prayer.name,
              when: iqamahWhen,
            );
            scheduled++;
          } catch (_) {
            failed++;
          }
        }
      }
    }

    return ScheduleResult(
      scheduled: scheduled,
      failed: failed,
      exactAlarmGranted: exactGranted ?? false,
    );
  }
}

/// إلغاء جميع الإشعارات / Cancel all notifications
class CancelNotificationsUseCase {
  final AdhanNotificationService _service;

  CancelNotificationsUseCase(this._service);

  Future<void> call() => _service.cancelAll();
}
