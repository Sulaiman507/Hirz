// اختبارات نموذج المدينة: JSON ↔ كيان / CityModel JSON round-trip tests
// يشمل حقلي timezoneId و methodId المستخدمين في الحساب الذكي
// covers timezoneId + methodId used by smart auto calculation

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/data/models/city_model.dart';
import 'package:hirz/domain/entities/city.dart';

const City fullCity = City(
  id: 'np_kathmandu',
  nameEn: 'Kathmandu',
  nameAr: 'كاتماندو',
  countryEn: 'Nepal',
  countryAr: 'نيبال',
  latitude: 27.7172,
  longitude: 85.3240,
  timezoneOffsetHours: 5.75,
  timezoneId: 'Asia/Kathmandu',
  methodId: 'muslimWorldLeague',
);

const City minimalCity = City(
  id: 'xx_manual',
  nameEn: 'My Spot',
  nameAr: 'موقعي',
  countryEn: 'Custom',
  countryAr: 'مخصص',
  latitude: -33.86,
  longitude: 151.21,
  timezoneOffsetHours: 10,
  isCustom: true,
);

void main() {
  group('fromJson → toJson (round-trip)', () {
    test('مدينة كاملة تحفظ كل الحقول / full city keeps all fields', () {
      final Map<String, dynamic> json =
          CityModel.fromEntity(fullCity).toJson();
      final CityModel restored = CityModel.fromJson(json);

      expect(restored.id, fullCity.id);
      expect(restored.nameEn, fullCity.nameEn);
      expect(restored.nameAr, fullCity.nameAr);
      expect(restored.countryAr, fullCity.countryAr);
      expect(restored.latitude, fullCity.latitude);
      expect(restored.longitude, fullCity.longitude);
      expect(restored.timezoneOffsetHours, fullCity.timezoneOffsetHours);
      expect(restored.timezoneId, 'Asia/Kathmandu');
      expect(restored.methodId, 'muslimWorldLeague');
      expect(restored.isCustom, isFalse);
    });

    test('مدينة يدوية بدون حقول اختيارية / manual city without optional fields', () {
      final Map<String, dynamic> json =
          CityModel.fromEntity(minimalCity).toJson();

      // الحقول الاختيارية لا تُسلسل عند null / null optionals omitted
      expect(json.containsKey('timezoneId'), isFalse);
      expect(json.containsKey('methodId'), isFalse);
      expect(json['isCustom'], isTrue); // أُنشئت كإدخال يدوي

      final CityModel restored = CityModel.fromJson(json);
      expect(restored.timezoneId, isNull);
      expect(restored.methodId, isNull);
      expect(restored.timezoneOffsetHours, 10.0);
    });

    test('isCustom مفقود في JSON يعامل false / missing isCustom defaults false', () {
      final Map<String, dynamic> json =
          CityModel.fromEntity(fullCity).toJson()
            ..remove('isCustom');
      expect(CityModel.fromJson(json).isCustom, isFalse);
    });

    test('إزاحة نيبال الربعية تبقى دقيقة / quarter-hour offset survives', () {
      final Map<String, dynamic> json =
          CityModel.fromEntity(fullCity).toJson();
      final CityModel restored = CityModel.fromJson(json);
      expect(restored.timezoneOffsetHours, 5.75);
    });
  });
}
