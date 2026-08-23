// إعدادات التطبيق / App settings (pure Dart, dart:core only)

/// طريقة الحساب — الأسماء تطابق مكتبة adhan حرفياً
/// Calculation method — names map 1:1 to the adhan library
enum CalculationMethod {
  // تلقائي: يتبع الطريقة الرسمية للمدينة المختارة
  // auto: follows the selected city's official regional method
  auto('auto'),
  ummAlQura('ummAlQura'),
  muslimWorldLeague('muslimWorldLeague'),
  egyptian('egyptian'),
  karachi('karachi'),
  northAmerica('northAmerica'),
  turkey('turkey'),
  qatar('qatar'),
  kuwait('kuwait'),
  dubai('dubai');

  /// المعرف النصي المستخدم في cities.json / String id used in cities.json
  final String jsonId;
  const CalculationMethod(this.jsonId);
}

/// مذهب حساب وقت العصر / Madhab for Asr calculation
enum Madhab { shafi, hanafi }

/// إعدادات التطبيق الكاملة / Full app settings
class AppSettings {
  final String languageCode; // 'ar' | 'en'
  final bool isDarkMode;
  final CalculationMethod method;
  final Madhab madhab;
  final bool use24HourFormat;
  final Map<String, int> iqamahOffsets; // مفاتيح: fajr,sunrise,dhuhr,asr,maghrib,isha بالدقائق / keys in minutes

  /// فروق الإقامة الافتراضية بالدقائق / Default iqamah offsets in minutes
  static const Map<String, int> defaultIqamahOffsets = {
    'fajr': 20,
    'sunrise': 15,
    'dhuhr': 15,
    'asr': 15,
    'maghrib': 10,
    'isha': 20,
  };

  const AppSettings({
    required this.languageCode,
    required this.isDarkMode,
    required this.method,
    required this.madhab,
    required this.use24HourFormat,
    required this.iqamahOffsets,
  });

  /// نسخة محدّثة بحقول اختيارية / Updated copy with optional overrides
  AppSettings copyWith({
    String? languageCode,
    bool? isDarkMode,
    CalculationMethod? method,
    Madhab? madhab,
    bool? use24HourFormat,
    Map<String, int>? iqamahOffsets,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      iqamahOffsets: iqamahOffsets ?? this.iqamahOffsets,
    );
  }
}