// العدّاد التنازلي للصلاة القادمة / Countdown timer to the next prayer
// الحالة الوحيدة التي نستخدم فيها setState (Timer) / The only setState use (Timer)

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/prayer_providers.dart';
import '../providers/settings_providers.dart';

/// عدّاد تنازلي يتحدث كل ثانية / Updates every second
class CountdownTimer extends ConsumerStatefulWidget {
  const CountdownTimer({super.key});

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث كل ثانية / Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف مؤقت لمنع التسريبات / Cancel to avoid leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<DailyPrayerTimes> times = ref.watch(prayerTimesProvider);

    return times.when(
      loading: () => const GlassCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => GlassCard(
        child: Center(child: Text(l10n.tr('error'))),
      ),
      data: (DailyPrayerTimes daily) {
        final PrayerTime? next = daily.nextPrayer(DateTime.now());
        if (next == null) {
          return GlassCard(
            child: Text(
              l10n.tr('nextPrayer'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }
        final Duration remaining = next.time.difference(DateTime.now());
        final String languageCode =
            ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar';
        return GlassCard(
          child: Column(
            children: <Widget>[
              Text(
                l10n.tr('nextPrayer'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.goldBright,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tr(next.prayer.name),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // HH:MM:SS — الوقت المتبقي / Remaining time
              Text(
                formatDuration(remaining.isNegative ? Duration.zero : remaining),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
              ),
              Text(
                l10n.tr('timeRemaining'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}