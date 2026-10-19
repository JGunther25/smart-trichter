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

  group('formatLeaderboardTime', () {
    const durations = [3500, 3700, 4200];

    List<String> all(TimeDisplayMode mode) => [
          for (var i = 0; i < durations.length; i++)
            formatLeaderboardTime(durations, i, mode),
        ];

    test('overall shows full times', () {
      expect(all(TimeDisplayMode.overall), ['3.500s', '3.700s', '4.200s']);
    });

    test('gap to leader is relative to first place', () {
      expect(all(TimeDisplayMode.gapToLeader), ['3.500s', '+0.200', '+0.700']);
    });

    test('interval is relative to the row above', () {
      expect(all(TimeDisplayMode.interval), ['3.500s', '+0.200', '+0.500']);
    });

    test('ties show +0.000', () {
      expect(
        formatLeaderboardTime([3500, 3500], 1, TimeDisplayMode.interval),
        '+0.000',
      );
    });

    test('gaps over a minute keep the m:ss format', () {
      expect(formatChugGap(62400), '+1:02.400');
    });

    test('mode cycles overall -> gap -> interval -> overall', () {
      expect(TimeDisplayMode.overall.next, TimeDisplayMode.gapToLeader);
      expect(TimeDisplayMode.gapToLeader.next, TimeDisplayMode.interval);
      expect(TimeDisplayMode.interval.next, TimeDisplayMode.overall);
    });
  });
}
