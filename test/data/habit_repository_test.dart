import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/tracker/data/habit_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  final clock = FakeClock(DateTime.utc(2026, 1, 1, 8));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HabitRepository(db, clock);
  });

  tearDown(() => db.close());

  test('createHabitWithAttempt persists habit and an active attempt', () async {
    final int id = await repo.createHabitWithAttempt(
      name: 'Beer',
      type: HabitType.alcohol,
      unitLabel: 'drink',
      startedAt: DateTime.utc(2025, 12, 30, 20),
    );

    final habits = await repo.watchActiveHabits().first;
    expect(habits, hasLength(1));
    expect(habits.single.id, id);
    expect(habits.single.name, 'Beer');
    expect(habits.single.type, HabitType.alcohol);
    // Drift reads DateTimes back with a local flag; compare by instant.
    expect(habits.single.createdAt.isAtSameMomentAs(clock.now()), isTrue);

    final attempts = await repo.watchAttempts(id).first;
    expect(attempts, hasLength(1));
    expect(
      attempts.single.startedAt.isAtSameMomentAs(DateTime.utc(2025, 12, 30, 20)),
      isTrue,
    );
    expect(attempts.single.endedAt, isNull, reason: 'attempt is active');
  });

  test('archived / inactive habits are excluded from the active stream',
      () async {
    final int id = await repo.createHabitWithAttempt(
      name: 'Smokes',
      type: HabitType.nicotine,
      unitLabel: 'cigarette',
      startedAt: clock.now(),
    );
    await (db.update(db.habits)..where((h) => h.id.equals(id)))
        .write(const HabitsCompanion(isActive: Value(false)));

    final habits = await repo.watchActiveHabits().first;
    expect(habits, isEmpty);
  });
}
