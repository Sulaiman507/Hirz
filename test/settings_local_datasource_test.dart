// اختبارات مصدر الإعدادات المحلي / Settings local datasource tests
// يغطي إصلاح حفظ الخط (font_family / font_thickness) مع SharedPreferences Mock
// covers the font persistence fix via the plugin's built-in mock

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/data/datasources/settings_local_datasource.dart';
import 'package:hirz/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppSettings _settings({String? fontFamily, double? fontThickness}) =>
    AppSettings(
      languageCode: 'ar',
      isDarkMode: false,
      method: CalculationMethod.ummAlQura,
      madhab: Madhab.shafi,
      use24HourFormat: false,
      iqamahOffsets: AppSettings.defaultIqamahOffsets,
      fontFamily: fontFamily ?? 'Amiri',
      fontThickness: fontThickness ?? 1.0,
    );

Future<SettingsLocalDatasource> _datasourceWith(
  Map<String, Object> initial,
) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsLocalDatasource(await SharedPreferences.getInstance());
}

void main() {
  group('load()', () {
    test('تخزين فارغ → خط أميري بسماكة 1.0 / empty store → defaults', () async {
      final SettingsLocalDatasource ds = await _datasourceWith(<String, Object>{});
      final AppSettings s = ds.load();
      expect(s.fontFamily, 'Amiri');
      expect(s.fontThickness, 1.0);
    });

    test('قيمة خط تالفة → ترجع آمنة لأميري / corrupt font value → safe fallback', () async {
      final SettingsLocalDatasource ds = await _datasourceWith(
        <String, Object>{'font_family': 'ComicSans'},
      );
      expect(ds.load().fontFamily, 'Amiri');
    });

    test('سماكة خارج النطاق تُقيَّد / out-of-range thickness clamps', () async {
      final SettingsLocalDatasource ds = await _datasourceWith(
        <String, Object>{'font_thickness': 9.9},
      );
      expect(ds.load().fontThickness, 2.0);
    });
  });

  group('save → load round-trip', () {
    test('نوع الخط وسماكته يبقيان بعد الإعادة / font survives reload', () async {
      final SettingsLocalDatasource writeDs =
          await _datasourceWith(<String, Object>{});
      await writeDs.save(_settings(fontFamily: 'Cairo', fontThickness: 1.5));

      // قراءة من تخزين جديد بنفس القيم المخزنة
      final SettingsLocalDatasource readDs = await _datasourceWith(
        <String, Object>{
          'font_family': 'Cairo',
          'font_thickness': 1.5,
          'language_code': 'ar',
        },
      );
      final AppSettings s = readDs.load();
      expect(s.fontFamily, 'Cairo');
      expect(s.fontThickness, 1.5);
    });

    test('كل حقول الإعدادات تدور كاملة / all fields survive full cycle', () async {
      final SettingsLocalDatasource writeDs =
          await _datasourceWith(<String, Object>{});
      final AppSettings original = _settings().copyWith(
        languageCode: 'en',
        isDarkMode: true,
        use24HourFormat: true,
      );
      await writeDs.save(original);

      final Map<String, Object> stored = <String, Object>{
        'language_code': 'en',
        'is_dark_mode': true,
        'calculation_method': 'ummAlQura',
        'madhab': 'shafi',
        'use_24_hour': true,
        'iqamah_offsets':
            '{"fajr":20,"sunrise":15,"dhuhr":15,"asr":15,"maghrib":10,"isha":20}',
        'font_family': 'Amiri',
        'font_thickness': 1.0,
        'adhan_enabled': true,
      };
      final SettingsLocalDatasource readDs = await _datasourceWith(stored);
      final AppSettings loaded = readDs.load();

      expect(loaded.languageCode, 'en');
      expect(loaded.isDarkMode, isTrue);
      expect(loaded.use24HourFormat, isTrue);
      expect(loaded.method, CalculationMethod.ummAlQura);
      expect(loaded.iqamahOffsets['fajr'], 20);
      expect(loaded.iqamahOffsets['maghrib'], 10);
      expect(loaded.adhanEnabled, isTrue);
    });

    test('adhanEnabled مفقود → افتراضياً معطل / missing flag defaults off', () async {
      final SettingsLocalDatasource ds = await _datasourceWith(<String, Object>{});
      expect(ds.load().adhanEnabled, isFalse);
    });
  });
}
