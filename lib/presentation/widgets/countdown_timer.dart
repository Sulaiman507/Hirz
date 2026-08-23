// العدّاد التنازلي للصلاة القادمة / Countdown timer to the next prayer
// الحالة الوحيدة التي نستخدم فيها setState (Timer) / The only setState use (Timer)

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/prayer_providers.dart';
import 'circular_countdown_ring.dart';
/// عدّاد تنازلي يتحدث كل ثانية / Updates every second
class CountdownTimer extends ConsumerStatefulWidget {
  const CountdownTimer({super.key});

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  Timer? _timer;
  // الوقت المتبقي يُخزن هنا — الـ setState يعيد بناء هذا الويدجت فقط
  // Remaining time stored here — setState rebuilds only this widget
  Duration _remaining = Duration.zero;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // تحديث كل ثانية / Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      final DailyPrayerTimes? daily = ref.read(prayerTimesProvider).valueOrNull;
      if (daily == null) return;
      _recompute(daily);
      setState(() {});
    });
  }

  /// حساب المتبقي والتقدم من بيانات اليوم / Compute remaining + progress
  void _recompute(DailyPrayerTimes daily) {
    final DateTime now = DateTime.now();
    final PrayerTime? next = daily.nextPrayer(now);
    if (next == null) {
      // صلوات اليوم انتهت — الحساب يتم في _buildTomorrowCountdown
      // Today's prayers done — computed in _buildTomorrowCountdown
      _remaining = Duration.zero;
      _progress = 1.0;
      return;
    }
    _remaining = next.time.difference(now);
    final List<PrayerTime> passed = daily.times
        .where((PrayerTime pt) => pt.time.isBefore(now))
        .toList();
    final DateTime? previousTime = passed.isEmpty ? null : passed.last.time;
    final Duration totalSpan = previousTime == null
        ? const Duration(hours: 6)
        : next.time.difference(previousTime);
    _progress = totalSpan.inSeconds <= 0
        ? 0.0
        : 1.0 -
            (_remaining.inSeconds / max(totalSpan.inSeconds, 1))
                .clamp(0.0, 1.0);
  }

  /// عدّاد فجر الغد بعد انتهاء صلوات اليوم / Tomorrow-fajr countdown
  /// يُعاد بناؤه كل ثانية عبر الـ Timer نفسه / rebuilt every second by same timer
  Widget _buildTomorrowCountdown(AppLocalizations l10n) {
    final AsyncValue<DailyPrayerTimes> tomorrow =
        ref.watch(tomorrowTimesProvider);

    return tomorrow.when(
      loading: () => const GlassCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => GlassCard(
        child: Center(child: Text(l10n.tr('error'))),
      ),
      data: (DailyPrayerTimes tomorrowDaily) {
        final PrayerTime fajr = tomorrowDaily.times.first; // فجر الغد
        final Duration remaining = fajr.time.difference(DateTime.now());

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
                l10n.tr(fajr.prayer.name),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              CircularCountdownRing(
                progress: 0.0, // بداية دورة جديدة / fresh cycle
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      formatDuration(
                          remaining.isNegative ? Duration.zero : remaining),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    Text(
                      l10n.tr('timeRemaining'),
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
        // إعادة الحساب عند تغير البيانات (وليس كل ثانية) / recompute on data change only
        _recompute(daily);
        final PrayerTime? next = daily.nextPrayer(DateTime.now());
        if (next == null) {
          // كل صلوات اليوم انتهت → العدّاد يتحول لفجر الغد
          // All today's prayers done → countdown switches to tomorrow's fajr
          return _buildTomorrowCountdown(l10n);
        }
        final Duration remaining = _remaining;
        final double progress = _progress;

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
              const SizedBox(height: 16),
              // الحلقة الذهبية حول الوقت المتبقي / Gold ring around remaining time
              CircularCountdownRing(
                progress: progress,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // HH:MM:SS — الوقت المتبقي بأرقام tabular
                    // Remaining time with tabular figures (no layout shift)
                    Text(
                      formatDuration(
                          remaining.isNegative ? Duration.zero : remaining),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    Text(
                      l10n.tr('timeRemaining'),
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}