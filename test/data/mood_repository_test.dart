import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/features/mood/data/mood_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MoodRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodRepository(db);
  });

  tearDown(() => db.close());

  test('upsert stores one entry per day and normalises to midnight', () async {
    await repo.upsertForDay(
      day: DateTime(2026, 1, 10, 9),
      moodScore: 4,
      energy: 3,
      tags: <String>['proud', 'calm'],
    );

    final MoodEntry? entry = await repo.forDay(DateTime(2026, 1, 10, 22));
    expect(entry, isNotNull);
    expect(entry!.moodScore, 4);
    expect(entry.date, DateTime(2026, 1, 10));
    expect(decodeTags(entry.tags), <String>['proud', 'calm']);
  });

  test('a second write for the same day updates rather than duplicates',
      () async {
    await repo.upsertForDay(day: DateTime(2026, 1, 10), moodScore: 2, energy: 2);
    await repo.upsertForDay(
      day: DateTime(2026, 1, 10, 20),
      moodScore: 5,
      energy: 4,
      note: 'better now',
    );

    final List<MoodEntry> all = await repo.watchAll().first;
    expect(all.length, 1);
    expect(all.single.moodScore, 5);
    expect(all.single.note, 'better now');
  });

  test('blank notes are stored as null', () async {
    await repo.upsertForDay(
      day: DateTime(2026, 1, 11),
      moodScore: 3,
      energy: 3,
      note: '   ',
    );
    final MoodEntry? entry = await repo.forDay(DateTime(2026, 1, 11));
    expect(entry!.note, isNull);
  });
}
