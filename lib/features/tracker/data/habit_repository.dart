import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';

/// Data access for habits and their quit attempts.
///
/// Kept as a thin wrapper over drift so the presentation layer never touches
/// SQL directly and so it can be faked in widget tests. Returns reactive
/// streams; the UI rebuilds automatically when rows change.
class HabitRepository {
  HabitRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Active, non-archived habits, newest first.
  Stream<List<Habit>> watchActiveHabits() {
    return (_db.select(_db.habits)
          ..where((h) => h.isActive.equals(true) & h.archivedAt.isNull())
          ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .watch();
  }

  /// All attempts for a habit, oldest first (attempt #1 is the earliest).
  Stream<List<QuitAttempt>> watchAttempts(int habitId) {
    return (_db.select(_db.quitAttempts)
          ..where((a) => a.habitId.equals(habitId))
          ..orderBy([(a) => OrderingTerm.asc(a.startedAt)]))
        .watch();
  }

  /// Creates a habit together with its first (active) quit attempt in one
  /// transaction, so a habit is never persisted without a running streak.
  Future<int> createHabitWithAttempt({
    required String name,
    required HabitType type,
    required String unitLabel,
    required DateTime startedAt,
  }) {
    return _db.transaction(() async {
      final int habitId = await _db.into(_db.habits).insert(
            HabitsCompanion.insert(
              name: name,
              type: type,
              unitLabel: Value(unitLabel),
              createdAt: _clock.now(),
            ),
          );
      await _db.into(_db.quitAttempts).insert(
            QuitAttemptsCompanion.insert(
              habitId: habitId,
              startedAt: startedAt,
            ),
          );
      return habitId;
    });
  }
}
