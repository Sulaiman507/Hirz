// خدمة تحديد الموقع التلقائي — GPS → أقرب مدينة مدمجة
// Auto-location service: GPS fix → nearest bundled city

import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/city.dart';

/// نتيجة التحديد التلقائي / auto-location result
class LocationResult {
  final City city;
  final double distanceKm;
  final bool isApproximate; // أقرب مدينة بعيدة → تقريب / nearest fallback

  const LocationResult({
    required this.city,
    required this.distanceKm,
    required this.isApproximate,
  });
}

class AutoLocationService {
  const AutoLocationService();

  /// إحداثيات الجهاز مع طلب الأذونات / device fix with permission handling
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('location permission denied');
    }
    // آخر موضع معروف سريعاً ثم تحديد دقيق / cached fix first, then precise
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        ).timeout(const Duration(seconds: 12), onTimeout: () => last);
      }
    } catch (_) {
      // تجاهل وأكمل بالتحديد المباشر / fall through to direct fix
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    ).timeout(const Duration(seconds: 20));
  }

  /// أقرب مدينة من القائمة المدمجة / nearest bundled city by haversine
  LocationResult nearestCity(List<City> cities, Position position) {
    City best = cities.first;
    double bestKm = double.infinity;
    for (final City c in cities) {
      final double km = _haversineKm(
        position.latitude,
        position.longitude,
        c.latitude,
        c.longitude,
      );
      if (km < bestKm) {
        bestKm = km;
        best = c;
      }
    }
    return LocationResult(
      city: best,
      distanceKm: bestKm,
      isApproximate: bestKm > 50, // أبعد من 50كم → تقدير تقريبي
    );
  }

  /// اسم المنطقة من الإحداثيات (اختياري للعرض) / reverse geocode (optional label)
  Future<String?> areaLabel(double lat, double lon) async {
    try {
      final List<Placemark> marks = await placemarkFromCoordinates(
        lat,
        lon,
      ).timeout(const Duration(seconds: 8));
      if (marks.isEmpty) return null;
      final Placemark m = marks.first;
      // في geocoding 3.0 كل الحقول nullable / all fields nullable in v3
      final String city = (m.locality?.isNotEmpty ?? false)
          ? m.locality!
          : (m.administrativeArea ?? '');
      final String country = m.country ?? '';
      if (city.isEmpty && country.isEmpty) return null;
      return country.isEmpty ? city : '$city، $country';
    } catch (_) {
      return null; // بلا إنترنت نكتفي بأقرب مدينة مدمجة
    }
  }

  /// مسافة هافرسين بالكيلومتر / haversine distance in km
  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371.0;
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _deg2rad(double deg) => deg * math.pi / 180.0;
}
