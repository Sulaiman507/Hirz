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

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required City city,
    required DateTime date,
    required AppSettings settings,
  }) async {
    lastDate = date;
    throw UnimplementedError('capture only');
  }
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

  test('tomorrow يمرر اليوم التالي كتاريخ كنداري DST-آمن (آخر الشهر)', () async {
    final _CaptureRepo repo = _CaptureRepo();
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);
    // 31 كانون الثاني → يجب أن يصبح 1 شباط لا 32/1 (لا انهيار نهاية الشهر)
    final DateTime now = DateTime(2026, 1, 31, 23, 30);

    await expectLater(
      flow.tomorrow(city: city, settings: settings, now: now),
      throwsA(isA<UnimplementedError>()),
    );

    expect(repo.lastDate, DateTime(2026, 2, 1));
  });

  test('بدون now: today/tomorrow يعملان (ساعة النظام) ولا يفشلان إلا في الـ repo',
      () async {
    final _CaptureRepo repo = _CaptureRepo();
    final GetPrayerTimesFlow flow = GetPrayerTimesFlow(repo);

    await expectLater(
      flow.today(city: city, settings: settings),
      throwsA(isA<UnimplementedError>()),
    );
    expect(repo.lastDate, isNotNull);
  });
}
