// providers المدن: قائمة + بحث + المدينة المختارة
// City providers: list + search + selected city

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city.dart';
import 'app_providers.dart';

/// المدينة الافتراضية: مكة المكرمة
const City defaultCity = City(
  id: 'sa_makkah',
  nameEn: 'Makkah',
  nameAr: 'مكة المكرمة',
  countryEn: 'Saudi Arabia',
  countryAr: 'السعودية',
  latitude: 21.4225,
  longitude: 39.8262,
  timezoneOffsetHours: 3,
);

/// نص البحث الحالي
final StateProvider<String> citySearchQueryProvider = StateProvider<String>(
  (ref) => '',
);

/// كل المدن المدمجة
final FutureProvider<List<City>> citiesProvider = FutureProvider<List<City>>((
  ref,
) async {
  final getAllCities = await ref.watch(getAllCitiesUseCaseProvider.future);
  return getAllCities();
});

/// المدن بعد البحث
final FutureProvider<List<City>> filteredCitiesProvider =
    FutureProvider<List<City>>((ref) async {
  final String query = ref.watch(citySearchQueryProvider);
  final searchCities = await ref.watch(searchCitiesUseCaseProvider.future);
  return searchCities(query);
});

/// المدينة المختارة: المحفوظة أو مكة افتراضياً
final FutureProvider<City> selectedCityProvider = FutureProvider<City>((
  ref,
) async {
  final getSavedCity = await ref.watch(getSavedCityUseCaseProvider.future);
  final City? saved = await getSavedCity();
  return saved ?? defaultCity;
});

/// حفظ مدينة جديدة وإعادة حساب المواقيت
Future<void> selectCity(WidgetRef ref, City city) async {
  final saveCity = await ref.read(saveCityUseCaseProvider.future);
  await saveCity(city);
  ref.invalidate(selectedCityProvider);
}
