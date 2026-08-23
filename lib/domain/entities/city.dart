// كيان المدينة / City entity (pure Dart, dart:core only)

/// مدينة للحساب: من القائمة المدمجة أو إدخال يدوي
/// City used for calculations: from the bundled list or user-entered
class City {
  final String id;
  final String nameEn;
  final String nameAr;
  final String countryEn;
  final String countryAr;
  final double latitude;
  final double longitude;
  final double timezoneOffsetHours; // إزاحة شتوية احتياطية / Fallback winter offset
  final String? timezoneId; // معرف IANA لحساب DST / IANA id for DST-aware offset
  final bool isCustom; // مدينة أدخلها المستخدم يدوياً / Manually entered city

  const City({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.countryEn,
    required this.countryAr,
    required this.latitude,
    required this.longitude,
    required this.timezoneOffsetHours,
    this.timezoneId,
    this.isCustom = false,
  });
}