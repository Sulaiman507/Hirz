// شاشة اختيار المدن / City selection screen
// بحث فوري + قائمة + نموذج إحداثيات يدوية

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/city.dart';
import '../providers/city_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/manual_coordinates_form.dart';

/// بحث + قائمة مدن + إدخال يدوي / Search + city list + manual entry
class CitySelectionScreen extends ConsumerStatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  ConsumerState<CitySelectionScreen> createState() =>
      _CitySelectionScreenState();
}

class _CitySelectionScreenState extends ConsumerState<CitySelectionScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// بحث مؤجل 250ms — يمنع فلترة عند كل حرف / 250ms debounced search
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(citySearchQueryProvider.notifier).state = value;
    });
  }

  void _showManualForm() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).tr('manualCoordinates')),
        content: SingleChildScrollView(
          child: ManualCoordinatesForm(
            onSubmit: (City city) async {
              Navigator.of(dialogContext).pop();
              await selectCity(ref, city);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<City>> citiesAsync =
        ref.watch(filteredCitiesProvider);
    final String languageCode =
        ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('citySelectionTitle'))),
      body: Column(
        children: <Widget>[
          // حقل البحث / Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.tr('searchCity'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // القائمة / List
          Expanded(
            child: citiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  Center(child: Text(l10n.tr('error'))),
              data: (List<City> cities) {
                if (cities.isEmpty) {
                  return Center(child: Text(l10n.tr('noResults')));
                }
                return ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (BuildContext context, int index) {
                    final City city = cities[index];
                    final String name =
                        languageCode == 'ar' ? city.nameAr : city.nameEn;
                    final String country = languageCode == 'ar'
                        ? city.countryAr
                        : city.countryEn;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(country),
                      trailing: Text(
                        'UTC${city.timezoneOffsetHours >= 0 ? '+' : ''}${city.timezoneOffsetHours}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onTap: () async {
                        await selectCity(ref, city);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualForm,
        icon: const Icon(Icons.edit_location_alt_outlined),
        label: Text(l10n.tr('manualCoordinates')),
      ),
    );
  }
}