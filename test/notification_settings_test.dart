// اختبارات كيان إعدادات الإشعارات / Notification settings entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/domain/entities/notification_settings.dart';
import 'package:hirz/domain/entities/prayer_time.dart';

void main() {
  group('PrayerNotification', () {
    test('تخزين وتحميل من النص / store and load from string', () {
      const PrayerNotification pn = PrayerNotification(
        enabled: true,
        type: AlertType.fullAdhan,
      );
      final String stored = pn.storeKey();
      expect(stored, '1_fullAdhan');

      final PrayerNotification loaded = PrayerNotification.load(stored);
      expect(loaded.enabled, true);
      expect(loaded.type, AlertType.fullAdhan);
    });

    test('تحميل قيمة غير صالحة يعود للافتراضي / invalid load defaults', () {
      final PrayerNotification loaded = PrayerNotification.load('invalid');
      expect(loaded.enabled, true); // fallback
      expect(loaded.type, AlertType.shortTone);
    });

    test('copyWith يعيد نسخة محدّثة / copyWith returns updated copy', () {
      const PrayerNotification original = PrayerNotification(
        enabled: false,
        type: AlertType.shortTone,
      );
      final PrayerNotification updated = original.copyWith(enabled: true);
      expect(updated.enabled, true);
      expect(updated.type, AlertType.shortTone);
    });
  });

  group('NotificationSettings.defaults()', () {
    test('تُنشئ كل الصلوات مطفأة / all prayers disabled', () {
      final NotificationSettings s = NotificationSettings.defaults();
      expect(s.masterEnabled, false);
      expect(s.iqamahEnabled, false);
      expect(s.prayers.length, Prayer.values.length);
      for (final Prayer prayer in Prayer.values) {
        expect(s.prayers[prayer]!.enabled, false);
      }
    });
  });

  group('NotificationSettings.copyWith()', () {
    test('تحديث masterEnabled فقط / updates master only', () {
      final NotificationSettings original = NotificationSettings.defaults();
      final NotificationSettings updated = original.copyWith(
        masterEnabled: true,
      );
      expect(updated.masterEnabled, true);
      expect(updated.iqamahEnabled, false);
      expect(updated.prayers.length, original.prayers.length);
    });
  });
}
