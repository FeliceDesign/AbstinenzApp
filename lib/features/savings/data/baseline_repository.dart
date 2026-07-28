import 'package:drift/drift.dart';

import '../../../core/db/database.dart';

/// Reads and writes versioned baseline rows. Editing never updates in place:
/// each save inserts a new row with its own [BaselineUsages.validFrom], so past
/// savings stay computed at the rate that was in effect then.
class BaselineRepository {
  BaselineRepository(this._db);

  final AppDatabase _db;

  /// All baseline versions for a habit, oldest first.
  Stream<List<BaselineUsage>> watchForHabit(int habitId) {
    return (_db.select(_db.baselineUsages)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.asc(t.validFrom)]))
        .watch();
  }

  /// All baseline versions across habits (for the app-wide totals).
  Stream<List<BaselineUsage>> watchAll() {
    return (_db.select(_db.baselineUsages)
          ..orderBy([(t) => OrderingTerm.asc(t.validFrom)]))
        .watch();
  }

  /// The most recent baseline for a habit, or null if none set yet.
  Future<BaselineUsage?> latestForHabit(int habitId) {
    return (_db.select(_db.baselineUsages)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.desc(t.validFrom)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts a new baseline version effective from [validFrom].
  Future<int> addVersion({
    required int habitId,
    required double unitsPerDay,
    required double costPerUnit,
    required String currency,
    double? kcalPerUnit,
    required DateTime validFrom,
  }) {
    return _db.into(_db.baselineUsages).insert(
          BaselineUsagesCompanion.insert(
            habitId: habitId,
            unitsPerDay: unitsPerDay,
            costPerUnit: costPerUnit,
            currency: Value(currency),
            kcalPerUnit: Value(kcalPerUnit),
            validFrom: validFrom,
          ),
        );
  }
}
