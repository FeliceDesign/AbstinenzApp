import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';

/// Writes a relapse: closes the active attempt, records the event, and opens a
/// fresh attempt — all in one transaction so a habit is never left without an
/// active streak.
class RelapseRepository {
  RelapseRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Future<void> recordRelapse({
    required int habitId,
    required int quitAttemptId,
    required DateTime occurredAt,
    required DateTime newStartAt,
    String? trigger,
    String? situation,
    int? moodBefore,
    double? amount,
    String? note,
    bool wasPlanned = false,
  }) {
    return _db.transaction(() async {
      // 1. Close the attempt that was running at the relapse moment.
      await (_db.update(_db.quitAttempts)
            ..where((a) => a.id.equals(quitAttemptId)))
          .write(QuitAttemptsCompanion(endedAt: Value(occurredAt)));

      // 2. Record the relapse as a data point.
      await _db.into(_db.relapseEvents).insert(
            RelapseEventsCompanion.insert(
              habitId: habitId,
              quitAttemptId: quitAttemptId,
              occurredAt: occurredAt,
              trigger: Value(trigger),
              situation: Value(situation),
              moodBefore: Value(moodBefore),
              amount: Value(amount),
              note: Value(note),
              wasPlanned: Value(wasPlanned),
            ),
          );

      // 3. Open the next attempt so the streak starts again immediately.
      await _db.into(_db.quitAttempts).insert(
            QuitAttemptsCompanion.insert(
              habitId: habitId,
              startedAt: newStartAt,
            ),
          );
    });
  }

  /// Relapse events for a habit, newest first (for the history view).
  Stream<List<RelapseEvent>> watchRelapses(int habitId) {
    return (_db.select(_db.relapseEvents)
          ..where((r) => r.habitId.equals(habitId))
          ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]))
        .watch();
  }

  /// Every relapse across all habits (for mood-around-relapse correlation).
  Stream<List<RelapseEvent>> watchAllRelapses() {
    return (_db.select(_db.relapseEvents)
          ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]))
        .watch();
  }

  DateTime now() => _clock.now();
}
