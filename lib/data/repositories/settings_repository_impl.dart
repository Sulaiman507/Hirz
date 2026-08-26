// تنفيذ مستودع الإعدادات / Settings repository implementation

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

/// مستودع الإعدادات: يمرر إلى SharedPreferences
/// Settings repo: delegates to SharedPreferences
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;

  SettingsRepositoryImpl(this._datasource);

  @override
  Future<AppSettings> getSettings() async {
    return _datasource.load();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _datasource.save(settings);
  }
}
