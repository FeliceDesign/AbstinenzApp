import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/checkin/data/checkin_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CheckinRepository repo;
  final FakeClock clock = FakeClock(DateTime(2026, 1, 12, 8));

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CheckinRepository(db, clock);
    // A habit is needed for the foreign key.
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            name: 'Beer',
            type: HabitType.alcohol,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
  });

  tearDown(() => db.close());

  test('saves answers for a day and reads them back', () async {
    await repo.saveForDay(
      habitId: 1,
      day: DateTime(2026, 1, 12, 9),
      answers: <String, dynamic>{'cleanToday': true, 'urgeStrength': 3},
    );

    final CheckIn? c = await repo.forDay(1, DateTime(2026, 1, 12, 23));
    expect(c, isNotNull);
    expect(c!.date, DateTime(2026, 1, 12));
    final Map<String, dynamic> answers = decodeAnswers(c.answersJson);
    expect(answers['cleanToday'], true);
    expect(answers['urgeStrength'], 3);
  });

  test('re-saving the same day updates instead of duplicating', () async {
    await repo.saveForDay(
      habitId: 1,
      day: DateTime(2026, 1, 12),
      answers: <String, dynamic>{'cleanToday': true},
    );
    await repo.saveForDay(
      habitId: 1,
      day: DateTime(2026, 1, 12),
      answers: <String, dynamic>{'cleanToday': false},
    );

    final List<CheckIn> all = await repo.watchAll().first;
    expect(all.length, 1);
    expect(decodeAnswers(all.single.answersJson)['cleanToday'], false);
  });

  test('back-dated check-in keeps its day but records completion now', () async {
    await repo.saveForDay(
      habitId: 1,
      day: DateTime(2026, 1, 9),
      answers: <String, dynamic>{'cleanToday': true},
    );
    final CheckIn? c = await repo.forDay(1, DateTime(2026, 1, 9));
    expect(c!.date, DateTime(2026, 1, 9));
    expect(c.completedAt, DateTime(2026, 1, 12, 8));
  });
}
