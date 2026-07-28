import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';

/// Persists urge events. The event is created up front (so an abandoned urge is
/// still recorded) and completed with the after-measurement at the end.
class UrgeRepository {
  UrgeRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Starts an urge and returns its id.
  Future<int> startUrge({required int intensityStart, int? habitId}) {
    return _db.into(_db.urgeEvents).insert(
          UrgeEventsCompanion.insert(
            habitId: Value(habitId),
            startedAt: _clock.now(),
            intensityStart: intensityStart,
          ),
        );
  }

  /// Completes an urge with the after-measurement and technique used.
  Future<void> completeUrge({
    required int id,
    required int intensityEnd,
    required String techniqueUsed,
    String? note,
  }) {
    return (_db.update(_db.urgeEvents)..where((u) => u.id.equals(id))).write(
      UrgeEventsCompanion(
        endedAt: Value(_clock.now()),
        intensityEnd: Value(intensityEnd),
        techniqueUsed: Value(techniqueUsed),
        // survived is true whenever the user finished the flow.
        survived: const Value(true),
        note: Value(note),
      ),
    );
  }

  /// All urge events, newest first (for stats and history).
  Stream<List<UrgeEvent>> watchUrges() {
    return (_db.select(_db.urgeEvents)
          ..orderBy([(u) => OrderingTerm.desc(u.startedAt)]))
        .watch();
  }
}
