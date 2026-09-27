// أدوات جغرافية مشتركة / Shared geo utilities
// المصدر الوحيد لدالة haversine — كان مكرراً في nearest_city و auto_location
// Single source of truth for haversine — previously duplicated

import 'dart:math' as math;

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
