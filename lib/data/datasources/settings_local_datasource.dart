// مصدر بيانات الإعدادات — SharedPreferences / Settings datasource via SharedPreferences

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';

/// مفاتيح التخزين / Storage keys
abstract class SettingsKeys {
  static const String languageCode = 'language_code';
  static const String isDarkMode = 'is_dark_mode';
  static const String calculationMethod = 'calculation_method';
  static const String madhab = 'madhab';
  static const String use24Hour = 'use_24_hour';
  static const String iqamahOffsets = 'iqamah_offsets';
  static const String savedCityId = 'saved_city_id';
  static const String savedCustomCity = 'saved_custom_city';
  static const String fontFamily = 'font_family';
  static const String fontThickness = 'font_thickness';
}

/// مصدر الإعدادات بأنواع صريحة — لا dynamic عائم
/// Settings source with explicit types — no floating dynamic
class SettingsLocalDatasource {
  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  /// قراءة الإعدادات أو الافتراضيات / Read settings or defaults
  AppSettings load() {
    final String languageCode =
        _prefs.getString(SettingsKeys.languageCode) ?? 'ar';
    final bool isDarkMode = _prefs.getBool(SettingsKeys.isDarkMode) ?? false;

    final String methodRaw =
        _prefs.getString(SettingsKeys.calculationMethod) ??
            CalculationMethod.auto.name;
    final CalculationMethod method = CalculationMethod.values.firstWhere(
      (CalculationMethod m) => m.name == methodRaw,
      orElse: () => CalculationMethod.auto,
    );

    final String madhabRaw =
        _prefs.getString(SettingsKeys.madhab) ?? Madhab.shafi.name;
    final Madhab madhab = Madhab.values.firstWhere(
      (Madhab m) => m.name == madhabRaw,
      orElse: () => Madhab.shafi,
    );

    final bool use24Hour = _prefs.getBool(SettingsKeys.use24Hour) ?? false;

    final Map<String, int> iqamahOffsets = _loadIqamahOffsets();

    final String fontFamilyRaw =
        _prefs.getString(SettingsKeys.fontFamily) ?? 'Amiri';
    // قيمة غير معروفة (خطأ قديم) → ارجع لافتراضي بدل انفجار
    final String fontFamily =
        (fontFamilyRaw == 'Amiri' || fontFamilyRaw == 'Cairo')
            ? fontFamilyRaw
            : 'Amiri';
    final double fontThicknessRaw =
        _prefs.getDouble(SettingsKeys.fontThickness) ?? 1.0;
    final double fontThickness = fontThicknessRaw.clamp(0.5, 2.0);

    return AppSettings(
      languageCode: languageCode,
      isDarkMode: isDarkMode,
      method: method,
      madhab: madhab,
      use24HourFormat: use24Hour,
      iqamahOffsets: iqamahOffsets,
      fontFamily: fontFamily,
      fontThickness: fontThickness,
    );
  }

  /// حفظ الإعدادات / Persist settings
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(SettingsKeys.languageCode, settings.languageCode);
    await _prefs.setBool(SettingsKeys.isDarkMode, settings.isDarkMode);
    await _prefs.setString(SettingsKeys.calculationMethod, settings.method.name);
    await _prefs.setString(SettingsKeys.madhab, settings.madhab.name);
    await _prefs.setBool(SettingsKeys.use24Hour, settings.use24HourFormat);
    await _prefs.setString(
      SettingsKeys.iqamahOffsets,
      jsonEncode(settings.iqamahOffsets),
    );
    await _prefs.setString(SettingsKeys.fontFamily, settings.fontFamily);
    await _prefs.setDouble(SettingsKeys.fontThickness, settings.fontThickness);
  }

  Map<String, int> _loadIqamahOffsets() {
    final String? raw = _prefs.getString(SettingsKeys.iqamahOffsets);
    if (raw == null || raw.isEmpty) {
      return Map<String, int>.from(AppSettings.defaultIqamahOffsets);
    }
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map<String, int>(
      (String key, dynamic value) => MapEntry<String, int>(key, value as int),
    );
  }
}