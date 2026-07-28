import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';

/// Data access for motivations (why / benefit / consequence).
class MotivationRepository {
  MotivationRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Entries of a kind in user sort order. Not pinned-first, so drag-reorder in
  /// the manage screen behaves predictably; pinning is an independent flag.
  Stream<List<Motivation>> watchByKind(MotivationKind kind) {
    return (_db.select(_db.motivations)
          ..where((m) => m.kind.equalsValue(kind))
          ..orderBy([
            (m) => OrderingTerm.asc(m.sortOrder),
            (m) => OrderingTerm.asc(m.id),
          ]))
        .watch();
  }

  /// Pinned "why" entries — the ones eligible for the daily dashboard quote and
  /// the relapse/urge flows.
  Stream<List<Motivation>> watchPinnedWhys() {
    return (_db.select(_db.motivations)
          ..where(
            (m) =>
                m.kind.equalsValue(MotivationKind.why) &
                m.isPinned.equals(true),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
        .watch();
  }

  Future<int> add({
    required MotivationKind kind,
    required String content,
    bool isPinned = false,
    int? habitId,
  }) async {
    // Append to the end of its kind.
    final int count = await (_db.select(_db.motivations)
          ..where((m) => m.kind.equalsValue(kind)))
        .get()
        .then((rows) => rows.length);
    return _db.into(_db.motivations).insert(
          MotivationsCompanion.insert(
            content: content,
            kind: kind,
            habitId: Value(habitId),
            sortOrder: Value(count),
            isPinned: Value(isPinned),
          ),
        );
  }

  Future<void> updateContent(int id, String content) {
    return (_db.update(_db.motivations)..where((m) => m.id.equals(id)))
        .write(MotivationsCompanion(content: Value(content)));
  }

  Future<void> setPinned(int id, bool pinned) {
    return (_db.update(_db.motivations)..where((m) => m.id.equals(id)))
        .write(MotivationsCompanion(isPinned: Value(pinned)));
  }

  /// Marks a benefit as noticed (now) or clears it (null).
  Future<void> setNoticed(int id, {required bool noticed}) {
    return (_db.update(_db.motivations)..where((m) => m.id.equals(id))).write(
      MotivationsCompanion(
        noticedAt: Value(noticed ? _clock.now() : null),
      ),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.motivations)..where((m) => m.id.equals(id))).go();
  }

  /// Persists a new order for a kind: `orderedIds` is the full list in the
  /// desired order, written back as sortOrder 0..n-1.
  Future<void> reorder(List<int> orderedIds) {
    return _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.motivations)
              ..where((m) => m.id.equals(orderedIds[i])))
            .write(MotivationsCompanion(sortOrder: Value(i)));
      }
    });
  }
}
