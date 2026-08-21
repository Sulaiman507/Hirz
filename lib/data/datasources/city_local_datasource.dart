// مصدر بيانات المدن — من assets/data/cities.json / City datasource from bundled JSON

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/city.dart';
import '../models/city_model.dart';

/// مصدر مدن مدمج: تحميل JSON مرة واحدة ثم بحث في الذاكرة
/// Bundled city source: load JSON once, then search in memory
class CityLocalDatasource {
  CityLocalDatasource();

  static const String _assetPath = 'assets/data/cities.json';

  List<CityModel>? _cache; // ذاكرة مؤقتة بعد التحميل الأول / first-load cache

  /// تحميل كل المدن / Load all bundled cities
  Future<List<CityModel>> loadCities() async {
    if (_cache != null) return _cache!;
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> raw = jsonDecode(jsonString) as List<dynamic>;
    _cache = raw
        .map((dynamic item) => CityModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// بحث في الحقول الأربعة (عربي/إنجليزي) / Search all four name fields
  Future<List<CityModel>> search(String query) async {
    final cities = await loadCities();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return cities;
    return cities.where((CityModel city) {
      return city.nameEn.toLowerCase().contains(q) ||
          city.nameAr.contains(query.trim()) ||
          city.countryEn.toLowerCase().contains(q) ||
          city.countryAr.contains(query.trim());
    }).toList();
  }

  /// إيجاد مدينة بالمعرف / Find a city by id
  Future<CityModel?> findById(String id) async {
    final cities = await loadCities();
    for (final CityModel city in cities) {
      if (city.id == id) return city;
    }
    return null;
  }

  /// تحويل كيان عام إلى نموذج / Promote a generic entity to a model
  CityModel fromEntity(City city) => CityModel.fromEntity(city);
}