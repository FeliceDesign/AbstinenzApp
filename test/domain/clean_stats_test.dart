import 'package:clean_tracker/features/relapse/domain/clean_stats.dart';
import 'package:clean_tracker/features/tracker/domain/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clean total sums attempts and never drops to zero after a relapse', () {
    final now = DateTime.utc(2026, 1, 11);
    final attempts = [
      // 5 clean days, then a relapse gap...
      AttemptSpan(
        startedAt: DateTime.utc(2026, 1, 1),
        endedAt: DateTime.utc(2026, 1, 6),
      ),
      // ...then 3 more days on the active attempt.
      AttemptSpan(startedAt: DateTime.utc(2026, 1, 8)),
    ];

    final stats = cleanStats(attempts, now);

    expect(stats.cleanDays, 8); // 5 + 3
    expect(stats.trackedDays, 10); // 01-01 -> 01-11
    expect(stats.percent, 80); // 8 / 10
  });

  test('a single fresh attempt is 100% clean', () {
    final now = DateTime.utc(2026, 1, 4);
    final attempts = [AttemptSpan(startedAt: DateTime.utc(2026, 1, 1))];
    final stats = cleanStats(attempts, now);
    expect(stats.cleanDays, 3);
    expect(stats.trackedDays, 3);
    expect(stats.percent, 100);
  });

  test('empty history is zero, not a divide-by-zero', () {
    final stats = cleanStats(const [], DateTime.utc(2026, 1, 1));
    expect(stats.cleanDays, 0);
    expect(stats.trackedDays, 0);
    expect(stats.percent, 0);
  });
}
