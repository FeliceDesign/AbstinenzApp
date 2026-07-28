import 'package:clean_tracker/features/checkin/domain/checkin_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 1, d);
  final DateTime today = DateTime(2026, 1, 10, 14, 30); // afternoon of the 10th

  test('empty set has no streak', () {
    expect(checkinStreak(<DateTime>{}, today), 0);
  });

  test('counts consecutive days ending today', () {
    final days = <DateTime>{day(10), day(9), day(8)};
    expect(checkinStreak(days, today), 3);
  });

  test('grace: still current if today is missing but yesterday is done', () {
    final days = <DateTime>{day(9), day(8)};
    expect(checkinStreak(days, today), 2);
  });

  test('a gap breaks the streak', () {
    final days = <DateTime>{day(10), day(9), day(7)}; // 8th missing
    expect(checkinStreak(days, today), 2);
  });

  test('most recent older than yesterday yields zero', () {
    final days = <DateTime>{day(8), day(7)};
    expect(checkinStreak(days, today), 0);
  });

  test('normalises timestamps to their calendar day', () {
    final days = <DateTime>{
      DateTime(2026, 1, 10, 6),
      DateTime(2026, 1, 9, 23, 59),
    };
    expect(checkinStreak(days, today), 2);
  });
}
