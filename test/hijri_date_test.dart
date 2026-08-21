// اختبارات التقويم الهجري الجدولي / Tabular Hijri calendar tests

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/utils/hijri_date.dart';

void main() {
  group('hijriFromDate', () {
    test('2024-04-10 ≈ 1 Shawwal 1445 (±1 day)', () {
      final HijriDate result = hijriFromDate(DateTime(2024, 4, 10));
      expect(result.year, 1445);
      expect(result.month, 10); // Shawwal
      expect((result.day - 1).abs(), lessThanOrEqualTo(1));
    });

    test('2026-01-01 ≈ 12 Rajab 1447 (±1 day)', () {
      final HijriDate result = hijriFromDate(DateTime(2026, 1, 1));
      expect(result.year, 1447);
      expect(result.month, 7); // Rajab
      expect((result.day - 12).abs(), lessThanOrEqualTo(1));
    });

    test('2023-03-23 ≈ 1 Ramadan 1444 (±1 day)', () {
      final HijriDate result = hijriFromDate(DateTime(2023, 3, 23));
      expect(result.year, 1444);
      expect(result.month, 9); // Ramadan
      expect((result.day - 1).abs(), lessThanOrEqualTo(1));
    });
  });

  group('formatHijri', () {
    test('Arabic format includes هـ', () {
      const HijriDate date = HijriDate(1445, 10, 1);
      final String formatted = formatHijri(date, 'ar');
      expect(formatted, contains('هـ'));
      expect(formatted, contains('شوال'));
    });

    test('English format includes AH', () {
      const HijriDate date = HijriDate(1445, 10, 1);
      final String formatted = formatHijri(date, 'en');
      expect(formatted, contains('AH'));
      expect(formatted, contains('Shawwal'));
    });
  });
}