import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/urge/data/urge_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late UrgeRepository repo;
  final clock = FakeClock(DateTime.utc(2026, 1, 10, 9));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = UrgeRepository(db, clock);
  });

  tearDown(() => db.close());

  test('startUrge records the initial intensity, open-ended', () async {
    final id = await repo.startUrge(intensityStart: 8);
    final event = (await repo.watchUrges().first).single;

    expect(event.id, id);
    expect(event.intensityStart, 8);
    expect(event.intensityEnd, isNull);
    expect(event.endedAt, isNull);
  });

  test('completeUrge writes after-measurement, technique and survived',
      () async {
    final id = await repo.startUrge(intensityStart: 8);
    clock.advance(const Duration(minutes: 4));
    await repo.completeUrge(
      id: id,
      intensityEnd: 3,
      techniqueUsed: 'breathing478',
    );

    final event = (await repo.watchUrges().first).single;
    expect(event.intensityEnd, 3);
    expect(event.techniqueUsed, 'breathing478');
    expect(event.survived, isTrue);
    expect(event.endedAt, isNotNull);
  });
}
