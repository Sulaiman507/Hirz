// اختبارات تنسيق الإزاحة الزمنية / UTC offset formatting tests

import 'package:flutter_test/flutter_test.dart';
import 'package:hirz/core/utils/format_utils.dart';

void main() {
  group('formatUtcOffset', () {
    test('أعداد صحيحة بدون أصفار زائدة / whole hours drop .0', () {
      expect(formatUtcOffset(3.0), 'UTC+3');
      expect(formatUtcOffset(0.0), 'UTC+0');
      expect(formatUtcOffset(-6.0), 'UTC-6');
      expect(formatUtcOffset(-8.0), 'UTC-8');
    });

    test('أنصاف الساعات / half hours', () {
      expect(formatUtcOffset(3.5), 'UTC+3.5');
      expect(formatUtcOffset(4.5), 'UTC+4.5');
      expect(formatUtcOffset(-3.5), 'UTC-3.5');
    });

    test('أرباع الساعات مثل نيبال / quarter hours like Nepal', () {
      expect(formatUtcOffset(5.75), 'UTC+5.75'); // كاتماندو / Kathmandu
      expect(formatUtcOffset(4.5 + 0.25), 'UTC+4.75'); // كابول / Kabul
    });

    test('ضجيج الفاصلة العائمة يُنظف / float noise cleaned', () {
      // 0.1 + 0.2 ≠ 0.3 في الفاصلة العائمة — يجب التنظيف
      expect(formatUtcOffset(0.1 + 0.2), 'UTC+0.3');
      expect(formatUtcOffset(2.9999999999), 'UTC+3');
    });

    test('كل إزاحات المدن المدمجة تعطي نصاً غير فارغ / bundled offsets render', () {
      // قيم مأخوذة من نطاق cities.json الفعلي / range observed in cities.json
      const List<double> bundledOffsets = <double>[
        -8, -6, -5, -4, -3, 0, 1, 2, 3, 3.5, 4, 4.5, 5, 5.5, 5.75,
      ];
      for (final double offset in bundledOffsets) {
        final String label = formatUtcOffset(offset);
        expect(label, startsWith('UTC'));
        expect(label.length, greaterThan(4), reason: 'offset=$offset');
        expect(label, isNot(contains('.0')), reason: 'offset=$offset');
      }
    });
  });
}
