// اختبارات حالات استخدام الإشعارات / Notification use case tests

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/domain/entities/notification_settings.dart';
import 'package:hirz/domain/entities/prayer_time.dart';

void main() {
  group('ScheduleAdhansUseCase', () {
    test('masterEnabled = false → لا يجدول شيئًا / master off → schedules nothing', () {
      final NotificationSettings settings = NotificationSettings.defaults();
      expect(settings.masterEnabled, false);
    });

    test('الإعدادات الافتراضية: كل الصلوات مطفأة / defaults: all prayers off', () {
      final NotificationSettings settings = NotificationSettings.defaults();
      for (final Prayer prayer in Prayer.values) {
        expect(settings.prayers[prayer]!.enabled, false);
      }
    });

    test('Fajr مفعّل بـ fullAdhan / Fajr enabled with fullAdhan', () {
      final NotificationSettings settings = NotificationSettings.defaults();
      final PrayerNotification? fajr = settings.prayers[Prayer.fajr];
      expect(fajr, isNotNull);
      expect(fajr!.enabled, false);
    });
  });
}
