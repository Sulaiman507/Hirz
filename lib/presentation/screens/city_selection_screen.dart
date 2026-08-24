// شاشة اختيار المدن الفاخرة / Luxury city selection screen
// بحث بإطار ذهبي متوهج + بطاقات مدن بتدرجات راقية
// Glowing gold search field + refined gradient city cards

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/city.dart';
import '../providers/city_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/luxury_components.dart';
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
          // حقل البحث الفاخر / luxury search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LuxurySearchField(
              hint: l10n.tr('searchCity'),
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
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: cities.length,
                  itemBuilder: (BuildContext context, int index) {
                    final City city = cities[index];
                    final String name =
                        languageCode == 'ar' ? city.nameAr : city.nameEn;
                    final String country = languageCode == 'ar'
                        ? city.countryAr
                        : city.countryEn;
                    return _LuxuryCityTile(
                      name: name,
                      country: country,
                      offsetLabel:
                          'UTC${city.timezoneOffsetHours >= 0 ? '+' : ''}${city.timezoneOffsetHours}',
                      isCustom: city.isCustom,
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

/// بطاقة مدينة فاخرة / Luxury city tile
class _LuxuryCityTile extends StatelessWidget {
  final String name;
  final String country;
  final String offsetLabel;
  final bool isCustom;
  final VoidCallback onTap;

  const _LuxuryCityTile({
    required this.name,
    required this.country,
    required this.offsetLabel,
    required this.isCustom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.goldBright
                    .withValues(alpha: isCustom ? 0.55 : 0.28),
                width: isCustom ? 1.4 : 1,
              ),
              // تدرج يضيء يسار البطاقة / gradient lighting the tile start
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: <Color>[
                  AppColors.goldBright.withValues(alpha: isDark ? 0.10 : 0.14),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  isCustom
                      ? Icons.my_location_outlined
                      : Icons.location_city_outlined,
                  size: 20,
                  color: AppColors.goldBright,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.goldBright.withValues(alpha: 0.14),
                  ),
                  child: Text(
                    offsetLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.goldBright,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
