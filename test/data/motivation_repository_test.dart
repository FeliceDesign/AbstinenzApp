import 'package:clean_tracker/core/db/database.dart';
import 'package:clean_tracker/core/utils/clock.dart';
import 'package:clean_tracker/features/motivation/data/motivation_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MotivationRepository repo;
  final clock = FakeClock(DateTime.utc(2026, 1, 10, 9));

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MotivationRepository(db, clock);
  });

  tearDown(() => db.close());

  test('add appends in sort order; pinning is independent', () async {
    final a = await repo.add(kind: MotivationKind.why, content: 'A');
    final b = await repo.add(kind: MotivationKind.why, content: 'B');

    final whys = await repo.watchByKind(MotivationKind.why).first;
    expect(whys.map((m) => m.content), ['A', 'B']);
    expect(whys.map((m) => m.sortOrder), [0, 1]);

    await repo.setPinned(a, true);
    final pinned = await repo.watchPinnedWhys().first;
    expect(pinned.map((m) => m.id), [a]);
    expect(b, isNot(a));
  });

  test('reorder rewrites sort order', () async {
    final a = await repo.add(kind: MotivationKind.why, content: 'A');
    final b = await repo.add(kind: MotivationKind.why, content: 'B');

    await repo.reorder([b, a]);

    final whys = await repo.watchByKind(MotivationKind.why).first;
    expect(whys.map((m) => m.content), ['B', 'A']);
  });

  test('setNoticed stamps and clears the date', () async {
    final id = await repo.add(kind: MotivationKind.benefit, content: 'Sleep');

    await repo.setNoticed(id, noticed: true);
    var benefit = (await repo.watchByKind(MotivationKind.benefit).first).single;
    expect(benefit.noticedAt, isNotNull);

    await repo.setNoticed(id, noticed: false);
    benefit = (await repo.watchByKind(MotivationKind.benefit).first).single;
    expect(benefit.noticedAt, isNull);
  });
}
