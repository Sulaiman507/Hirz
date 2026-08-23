// نموذج إحداثيات يدوية مع تحقق / Manual coordinates form with validation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/nearest_city.dart';
import '../../domain/entities/city.dart';
import '../providers/city_providers.dart';

/// نتيجة النموذج / Form result callback
typedef CityCreated = void Function(City city);

/// نموذج إدخال مدينة يدوياً / Manual city entry form
class ManualCoordinatesForm extends ConsumerStatefulWidget {
  final CityCreated onSubmit;

  const ManualCoordinatesForm({super.key, required this.onSubmit});

  @override
  ConsumerState<ManualCoordinatesForm> createState() =>
      _ManualCoordinatesFormState();
}

class _ManualCoordinatesFormState
    extends ConsumerState<ManualCoordinatesForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _offsetController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  /// تحقق من نطاق الإحداثيات / Validate coordinate ranges
  String? _validateLatitude(String? value) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double? lat = double.tryParse(value ?? '');
    if (lat == null || lat < -90 || lat > 90) {
      return l10n.tr('invalidLatitude');
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double? lng = double.tryParse(value ?? '');
    if (lng == null || lng < -180 || lng > 180) {
      return l10n.tr('invalidLongitude');
    }
    return null;
  }

  void _submit() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String name = _nameController.text.trim();
    final double latitude = double.parse(_latController.text.trim());
    final double longitude = double.parse(_lngController.text.trim());
    final double offset =
        double.tryParse(_offsetController.text.trim()) ?? 0.0;

    final City draft = City(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      nameEn: name,
      nameAr: name,
      countryEn: l10n.tr('manualCoordinates'),
      countryAr: l10n.tr('manualCoordinates'),
      latitude: latitude,
      longitude: longitude,
      timezoneOffsetHours: offset,
      isCustom: true,
    );

    // ── وراثة timezoneId/methodId من أقرب مدينة معروفة (≤300كم) ──
    // يصلح فقدان DST وطرق الحساب الإقليمية للمدن اليدوية.
    // Inherit tz + method from the nearest known city (≤300km) —
    // fixes DST and regional-method loss for manual cities.
    final List<City> known =
        ref.read(citiesProvider).valueOrNull ?? const <City>[];
    final City? nearest = nearestKnownCity(
      latitude: latitude,
      longitude: longitude,
      known: known,
    );
    final City city = nearest == null
        ? draft
        : draft.copyWith(
            timezoneId: nearest.timezoneId,
            methodId: nearest.methodId,
          );
    widget.onSubmit(city);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.tr('cityName')),
            validator: (String? value) =>
                (value == null || value.trim().isEmpty) ? '*' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.tr('latitude')),
                  validator: _validateLatitude,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.tr('longitude')),
                  validator: _validateLongitude,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _offsetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.tr('timezoneOffset')),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.tr('cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.tr('save')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}