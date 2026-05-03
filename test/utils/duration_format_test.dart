import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/utils/duration_format.dart';

void main() {
  group('formatChugDuration', () {
    test('formats sub-minute durations as s.SSSs', () {
      expect(formatChugDuration(3235), '3.235s');
      expect(formatChugDuration(1000), '1.000s');
      expect(formatChugDuration(500), '0.500s');
      expect(formatChugDuration(59999), '59.999s');
    });

    test('formats exact minute boundary as mm:ss.SSSs', () {
      expect(formatChugDuration(60000), '1:00.000s');
    });

    test('formats over-60-second durations as m:ss.SSSs', () {
      expect(formatChugDuration(62400), '1:02.400s');
      expect(formatChugDuration(125000), '2:05.000s');
    });

    test('pads millis to three digits', () {
      expect(formatChugDuration(1001), '1.001s');
      expect(formatChugDuration(1010), '1.010s');
    });

    test('handles zero', () {
      expect(formatChugDuration(0), '0.000s');
    });
  });
}
