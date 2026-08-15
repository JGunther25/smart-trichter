import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trichter/utils/date_format.dart';

void main() {
  group('formatChugTimestamp', () {
    test('formats today as "Today, HH:mm"', () {
      final now = DateTime.now();
      final loggedAt = DateTime(now.year, now.month, now.day, 14, 5);
      expect(formatChugTimestamp(loggedAt), 'Today, 14:05');
    });

    test('formats yesterday as "Yesterday, HH:mm"', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final loggedAt =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 30);
      expect(formatChugTimestamp(loggedAt), 'Yesterday, 09:30');
    });

    test('formats older dates as "Mon d, HH:mm"', () {
      final loggedAt = DateTime(2024, 6, 1, 12, 0);
      expect(formatChugTimestamp(loggedAt), 'Jun 1, 12:00');
    });

    test('pads single-digit minutes and hours', () {
      final loggedAt = DateTime(2024, 1, 5, 3, 4);
      expect(formatChugTimestamp(loggedAt), 'Jan 5, 03:04');
    });
  });
}
