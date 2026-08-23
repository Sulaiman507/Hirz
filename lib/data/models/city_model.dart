// نموذج المدينة — تحويل JSON ↔ كيان / City model: JSON ↔ entity

import '../../domain/entities/city.dart';

/// نموذج بيانات المدينة (قابل للتسلسل) / Serializable city model
class CityModel extends City {
  const CityModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.countryEn,
    required super.countryAr,
    required super.latitude,
    required super.longitude,
    required super.timezoneOffsetHours,
    super.timezoneId,
    super.isCustom,
  });

  /// من JSON إلى نموذج / From JSON map to model
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      countryEn: json['countryEn'] as String,
      countryAr: json['countryAr'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezoneOffsetHours: (json['timezoneOffsetHours'] as num).toDouble(),
      timezoneId: json['timezoneId'] as String?,
      isCustom: (json['isCustom'] as bool?) ?? false,
    );
  }

  /// من كيان المدينة إلى نموذج / From entity to model
  factory CityModel.fromEntity(City city) {
    return CityModel(
      id: city.id,
      nameEn: city.nameEn,
      nameAr: city.nameAr,
      countryEn: city.countryEn,
      countryAr: city.countryAr,
      latitude: city.latitude,
      longitude: city.longitude,
      timezoneOffsetHours: city.timezoneOffsetHours,
      timezoneId: city.timezoneId,
      isCustom: city.isCustom,
    );
  }

  /// من النموذج إلى JSON / Serialize to JSON map
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'countryEn': countryEn,
      'countryAr': countryAr,
      'latitude': latitude,
      'longitude': longitude,
      'timezoneOffsetHours': timezoneOffsetHours,
      if (timezoneId != null) 'timezoneId': timezoneId,
      'isCustom': isCustom,
    };
  }
}