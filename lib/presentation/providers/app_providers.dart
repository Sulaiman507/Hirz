// الـ providers الأساسية: SharedPreferences + المستودعات الثلاثة
// Core providers: SharedPreferences + the three repositories

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/city_local_datasource.dart';
import '../../data/datasources/prayer_times_local_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/city_repository_impl.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/city_repository.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/city_usecases.dart';
import '../../domain/usecases/get_prayer_times.dart';
import '../../domain/usecases/settings_usecases.dart';

/// SharedPreferences — يُحمّل مرة واحدة / Loaded once
final FutureProvider<SharedPreferences> sharedPreferencesProvider =
    FutureProvider<SharedPreferences>(
        (Ref ref) async => SharedPreferences.getInstance());

/// مصادر البيانات / Datasources
final Provider<CityLocalDatasource> cityLocalDatasourceProvider =
    Provider<CityLocalDatasource>((Ref ref) => CityLocalDatasource());

final Provider<PrayerTimesLocalDatasource> prayerTimesLocalDatasourceProvider =
    Provider<PrayerTimesLocalDatasource>(
        (Ref ref) => const PrayerTimesLocalDatasource());

/// المستودعات / Repositories
final FutureProvider<CityRepository> cityRepositoryProvider =
    FutureProvider<CityRepository>((Ref ref) async {
  final SharedPreferences prefs = await ref.watch(sharedPreferencesProvider.future);
  return CityRepositoryImpl(ref.read(cityLocalDatasourceProvider), prefs);
});

final Provider<PrayerTimesRepository> prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>(
  (Ref ref) => PrayerTimesRepositoryImpl(
      ref.read(prayerTimesLocalDatasourceProvider)),
);

final FutureProvider<SettingsRepository> settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((Ref ref) async {
  final SharedPreferences prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepositoryImpl(SettingsLocalDatasource(prefs));
});

/// حالات الاستخدام / Use cases
final FutureProvider<GetPrayerTimes> getPrayerTimesUseCaseProvider =
    FutureProvider<GetPrayerTimes>((Ref ref) async {
  final PrayerTimesRepository repository =
      ref.watch(prayerTimesRepositoryProvider);
  return GetPrayerTimes(repository);
});

final FutureProvider<SearchCities> searchCitiesUseCaseProvider =
    FutureProvider<SearchCities>((Ref ref) async {
  final CityRepository repository = await ref.watch(cityRepositoryProvider.future);
  return SearchCities(repository);
});

final FutureProvider<GetAllCities> getAllCitiesUseCaseProvider =
    FutureProvider<GetAllCities>((Ref ref) async {
  final CityRepository repository = await ref.watch(cityRepositoryProvider.future);
  return GetAllCities(repository);
});

final FutureProvider<GetSavedCity> getSavedCityUseCaseProvider =
    FutureProvider<GetSavedCity>((Ref ref) async {
  final CityRepository repository = await ref.watch(cityRepositoryProvider.future);
  return GetSavedCity(repository);
});

final FutureProvider<SaveCity> saveCityUseCaseProvider =
    FutureProvider<SaveCity>((Ref ref) async {
  final CityRepository repository = await ref.watch(cityRepositoryProvider.future);
  return SaveCity(repository);
});

final FutureProvider<GetSettings> getSettingsUseCaseProvider =
    FutureProvider<GetSettings>((Ref ref) async {
  final SettingsRepository repository =
      await ref.watch(settingsRepositoryProvider.future);
  return GetSettings(repository);
});

final FutureProvider<SaveSettings> saveSettingsUseCaseProvider =
    FutureProvider<SaveSettings>((Ref ref) async {
  final SettingsRepository repository =
      await ref.watch(settingsRepositoryProvider.future);
  return SaveSettings(repository);
});