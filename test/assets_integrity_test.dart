// اختبارات سلامة الأصول المدمجة / Bundled assets integrity tests
// يضمن أن l10n و cities.json سليمة قبل وصولها للـ UI
// ensures l10n keys and city data stay consistent before reaching the UI

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/l10n/app_localizations.dart';

/// قراءة ملف من مجلد المشروع الحقيقي / read a file from the real project tree
String _readProjectFile(String relativePath) {
  // CI يشغّل الاختبارات من جذر scaffold/ مع نسخ lib/ — نفس البنية المحلية
  return File(relativePath).readAsStringSync();
}

void main() {
  group('ترجمات الواجهة / localization files', () {
    late final Map<String, dynamic> ar;
    late final Map<String, dynamic> en;

    setUpAll(() {
      ar = jsonDecode(_readProjectFile('lib/l10n/app_ar.json'))
          as Map<String, dynamic>;
      en = jsonDecode(_readProjectFile('lib/l10n/app_en.json'))
          as Map<String, dynamic>;
    });

    test('العربية والإنجليزية لهما نفس مفاتيح تماماً / identical key sets', () {
      expect(ar.keys.toSet(), equals(en.keys.toSet()));
    });

    test('كل القيم نصوص أو قوائم نصوص غير فارغة / values are non-empty strings or lists', () {
      for (final MapEntry<String, dynamic> e in ar.entries) {
        final dynamic value = e.value;
        if (value is List<dynamic>) {
          // قوائم مثل أسماء الأشهر والأيام / lists like month & weekday names
          expect(value, isNotEmpty, reason: 'key=${e.key}');
          for (final dynamic item in value) {
            expect(item, isA<String>(), reason: 'key=${e.key}');
            expect((item as String).trim(), isNotEmpty, reason: 'key=${e.key}');
          }
        } else {
          expect(value, isA<String>(), reason: 'key=${e.key}');
          expect((value as String).trim(), isNotEmpty, reason: 'key=${e.key}');
        }
      }
    });

    test('مفاتيح الخط والبحث موجودة / font + search keys present', () {
      const List<String> requiredKeys = <String>[
        'fontFamily', 'fontThickness', 'fontAmiri', 'fontCairo',
        'fontThin', 'fontThick', 'searchCity', 'noResults', 'close',
        'settingsTitle', 'manualCoordinates',
        'adhanTitle', 'adhanEnable', 'adhanTest',
        'adhanTestRegular', 'adhanTestFajr',
        'locateMe', 'locatedTo', 'locationFailed',
      ];
      for (final String key in requiredKeys) {
        expect(ar.keys, contains(key), reason: 'missing ar key=$key');
        expect(en.keys, contains(key), reason: 'missing en key=$key');
      }
    });

    test('كل طرق الحساب لها ترجمة / every calculation method has a label', () {
      // مفاتيح ديناميكية: method + jsonId بحرف أول كبير
      const List<String> jsonIds = <String>[
        'auto', 'ummAlQura', 'muslimWorldLeague', 'egyptian', 'karachi',
        'northAmerica', 'turkey', 'qatar', 'kuwait', 'dubai',
      ];
      for (final String id in jsonIds) {
        final String key = 'method${id[0].toUpperCase()}${id.substring(1)}';
        expect(ar.keys, contains(key), reason: 'missing ar $key');
        expect(en.keys, contains(key), reason: 'missing en $key');
      }
    });
  });

  group('قاعدة المدن / bundled cities.json', () {
    late final List<Map<String, dynamic>> cities;

    setUpAll(() {
      final List<dynamic> raw =
          jsonDecode(_readProjectFile('assets/data/cities.json'))
              as List<dynamic>;
      cities = raw.cast<Map<String, dynamic>>();
    });

    test('عدد المدن ضمن النطاق المتوقع / plausible city count', () {
      expect(cities.length, greaterThan(100));
      expect(cities.length, lessThan(500));
    });

    test('كل مدينة لها كل الحقول الإلزامية / every city has mandatory fields', () {
      const List<String> required = <String>[
        'id', 'nameEn', 'nameAr', 'countryEn', 'countryAr',
        'latitude', 'longitude', 'timezoneOffsetHours',
      ];
      for (int i = 0; i < cities.length; i++) {
        for (final String field in required) {
          expect(cities[i].keys, contains(field),
              reason: 'city[$i]=${cities[i]['id']} missing $field');
        }
      }
    });

    test('المعرفات فريدة / unique ids', () {
      final Set<String> ids = cities.map((Map<String, dynamic> c) => c['id'] as String).toSet();
      expect(ids.length, cities.length, reason: 'duplicate ids found');
    });

    test('الإحداثيات داخل النطاقات الصحيحة / coordinates in valid ranges', () {
      for (final Map<String, dynamic> c in cities) {
        final double lat = (c['latitude'] as num).toDouble();
        final double lon = (c['longitude'] as num).toDouble();
        expect(lat.abs(), lessThanOrEqualTo(90), reason: '${c['id']} lat');
        expect(lon.abs(), lessThanOrEqualTo(180), reason: '${c['id']} lon');
        expect((c['timezoneOffsetHours'] as num).toDouble().abs(),
            lessThanOrEqualTo(14), reason: '${c['id']} tz');
      }
    });

    test('طريقة الحساب إن وُجدت تطابق enum التطبيق / methodIds match enum names', () {
      // الأسماء الصالحة من CalculationMethod في app_settings.dart
      const Set<String> valid = <String>{
        'auto', 'ummAlQura', 'muslimWorldLeague', 'egyptian', 'karachi',
        'northAmerica', 'turkey', 'qatar', 'kuwait', 'dubai',
      };
      for (final Map<String, dynamic> c in cities) {
        final Object? methodId = c['methodId'];
        if (methodId != null) {
          expect(valid, contains(methodId),
              reason: '${c['id']} has unknown methodId=$methodId');
        }
      }
    });
  });

  group('AppLocalizations fallback', () {
    test('tr يعيد المفتاح نفسه للنص الغريب / tr falls back to the key', () {
      final AppLocalizations l10n = AppLocalizations(
        const Locale('ar'),
        <String, dynamic>{},
      );
      expect(l10n.tr('definitely_not_a_key'), 'definitely_not_a_key');
    });
  });
}
