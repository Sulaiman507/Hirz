// اختبارات مصدر بيانات الإشعارات / Notification datasource tests

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/data/datasources/settings_local_datasource.dart';
import 'package:hirz/domain/entities/notification_settings.dart';
import 'package:hirz/domain/entities/prayer_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsLocalDatasource> _ds() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return SettingsLocalDatasource(await SharedPreferences.getInstance());
}

void main() {
  group('loadNotifications()', () {
    test('تخزين فارغ → إعدادات افتراضية / empty store → defaults', () async {
      final SettingsLocalDatasource ds = await _ds();
      final NotificationSettings s = ds.loadNotifications();
      expect(s.masterEnabled, false);
      expect(s.iqamahEnabled, false);
      expect(s.prayers.length, Prayer.values.length);
    });
  });

  group('saveNotifications → loadNotifications round-trip', () {
    test('حفظ واستعادة الإعدادات / save and restore', () async {
      final SettingsLocalDatasource ds = await _ds();

      final Map<Prayer, PrayerNotification> prayers =
          <Prayer, PrayerNotification>{};
      prayers[Prayer.fajr] = const PrayerNotification(
        enabled: true,
        type: AlertType.fullAdhan,
      );
      prayers[Prayer.dhuhr] = const PrayerNotification(
        enabled: true,
        type: AlertType.shortTone,
      );
      for (final Prayer p in Prayer.values) {
        prayers.putIfAbsent(
          p,
          () => const PrayerNotification(enabled: false),
        );
      }

      final NotificationSettings original = NotificationSettings(
        masterEnabled: true,
        iqamahEnabled: true,
        prayers: prayers,
      );

      await ds.saveNotifications(original);
      final NotificationSettings loaded = ds.loadNotifications();

      expect(loaded.masterEnabled, true);
      expect(loaded.iqamahEnabled, true);
      expect(loaded.prayers[Prayer.fajr]!.enabled, true);
      expect(loaded.prayers[Prayer.fajr]!.type, AlertType.fullAdhan);
      expect(loaded.prayers[Prayer.dhuhr]!.enabled, true);
      expect(loaded.prayers[Prayer.dhuhr]!.type, AlertType.shortTone);
      expect(loaded.prayers[Prayer.asr]!.enabled, false);
    });
  });
}
