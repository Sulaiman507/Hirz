// اختبارات كيان الإعدادات / AppSettings entity tests
// يغطي حقلي الخط المضافين حديثاً / covers the newly added font fields

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/domain/entities/app_settings.dart';

AppSettings _base() => AppSettings(
      languageCode: 'ar',
      isDarkMode: false,
      method: CalculationMethod.auto,
      madhab: Madhab.shafi,
      use24HourFormat: false,
      iqamahOffsets: AppSettings.defaultIqamahOffsets,
    );

void main() {
  group('القيم الافتراضية / Defaults', () {
    test('الخط الافتراضي أميري بسماكة 1.0', () {
      final AppSettings s = _base();
      expect(s.fontFamily, 'Amiri');
      expect(s.fontThickness, 1.0);
    });

    test('طرق الحساب تتضمن الطرق الرئيسية / methods include majors', () {
      expect(CalculationMethod.values.map((CalculationMethod m) => m.name),
          containsAll(<String>['auto', 'ummAlQura', 'egyptian', 'karachi']));
    });
  });

  group('copyWith', () {
    test('تغيير نوع الخط فقط لا يمس البقية / font change isolates', () {
      final AppSettings updated = _base().copyWith(fontFamily: 'Cairo');
      expect(updated.fontFamily, 'Cairo');
      expect(updated.languageCode, 'ar');
      expect(updated.method, CalculationMethod.auto);
      expect(updated.iqamahOffsets, AppSettings.defaultIqamahOffsets);
    });

    test('تغيير السماكة فقط / thickness-only change', () {
      final AppSettings updated = _base().copyWith(fontThickness: 1.5);
      expect(updated.fontThickness, 1.5);
      expect(updated.fontFamily, 'Amiri');
    });

    test('copyWith بلا معاملات يعيد نسخة متطابقة القيم / identity copy', () {
      final AppSettings original = _base();
      final AppSettings copied = original.copyWith();
      expect(copied.fontFamily, original.fontFamily);
      expect(copied.fontThickness, original.fontThickness);
      expect(identical(copied, original), isFalse);
    });
  });

  group('فروق الإقامة الافتراضية / default iqamah offsets', () {
    test('الصلوات الست موجودة بقيم موجبة / six prayers with positive values', () {
      const Map<String, int> offsets = AppSettings.defaultIqamahOffsets;
      expect(offsets.keys.toSet(), <String>{
        'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha',
      });
      for (final int minutes in offsets.values) {
        expect(minutes, greaterThan(0));
      }
    });
  });
}
