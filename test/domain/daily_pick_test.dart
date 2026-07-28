import 'package:clean_tracker/features/motivation/domain/daily_pick.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = ['a', 'b', 'c'];

  test('is stable within the same calendar day', () {
    final morning = DateTime.utc(2026, 1, 10, 7);
    final evening = DateTime.utc(2026, 1, 10, 22);
    expect(pickDaily(items, morning), pickDaily(items, evening));
  });

  test('advances by one (mod length) the next day', () {
    final day = DateTime.utc(2026, 1, 10);
    final next = DateTime.utc(2026, 1, 11);
    final iDay = items.indexOf(pickDaily(items, day)!);
    final iNext = items.indexOf(pickDaily(items, next)!);
    expect(iNext, (iDay + 1) % items.length);
  });

  test('single item always chosen; empty yields null', () {
    expect(pickDaily(['only'], DateTime.utc(2026, 5, 1)), 'only');
    expect(pickDaily(const <String>[], DateTime.utc(2026, 5, 1)), isNull);
  });
}
