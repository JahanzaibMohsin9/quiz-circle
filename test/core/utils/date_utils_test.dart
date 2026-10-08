import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_circle/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('format and parse date', () {
      final date = DateTime(2024, 12, 31);
      final formatted = AppDateUtils.formatDate(date);
      expect(formatted, '2024-12-31');
      final parsed = AppDateUtils.parseDate(formatted);
      expect(parsed, DateTime(2024, 12, 31));
    });

    test('format and parse date time', () {
      final dt = DateTime(2024, 12, 31, 23, 45);
      final formatted = AppDateUtils.formatDateTime(dt);
      expect(formatted, '2024-12-31 23:45:00');
      final parsed = AppDateUtils.parseDateTime(formatted);
      expect(parsed, DateTime(2024, 12, 31, 23, 45));
    });

    test('display formatting helpers', () {
      final date = DateTime(2024, 1, 15);
      expect(AppDateUtils.formatDateForDisplay(date), 'Jan 15, 2024');
      final dt = DateTime(2024, 1, 15, 9, 5);
      expect(AppDateUtils.formatDateTimeForDisplay(dt), 'Jan 15, 2024 09:05');
      expect(AppDateUtils.formatTimeForDisplay(dt), '09:05');
    });

    test('relative time and time ago', () {
      final now = DateTime.now();
      expect(AppDateUtils.getRelativeTime(now), 'Today');
      expect(
        AppDateUtils.getRelativeTime(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final ago = AppDateUtils.getTimeAgo(fiveMinutesAgo);
      expect(ago, '5 minutes ago');
    });

    test('start/end of day and math helpers', () {
      final date = DateTime(2024, 7, 10, 12, 30);
      expect(AppDateUtils.startOfDay(date), DateTime(2024, 7, 10));
      expect(
        AppDateUtils.endOfDay(date),
        DateTime(2024, 7, 10, 23, 59, 59, 999),
      );
      expect(AppDateUtils.addDays(date, 2), DateTime(2024, 7, 12, 12, 30));
      expect(AppDateUtils.subtractDays(date, 2), DateTime(2024, 7, 8, 12, 30));
      expect(
        AppDateUtils.daysBetween(DateTime(2024, 7), DateTime(2024, 7, 10)),
        9,
      );
    });

    test('formatDuration', () {
      expect(AppDateUtils.formatDuration(1), '1 min');
      expect(AppDateUtils.formatDuration(59), '59 mins');
      expect(AppDateUtils.formatDuration(60), '1 hour');
      expect(AppDateUtils.formatDuration(90), '1 hour 30 mins');
      expect(AppDateUtils.formatDuration(120), '2 hours');
    });
  });
}
