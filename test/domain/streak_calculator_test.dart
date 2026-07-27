import 'package:clean_tracker/features/tracker/domain/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed reference "now" so results never depend on the wall clock.
  final DateTime now = DateTime.utc(2026, 1, 10, 12, 0, 0);

  group('currentStreak', () {
    test('measures the active attempt up to now', () {
      final attempts = [
        AttemptSpan(startedAt: DateTime.utc(2026, 1, 8, 12)),
      ];
      expect(currentStreak(attempts, now), const Duration(days: 2));
    });

    test('ignores closed attempts', () {
      final attempts = [
        AttemptSpan(
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 3),
        ),
      ];
      expect(currentStreak(attempts, now), Duration.zero);
    });

    test('returns zero when the start is in the future', () {
      final attempts = [
        AttemptSpan(startedAt: DateTime.utc(2026, 1, 20)),
      ];
      expect(currentStreak(attempts, now), Duration.zero);
    });
  });

  group('longestStreak', () {
    test('picks the longest span across closed and active attempts', () {
      final attempts = [
        AttemptSpan(
          startedAt: DateTime.utc(2025, 12, 1),
          endedAt: DateTime.utc(2025, 12, 6), // 5 days
        ),
        AttemptSpan(startedAt: DateTime.utc(2026, 1, 8, 12)), // 2 days active
      ];
      expect(longestStreak(attempts, now), const Duration(days: 5));
    });
  });

  group('totalCleanTime / days', () {
    test('sums every attempt and never resets on relapse', () {
      final attempts = [
        AttemptSpan(
          startedAt: DateTime.utc(2025, 12, 1),
          endedAt: DateTime.utc(2025, 12, 6), // 5 days
        ),
        AttemptSpan(startedAt: DateTime.utc(2026, 1, 8, 12)), // 2 days
      ];
      expect(totalCleanDays(attempts, now), 7);
    });
  });

  group('DST safety', () {
    test('streak measures absolute elapsed time, not wall-clock days', () {
      // A calendar span that crosses a spring-forward transition contains one
      // fewer real hour than an ordinary two-day span. The streak must reflect
      // the 47 real hours that actually elapsed, not "2 days". We express the
      // instants with an explicit UTC base so the result is independent of the
      // machine time zone running the test.
      final DateTime start = DateTime.utc(2026, 3, 28, 10);
      final DateTime later = start.add(const Duration(hours: 47));
      final attempts = [AttemptSpan(startedAt: start)];

      final Duration d = currentStreak(attempts, later);
      expect(d, const Duration(hours: 47));
      expect(d.inDays, 1); // 47h -> 1 whole day + 23h, never rounded up to 2
    });
  });

  group('StreakParts', () {
    test('decomposes a duration', () {
      final parts = StreakParts.of(
        const Duration(days: 3, hours: 4, minutes: 5, seconds: 6),
      );
      expect(parts.days, 3);
      expect(parts.hours, 4);
      expect(parts.minutes, 5);
      expect(parts.seconds, 6);
    });

    test('clamps negatives to zero', () {
      final parts = StreakParts.of(const Duration(seconds: -10));
      expect(parts.seconds, 0);
    });
  });
}
