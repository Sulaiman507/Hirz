// عقد مستودع المدن / City repository contract

import '../entities/city.dart';

abstract class CityRepository {
  /// كل المدن المدمجة / All bundled cities
  Future<List<City>> getAllCities();

  /// بحث بالاسم أو الدولة (عربي/إنجليزي) / Search by name or country (ar/en)
  Future<List<City>> searchCities(String query);

  /// المدينة المحفوظة، أو null إن لم تُحفظ بعد / Saved city, or null if none
  Future<City?> getSavedCity();

  /// يحفظ id إن كانت من القائمة، أو كامل المدينة إن custom
  /// Saves the id for listed cities, or the full city if custom
  Future<void> saveCity(City city);

  /// حفظ مدينة مدخلة يدوياً / Save a manually entered city
  Future<void> saveCustomCity(City city);

  /// جلب المدينة المخصصة المحفوظة إن وجدت
  /// Get the saved custom city, if any
  Future<City?> getSavedCustomCity();
}