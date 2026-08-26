// عقد مستودع الإعدادات / Settings repository contract

import '../entities/app_settings.dart';

abstract class SettingsRepository {
  /// قراءة الإعدادات المحفوظة / Read persisted settings
  Future<AppSettings> getSettings();

  /// حفظ الإعدادات / Persist settings
  Future<void> saveSettings(AppSettings settings);
}
