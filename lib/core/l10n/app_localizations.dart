// الترجمة اليدوية — تحميل JSON من assets / Manual l10n loading JSON assets
// لا تعتمد على flutter gen-l10n / Does not rely on flutter gen-l10n

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// نصوص التطبيق من ملفات JSON / App strings from JSON files
class AppLocalizations {
  final Locale locale;
  late final Map<String, dynamic> _strings;

  AppLocalizations(this.locale, this._strings);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// هل اللغة الحالية عربية (RTL)؟ / Is the current locale Arabic (RTL)?
  bool get isRTL => locale.languageCode == 'ar';

  /// جلب نص بمفتاح / Get a string by key (falls back to the key)
  String tr(String key) {
    final dynamic value = _strings[key];
    if (value is String) return value;
    return key;
  }

  /// جلب قائمة نصوص (أشهر، أيام) / Get a list of strings (months, days)
  List<String> trList(String key) {
    final dynamic value = _strings[key];
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return <String>[];
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // المسار كما هو مُعرّف في pubspec (assets) / Path as declared in pubspec
    final String path = 'lib/l10n/app_${locale.languageCode}.json';
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> strings =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}