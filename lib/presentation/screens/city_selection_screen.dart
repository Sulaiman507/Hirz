// شاشة اختيار المدن الفاخرة / Luxury city selection screen
// بحث بإطار ذهبي متوهج + قائمة مجمعة حسب الدولة بعدّاد نتائج
// Glowing gold search field + country-grouped list with results counter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/auto_location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../domain/entities/city.dart';
import '../providers/app_providers.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  /// تحديد الموقع تلقائياً واختيار أقرب مدينة / auto-locate → nearest bundled city
  Future<void> _locateMe(AppLocalizations l10n, String languageCode) async {
    if (_locating) return;
    setState(() => _locating = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    try {
      const AutoLocationService service = AutoLocationService();
      final Position position = await service.getCurrentPosition();
      final List<City> cities =
          await ref.read(getAllCitiesUseCaseProvider.future);
      final LocationResult result = service.nearestCity(cities, position);
      await selectCity(ref, result.city);
      final String cityName =
          languageCode == 'ar' ? result.city.nameAr : result.city.nameEn;
      messenger.showSnackBar(
        SnackBar(
          content:
              Text('${l10n.tr('locatedTo')} $cityName'),
          duration: const Duration(seconds: 3),
        ),
      );
      if (mounted) navigator.pop();
    } on Exception {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tr('locationFailed'))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<City>> citiesAsync =
        ref.watch(filteredCitiesProvider);
    final String languageCode =
        ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar';
    final int filteredCount =
        ref.watch(filteredCitiesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      // شاشة كاملة بدون شريط علوي / fullscreen without top bar
      backgroundColor: null,
      body: Column(
        children: <Widget>[
          // حقل البحث + زر الإغلاق / search field + close button
          Padding(
            // SafeArea يدوية: ارتفاع شريط الحالة + التنفس الأصلي
            // Manual SafeArea: status-bar height + original breathing room
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 12,
              8,
              8,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: LuxurySearchField(
                    hint: l10n.tr('searchCity'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
                // تحديد الموقع تلقائياً / auto-locate button
                IconButton(
                  tooltip: l10n.tr('locateMe'),
                  icon: _locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  onPressed: () => _locateMe(l10n, languageCode),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.tr('close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // عدّاد النتائج / results counter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.tr('resultsCount').replaceAll('{n}', '$filteredCount'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
          ),
          // القائمة المجمّعة حسب الدولة / list grouped by country
          Expanded(
            child: citiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) =>
                  Center(child: Text(l10n.tr('error'))),
              data: (List<City> cities) {
                if (cities.isEmpty) {
                  // حالة فراغ مصممة / designed empty state
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: AppColors.goldBright.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.tr('noResults'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  );
                }

                // ترتيب حسب الدولة ثم المدينة / sort by country then city
                final List<_SortedCity> sorted = cities
                    .map(
                      (City c) => _SortedCity(
                        city: c,
                        label: languageCode == 'ar' ? c.nameAr : c.nameEn,
                        countryLabel:
                            languageCode == 'ar' ? c.countryAr : c.countryEn,
                      ),
                    )
                    .toList()
                  ..sort((_SortedCity a, _SortedCity b) {
                    final int byCountry =
                        a.countryLabel.compareTo(b.countryLabel);
                    if (byCountry != 0) return byCountry;
                    return a.label.compareTo(b.label);
                  });

                // تجميع متتالي: عنوان لكل دولة يتبعه بطاقاتها
                // Contiguous grouping: a header per country followed by its tiles
                final List<Object> rows = <Object>[]; // String عنوان | بطاقة
                String? currentGroup;
                for (final _SortedCity c in sorted) {
                  if (currentGroup != c.countryLabel) {
                    rows.add(c.countryLabel);
                    currentGroup = c.countryLabel;
                  }
                  rows.add(c);
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Object row = rows[index];
                    if (row is String) {
                      return _LuxurySectionHeader(title: row);
                    }
                    final _SortedCity sc = row as _SortedCity;
                    return _LuxuryCityTile(
                      name: sc.label,
                      country: sc.countryLabel,
                      offsetLabel:
                          formatUtcOffset(sc.city.timezoneOffsetHours),
                      isCustom: sc.city.isCustom,
                      showCountry: false,
                      onTap: () async {
                        await selectCity(ref, sc.city);
                        if (mounted) Navigator.of(context).pop();
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

/// عنوان قسم دولة بشريط ذهبي / country section header with a gold bar
class _LuxurySectionHeader extends StatelessWidget {
  final String title;

  const _LuxurySectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.goldBright,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// مدينة مرتبة مع تسميات معروضة حسب اللغة / sorted city with localized labels
class _SortedCity {
  final City city;
  final String label;
  final String countryLabel;

  const _SortedCity({
    required this.city,
    required this.label,
    required this.countryLabel,
  });
}

/// بطاقة مدينة فاخرة / Luxury city tile
class _LuxuryCityTile extends StatelessWidget {
  final String name;
  final String country;
  final String offsetLabel;
  final bool isCustom;
  final VoidCallback onTap;
  final bool showCountry;

  const _LuxuryCityTile({
    required this.name,
    required this.country,
    required this.offsetLabel,
    required this.isCustom,
    required this.onTap,
    this.showCountry = true,
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
                      if (showCountry)
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
