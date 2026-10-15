// مفاتيح SharedPreferences المشتركة / Shared SharedPreferences keys
// ملف مستقل حتى لا يستورد مستودع المدن ملف مصدر بيانات الإعدادات
// Standalone so the city repository doesn't import the settings datasource

/// مفاتيح التخزين / Storage keys
abstract class PrefsKeys {
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
