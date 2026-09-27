// اختبارات الأداة الجغرافية المشتركة / Shared geo utility tests
// تغطي دالة haversine الموحّدة (كانت مكررة في موقعين)
// Covers the unified haversine (previously duplicated)

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/utils/geo_utils.dart';

void main() {
  group('haversineKm', () {
    test('نفس النقطة = 0 / same point is 0', () {
      expect(haversineKm(21.4225, 39.8262, 21.4225, 39.8262), 0.0);
    });

    test('مكة → الرياض ≈ 790 كم / Makkah → Riyadh ≈ 790 km', () {
      expect(
        haversineKm(21.4225, 39.8262, 24.7136, 46.6753),
        closeTo(790, 50),
      );
    });

    test('مكة → القاهرة ≈ 1287 كم / Makkah → Cairo ≈ 1287 km', () {
      expect(
        haversineKm(21.4225, 39.8262, 30.0444, 31.2357),
        closeTo(1287, 50),
      );
    });

    test('متماثلة (تبديل النقاط لا يغيّر الناتج) / symmetric', () {
      final double a = haversineKm(21.4225, 39.8262, 24.7136, 46.6753);
      final double b = haversineKm(24.7136, 46.6753, 21.4225, 39.8262);
      expect(a, closeTo(b, 1e-6));
    });
  });
}
