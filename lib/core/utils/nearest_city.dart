// مطابقة المدينة اليدوية لأقرب مدينة معروفة — لوراثة timezoneId/methodId
// Match a manual city to its nearest known city — inherits tz + method
// (يصلح فقدان DST وطرق الحساب للمدن اليدوية / fixes DST+method loss)

import 'dart:math' as math;

import '../../domain/entities/city.dart';

/// المسافة بالكيلومتر بين إحداثيتين (haversine)
/// Great-circle distance in km between two coordinates
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371.0; // نصف قطر الأرض كم
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);
  final double a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

double _degToRad(double deg) => deg * math.pi / 180.0;

/// أقرب مدينة من [known] إلى النقطة المعطاة ضمن حد أقصى [maxKm]
/// Nearest known city to the point within [maxKm], or null
City? nearestKnownCity({
  required double latitude,
  required double longitude,
  required List<City> known,
  double maxKm = 300,
}) {
  City? best;
  double bestKm = double.infinity;
  for (final City c in known) {
    if (c.isCustom) continue; // تجاهل المدن اليدوية الأخرى
    if (c.timezoneId == null && c.methodId == null) continue;
    final double km = haversineKm(latitude, longitude, c.latitude, c.longitude);
    if (km < bestKm) {
      bestKm = km;
      best = c;
    }
  }
  return bestKm <= maxKm ? best : null;
}
