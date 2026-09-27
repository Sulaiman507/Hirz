// اختبارات مطابقة المدينة اليدوية لأقرب مدينة / nearestKnownCity tests
// تغطي وراثة التوقيت/الطريقة وتجاهل المدن المخصصة وحد maxKm

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/utils/nearest_city.dart';
import 'package:hirz/domain/entities/city.dart';

City _city(
  String id,
  double lat,
  double lon, {
  String? tzId,
  String? methodId,
  bool isCustom = false,
}) {
  return City(
    id: id,
    nameEn: id,
    nameAr: id,
    countryEn: '',
    countryAr: '',
    latitude: lat,
    longitude: lon,
    timezoneOffsetHours: 3,
    timezoneId: tzId,
    methodId: methodId,
    isCustom: isCustom,
  );
}

void main() {
  final City makkah = _city(
    'sa_makkah',
    21.4225,
    39.8262,
    tzId: 'Asia/Riyadh',
    methodId: 'ummAlQura',
  );
  final City riyadh = _city(
    'sa_riyadh',
    24.7136,
    46.6753,
    tzId: 'Asia/Riyadh',
    methodId: 'ummAlQura',
  );
  final City custom = _city('xx_custom', 24.0, 40.0, isCustom: true);

  group('nearestKnownCity', () {
    test('يرجع أقرب مدينة مع وراثة التوقيت والطريقة', () {
      final City? near = nearestKnownCity(
        latitude: 21.5,
        longitude: 40.0,
        known: <City>[makkah, riyadh],
      );
      expect(near?.id, 'sa_makkah');
      expect(near?.timezoneId, 'Asia/Riyadh');
      expect(near?.methodId, 'ummAlQura');
    });

    test('يتجاوز المدن المخصصة', () {
      final City? near = nearestKnownCity(
        latitude: 24.0,
        longitude: 40.0,
        known: <City>[custom, makkah, riyadh],
      );
      expect(near?.id, 'sa_makkah');
    });

    test('يرجع null خارج حد maxKm الافتراضي (300)', () {
      final City? near = nearestKnownCity(
        latitude: 50.0,
        longitude: -120.0,
        known: <City>[makkah, riyadh],
      );
      expect(near, isNull);
    });
  });
}
