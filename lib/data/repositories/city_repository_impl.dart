// تنفيذ مستودع المدن / City repository implementation

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_local_datasource.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/city_model.dart';

/// مستودع المدن: القائمة المدمجة + حفظ الاختيار في SharedPreferences
/// City repo: bundled list + persisted selection in SharedPreferences
class CityRepositoryImpl implements CityRepository {
  final CityLocalDatasource _datasource;
  final SharedPreferences _prefs;

  CityRepositoryImpl(this._datasource, this._prefs);

  @override
  Future<List<City>> getAllCities() async {
    return _datasource.loadCities();
  }

  @override
  Future<City?> getSavedCity() async {
    // أولاً: مدينة مخصصة محفوظة / First: a saved custom city
    final City? custom = await getSavedCustomCity();
    if (custom != null) return custom;
    // ثانياً: معرف مدينة من القائمة / Second: a listed city id
    final String? cityId = _prefs.getString(SettingsKeys.savedCityId);
    if (cityId == null || cityId.isEmpty) return null;
    return _datasource.findById(cityId);
  }

  @override
  Future<City?> getSavedCustomCity() async {
    final String? customRaw = _prefs.getString(SettingsKeys.savedCustomCity);
    if (customRaw == null || customRaw.isEmpty) return null;
    final Map<String, dynamic> decoded =
        jsonDecode(customRaw) as Map<String, dynamic>;
    return CityModel.fromJson(decoded);
  }

  @override
  Future<List<City>> searchCities(String query) async {
    final List<City> results = await _datasource.search(query);
    // أدرج المدينة المخصصة إن طابقت البحث — كانت مفقودة من النتائج
    // Include the custom city if it matches — it was missing from results
    final String q = query.trim();
    if (q.isNotEmpty) {
      final City? custom = await getSavedCustomCity();
      if (custom != null &&
          (custom.nameEn.toLowerCase().contains(q.toLowerCase()) ||
              custom.nameAr.contains(q))) {
        // تجنب التكرار / avoid duplicates
        final bool alreadyListed =
            results.any((City c) => c.id == custom.id);
        if (!alreadyListed) results.insert(0, custom);
      }
    }
    return results;
  }

  @override
  Future<void> saveCity(City city) async {
    if (city.isCustom) {
      await saveCustomCity(city);
      return;
    }
    await _prefs.setString(SettingsKeys.savedCityId, city.id);
    await _prefs.remove(SettingsKeys.savedCustomCity);
  }

  @override
  Future<void> saveCustomCity(City city) async {
    final CityModel model = CityModel.fromEntity(city);
    await _prefs.setString(
      SettingsKeys.savedCustomCity,
      jsonEncode(model.toJson()),
    );
    await _prefs.remove(SettingsKeys.savedCityId);
  }
}