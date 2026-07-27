import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/relapse/data/relapse_repository.dart';
import 'package:clean_tracker/features/relapse/domain/clean_stats.dart';
import 'package:clean_tracker/features/tracker/data/habit_repository.dart';
import 'package:clean_tracker/features/tracker/presentation/tracker_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HabitRepository habits;
  late RelapseRepository relapses;
  // Midnight so the active attempt's day count is exact (no partial day).
  final clock = FakeClock(DateTime.utc(2026, 1, 11));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    habits = HabitRepository(db, clock);
    relapses = RelapseRepository(db, clock);
  });

  tearDown(() => db.close());

  test('recordRelapse closes the active attempt and opens a new one', () async {
    final habitId = await habits.createHabitWithAttempt(
      name: 'Beer',
      type: HabitType.alcohol,
      unitLabel: 'drink',
      startedAt: DateTime.utc(2026, 1, 1),
    );
    final firstAttempt = (await habits.watchAttempts(habitId).first).single;

    await relapses.recordRelapse(
      habitId: habitId,
      quitAttemptId: firstAttempt.id,
      occurredAt: DateTime.utc(2026, 1, 6),
      newStartAt: DateTime.utc(2026, 1, 8),
      trigger: 'stress',
      moodBefore: 2,
      amount: 3,
    );

    final attempts = await habits.watchAttempts(habitId).first;
    expect(attempts, hasLength(2), reason: 'old closed + new open');

    final closed = attempts.firstWhere((a) => a.id == firstAttempt.id);
    expect(
      closed.endedAt!.isAtSameMomentAs(DateTime.utc(2026, 1, 6)),
      isTrue,
    );

    final active = attempts.where((a) => a.endedAt == null).toList();
    expect(active, hasLength(1));
    expect(
      active.single.startedAt.isAtSameMomentAs(DateTime.utc(2026, 1, 8)),
      isTrue,
    );

    final events = await relapses.watchRelapses(habitId).first;
    expect(events, hasLength(1));
    expect(events.single.trigger, 'stress');
    expect(events.single.moodBefore, 2);
    expect(events.single.amount, 3);
  });

  test('clean-days total spans both attempts after a relapse', () async {
    final habitId = await habits.createHabitWithAttempt(
      name: 'Beer',
      type: HabitType.alcohol,
      unitLabel: 'drink',
      startedAt: DateTime.utc(2026, 1, 1),
    );
    final first = (await habits.watchAttempts(habitId).first).single;

    await relapses.recordRelapse(
      habitId: habitId,
      quitAttemptId: first.id,
      occurredAt: DateTime.utc(2026, 1, 6), // 5 clean days
      newStartAt: DateTime.utc(2026, 1, 8), // then 3 more up to "now"
    );

    final attempts = await habits.watchAttempts(habitId).first;
    final stats = cleanStats(toSpans(attempts), clock.now());

    expect(stats.cleanDays, 8);
    expect(stats.trackedDays, 10);
    expect(stats.percent, 80);
  });
}
