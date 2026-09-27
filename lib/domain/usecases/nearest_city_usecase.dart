// توحيد مطابقة «أقرب مدينة» في usecase دومين واحد
// Unified nearest-city matching — single domain usecase
// استُبدل به التكرار الموجود سابقاً في core/utils/nearest_city
// و auto_location_service.nearestCity (سلوك كل مستدعٍ محفوظ عبر الخيارات).
// ملاحظة اعتماد: يستورد geo_utils النقي فقط (math) — الحافة الوحيدة domain→core.

import '../entities/city.dart';
import '../../core/utils/geo_utils.dart';

/// نتيجة المطابقة / matching result
class NearestCityResult {
  final City? city;
  final double distanceKm;
  const NearestCityResult({required this.city, required this.distanceKm});
}

/// أقرب مدينة من [cities] للنقطة المعطاة مع خيارات فلترة.
///
/// - [includeCustom]: هل تُدرج المدن اليدوية (الافتراضي نعم — لمسار الموقع).
/// - [requireTzOrMethod]: اشتراط أن تحمل المدينة tz أو method لوراثتها
///   (الافتراضي لا — يُفعَّل في مسار الإدخال اليدوي، كالسلوك السابق ≤300كم).
/// - [maxKm]: إن جاوزت المسافة هذا الحد تُرجع null (الافتراضي بلا حد).
NearestCityResult findNearestCity({
  required double latitude,
  required double longitude,
  required List<City> cities,
  double maxKm = double.infinity,
  bool includeCustom = true,
  bool requireTzOrMethod = false,
}) {
  City? best;
  double bestKm = double.infinity;
  for (final City c in cities) {
    if (!includeCustom && c.isCustom) continue;
    if (requireTzOrMethod && c.timezoneId == null && c.methodId == null) {
      continue;
    }
    final double km = haversineKm(latitude, longitude, c.latitude, c.longitude);
    if (km < bestKm) {
      bestKm = km;
      best = c;
    }
  }
  final bool inRange = bestKm <= maxKm;
  return NearestCityResult(
    city: inRange ? best : null,
    distanceKm: bestKm == double.infinity ? 0 : bestKm,
  );
}
