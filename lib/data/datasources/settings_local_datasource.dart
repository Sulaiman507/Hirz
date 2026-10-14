// مصدر بيانات الإعدادات — SharedPreferences / Settings datasource via SharedPreferences

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../prefs_keys.dart';

/// مصدر الإعدادات بأنواع صريحة — لا dynamic عائم
/// Settings source with explicit types — no floating dynamic
class SettingsLocalDatasource {
  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  /// قراءة الإعدادات أو الافتراضيات / Read settings or defaults
  AppSettings load() {
    final String languageCode =
        _prefs.getString(PrefsKeys.languageCode) ?? 'ar';
    final bool isDarkMode = _prefs.getBool(PrefsKeys.isDarkMode) ?? false;

    final String methodRaw =
        _prefs.getString(PrefsKeys.calculationMethod) ??
        CalculationMethod.auto.name;
    final CalculationMethod method = CalculationMethod.values.firstWhere(
      (CalculationMethod m) => m.name == methodRaw,
      orElse: () => CalculationMethod.auto,
    );

    final String madhabRaw =
        _prefs.getString(PrefsKeys.madhab) ?? Madhab.shafi.name;
    final Madhab madhab = Madhab.values.firstWhere(
      (Madhab m) => m.name == madhabRaw,
      orElse: () => Madhab.shafi,
    );

    final bool use24Hour = _prefs.getBool(PrefsKeys.use24Hour) ?? false;

    final Map<String, int> iqamahOffsets = _loadIqamahOffsets();

    final String fontFamilyRaw =
        _prefs.getString(PrefsKeys.fontFamily) ?? 'Amiri';
    // قيمة غير معروفة (خطأ قديم) → ارجع لافتراضي بدل انفجار
    final String fontFamily =
        (fontFamilyRaw == 'Amiri' || fontFamilyRaw == 'Cairo')
        ? fontFamilyRaw
        : 'Amiri';
    final double fontThicknessRaw =
        _prefs.getDouble(PrefsKeys.fontThickness) ?? 1.0;
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
    // كتابة متوازية — المفاتيح مستقلة / parallel writes — keys are independent
    await Future.wait(<Future<void>>[
      _prefs.setString(PrefsKeys.languageCode, settings.languageCode),
      _prefs.setBool(PrefsKeys.isDarkMode, settings.isDarkMode),
      _prefs.setString(PrefsKeys.calculationMethod, settings.method.name),
      _prefs.setString(PrefsKeys.madhab, settings.madhab.name),
      _prefs.setBool(PrefsKeys.use24Hour, settings.use24HourFormat),
      _prefs.setString(
        PrefsKeys.iqamahOffsets,
        jsonEncode(settings.iqamahOffsets),
      ),
      _prefs.setString(PrefsKeys.fontFamily, settings.fontFamily),
      _prefs.setDouble(PrefsKeys.fontThickness, settings.fontThickness),
    ]);
  }

  Map<String, int> _loadIqamahOffsets() {
    // ابدأ دائماً من الافتراضيات ثم ادمج المخزَّن فوقها — أي مفتاح ناقص في
    // التخزين (بيانات قديمة أو تالفة) يعود للافتراضي بدل أن يُفقد.
    // Always start from defaults, then merge stored values on top — any key
    // missing from storage (old/corrupt data) falls back instead of dropping.
    final Map<String, int> offsets = Map<String, int>.from(
      AppSettings.defaultIqamahOffsets,
    );
    final String? raw = _prefs.getString(PrefsKeys.iqamahOffsets);
    if (raw == null || raw.isEmpty) {
      return offsets;
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in decoded.entries) {
        // تجاهل القيم غير الصالحة والمفاتيح الغريبة بدل الانهيار
        // Ignore invalid values and unknown keys instead of crashing
        final Object? value = entry.value;
        if (value is int && offsets.containsKey(entry.key)) {
          offsets[entry.key] = value;
        }
      }
    } catch (_) {
      // JSON تالف → الافتراضيات / corrupt JSON → defaults
    }
    return offsets;
  }
}
