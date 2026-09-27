// مطابقة المدينة اليدوية لأقرب مدينة معروفة — لوراثة timezoneId/methodId
// Match a manual city to its nearest known city — inherits tz + method
// (يصلح فقدان DST وطرق الحساب للمدن اليدوية / fixes DST+method loss)

import '../../domain/entities/city.dart';
import 'geo_utils.dart';

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
