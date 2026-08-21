// حالات استخدام الإعدادات / Settings use cases

import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// قراءة الإعدادات / Read settings
class GetSettings {
  final SettingsRepository _repository;

  const GetSettings(this._repository);

  Future<AppSettings> call() => _repository.getSettings();
}

/// حفظ الإعدادات / Save settings
class SaveSettings {
  final SettingsRepository _repository;

  const SaveSettings(this._repository);

  Future<void> call(AppSettings settings) => _repository.saveSettings(settings);
}