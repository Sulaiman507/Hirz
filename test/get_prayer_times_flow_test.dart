// اختبارات مُنسّق اليوم/الغد / GetPrayerTimesFlow tests
// يتحقق من أن «الغد» يُمرَّر كتاريخ كنداري آمن مع DST (ولا ينهار آخر الشهر)
// وأن «اليوم» يمرر التاريخ المعطى نفسه.

import 'package:flutter_test/flutter_test.dart';

import 'package:hirz/domain/entities/app_settings.dart';
import 'package:hirz/domain/entities/city.dart';
import 'package:hirz/domain/entities/prayer_time.dart';
import 'package:hirz/domain/repositories/prayer_times_repository.dart';
import 'package:hirz/domain/usecases/get_prayer_times_flow.dart';

/// مستودع وهمي يلتقط التاريخ المطلوب ثم يفشل (لا حاجة لبناء نتيجة حقيقية)
class _CaptureRepo implements PrayerTimesRepository {
  DateTime? lastDate;

  /// "الآن" المزيف بتوقيت المدينة — يُستخدم عندما لا يُحقن now
  DateTime? fakeCityNow;

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) async {
    lastDate = date;
    throw UnimplementedError('capture only');
  }

  @override
  DateTime cityNow(City city) => fakeCityNow ?? DateTime.now();

  @override
  Duration timeUntilCityMidnight(City city) => const Duration(hours: 1);

  @override
  Duration cityUtcOffsetNow(City city) =>
      Duration(minutes: (city.timezoneOffsetHours * 60).round());
}

void main() {
  final City city = City(
    id: 'test',
    nameEn: 'Test',
    nameAr: 'اختبار',
    countryEn: '',
    countryAr: '',
    latitude: 21.4,
    longitude: 39.8,
    timezoneOffsetHours: 3,
  );
  final AppSettings settings = AppSettings(
    languageCode: 'ar',
    isDarkMode: true,
    method: CalculationMethod.ummAlQura,
    madhab: Madhab.shafi,
    use24HourFormat: false,
    iqamahOffsets: Map<String, int>.from(AppSettings.defaultIqamahOffsets),
  );

  test('today يمرر التاريخ المعطى نفسه', () async {
    final _CaptureRepo repo = _CaptureRepo();
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);
    final DateTime now = DateTime(2026, 4, 10, 8, 0);

    await expectLater(
      flow.today(city: city, settings: settings, now: now),
      throwsA(isA<UnimplementedError>()),
    );

    expect(repo.lastDate, now);
  });

  test(
    'tomorrow يمرر اليوم التالي كتاريخ كنداري DST-آمن (آخر الشهر)',
    () async {
      final _CaptureRepo repo = _CaptureRepo();
      final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);
      // 31 كانون الثاني → يجب أن يصبح 1 شباط لا 32/1 (لا انهيار نهاية الشهر)
      final DateTime now = DateTime(2026, 1, 31, 23, 30);

      await expectLater(
        flow.tomorrow(city: city, settings: settings, now: now),
        throwsA(isA<UnimplementedError>()),
      );

      expect(repo.lastDate, DateTime(2026, 2, 1));
    },
  );

  test(
    'بدون now: today/tomorrow يعملان (ساعة النظام) ولا يفشلان إلا في الـ repo',
    () async {
      final _CaptureRepo repo = _CaptureRepo();
      final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);

      await expectLater(
        flow.today(city: city, settings: settings),
        throwsA(isA<UnimplementedError>()),
      );
      expect(repo.lastDate, isNotNull);
    },
  );

  test(
    'today بدون now: يستخدم "الآن" بتوقيت المدينة لا بتوقيت الجهاز',
    () async {
      final _CaptureRepo repo = _CaptureRepo();
      // كأن الجهاز في منطقة مختلفة: توقيت المدينة = 00:30 يوم 15
      repo.fakeCityNow = DateTime(2026, 10, 15, 0, 30);
      final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);

      await expectLater(
        flow.today(city: city, settings: settings),
        throwsA(isA<UnimplementedError>()),
      );

      expect(repo.lastDate, repo.fakeCityNow);
    },
  );

  test('tomorrow بدون now: الغد بتقويم المدينة', () async {
    final _CaptureRepo repo = _CaptureRepo();
    repo.fakeCityNow = DateTime(2026, 10, 15, 0, 30);
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);

    await expectLater(
      flow.tomorrow(city: city, settings: settings),
      throwsA(isA<UnimplementedError>()),
    );

    expect(repo.lastDate, DateTime(2026, 10, 16));
  });

  test('timeUntilCityMidnight يفوّض للمستودع', () {
    final _CaptureRepo repo = _CaptureRepo();
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);

    expect(flow.timeUntilCityMidnight(city), const Duration(hours: 1));
  });
}
