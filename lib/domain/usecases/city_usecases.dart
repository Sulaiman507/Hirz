// حالات استخدام المدن / City use cases

import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// البحث عن مدن / Search cities by query
class SearchCities {
  final CityRepository _repository;

  const SearchCities(this._repository);

  Future<List<City>> call(String query) => _repository.searchCities(query);
}

/// جلب كل المدن / Get all bundled cities
class GetAllCities {
  final CityRepository _repository;

  const GetAllCities(this._repository);

  Future<List<City>> call() => _repository.getAllCities();
}

/// جلب المدينة المحفوظة / Get the saved city (null if none)
class GetSavedCity {
  final CityRepository _repository;

  const GetSavedCity(this._repository);

  Future<City?> call() => _repository.getSavedCity();
}

/// حفظ مدينة / Save a city
class SaveCity {
  final CityRepository _repository;

  const SaveCity(this._repository);

  Future<void> call(City city) => _repository.saveCity(city);
}
