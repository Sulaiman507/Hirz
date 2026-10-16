// العدّاد التنازلي للصلاة القادمة / Countdown timer to the next prayer
// الحالة الوحيدة التي نستخدم فيها setState (Timer) / The only setState use (Timer)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import 'glass_card.dart';
import '../../domain/entities/prayer_time.dart';
import '../providers/prayer_providers.dart';
import 'prayer_badge.dart';
import 'shimmer_text.dart';
import 'circular_countdown_ring.dart';

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
    // تحديث كل ثانية — إعادة البناء تحسب كل شيء من البيانات مباشرة
    // Tick every second — rebuild derives everything from provider data
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() {});
    });
  }

  /// أول صلاة وقتها بعد الآن — بمقارنة epoch آمنة عبر الأنواع
  /// First prayer after now — safe epoch comparison across kinds
  PrayerTime? _findNextPrayer(DailyPrayerTimes daily, int nowMs) {
    for (final PrayerTime pt in daily.times) {
      if (pt.time.millisecondsSinceEpoch > nowMs) return pt;
    }
    return null;
  }

  /// آخر صلاة دخل وقتها (قبل الفجر = عشاء أمس)
  /// Last prayer begun (before fajr = yesterday's isha)
  PrayerTime _findCurrentPrayer(DailyPrayerTimes daily, int nowMs) {
    PrayerTime current = daily.times.last;
    for (final PrayerTime pt in daily.times) {
      if (pt.time.millisecondsSinceEpoch <= nowMs) {
        current = pt;
      } else {
        break;
      }
    }
    return current;
  }

  /// تقدم الحلقة 0..1 من الصلاة السابقة إلى القادمة
  /// Ring progress 0..1 from the previous prayer to the next
  /// (قبل الفجر: نافذة تقديرية 6 ساعات — لا نملك وقت عشاء الأمس)
  /// (Before fajr: estimated 6h window — yesterday's isha is unavailable)
  double _ringProgress(DailyPrayerTimes daily, PrayerTime next, int nowMs) {
    int? startMs;
    for (final PrayerTime pt in daily.times) {
      final int t = pt.time.millisecondsSinceEpoch;
      if (t <= nowMs) {
        startMs = t;
      } else {
        break;
      }
    }
    final int s = startMs ?? nowMs - const Duration(hours: 6).inMilliseconds;
    final int spanMs = next.time.millisecondsSinceEpoch - s;
    if (spanMs <= 0) return 0.0;
    return ((nowMs - s) / spanMs).clamp(0.0, 1.0);
  }

  /// عدّاد فجر الغد بعد انتهاء صلوات اليوم / Tomorrow-fajr countdown
  /// يُعاد بناؤه كل ثانية عبر الـ Timer نفسه / rebuilt every second by same timer
  Widget _buildTomorrowCountdown(AppLocalizations l10n) {
    final AsyncValue<DailyPrayerTimes> tomorrow = ref.watch(
      tomorrowTimesProvider,
    );

    return tomorrow.when(
      loading: () =>
          const GlassCard(child: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) => GlassCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.tr('error')),
              TextButton(
                onPressed: () => ref.invalidate(tomorrowTimesProvider),
                child: Text(l10n.tr('retry')),
              ),
            ],
          ),
        ),
      ),
      data: (DailyPrayerTimes tomorrowDaily) {
        final PrayerTime fajr = tomorrowDaily.times.first; // فجر الغد
        final DateTime now = ref.watch(cityNowProvider);
        final Duration remaining = fajr.time.difference(now);

        return GlassCard(
          child: Column(
            children: <Widget>[
              Text(
                l10n.tr('nextPrayer'),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.goldBright),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tr(fajr.prayer.name),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CircularCountdownRing(
                progress: 0.0, // بداية دورة جديدة / fresh cycle
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      formatDuration(
                        remaining.isNegative ? Duration.zero : remaining,
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    Text(
                      l10n.tr('timeRemaining'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
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
      loading: () =>
          const GlassCard(child: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) => GlassCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.tr('error')),
              TextButton(
                onPressed: () => ref.invalidate(prayerTimesProvider),
                child: Text(l10n.tr('retry')),
              ),
            ],
          ),
        ),
      ),
      data: (DailyPrayerTimes daily) {
        // كل القيم تُشتق هنا مباشرة — بلا حالة مخزنة تُعدَّل أثناء البناء
        // Everything is derived here — no cached state mutated during build
        // "الآن" بتوقيت المدينة (متسق مع انزياح المدن اليدوية الكسرية)
        // City-local "now" (consistent with fractional manual-city shifts)
        final int nowMs = ref
            .watch(cityNowProvider)
            .millisecondsSinceEpoch;
        final PrayerTime? next = _findNextPrayer(daily, nowMs);
        if (next == null) {
          // كل صلوات اليوم انتهت → العدّاد يتحول لفجر الغد
          // All today's prayers done → countdown switches to tomorrow's fajr
          return _buildTomorrowCountdown(l10n);
        }
        final PrayerTime current = _findCurrentPrayer(daily, nowMs);
        final Duration remaining = Duration(
          milliseconds: next.time.millisecondsSinceEpoch - nowMs,
        );
        final double progress = _ringProgress(daily, next, nowMs);

        return GlassCard(
          // خلفية بيج فاتحة هادئة للمربع / calm light-beige backdrop
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFEFE7D6).withValues(alpha: 0.14)
              : const Color(0xFFEFE7D6).withValues(alpha: 0.85),
          child: Column(
            children: <Widget>[
              // الصلاة الحالية: شارتها + اسمها بنص هادئ
              // current prayer: its badge + calm plain name
              Row(
                children: <Widget>[
                  PrayerBadge(label: l10n.tr('badgeCurrent'), bright: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.tr(current.prayer.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // الصلاة القادمة: الاسم المتلألئ في مركز المربع
              // next prayer: shimmering name at the center of the box
              ShimmerText(
                l10n.tr(next.prayer.name),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                baseColor: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.9),
              ),
              Text(
                l10n.tr('nextPrayer'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.55),
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
                        remaining.isNegative ? Duration.zero : remaining,
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    Text(
                      l10n.tr('timeRemaining'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.6),
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
