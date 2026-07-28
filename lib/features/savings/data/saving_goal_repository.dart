import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';

/// CRUD for savings goals. Achievement is a timestamp set once the running
/// savings first cover the target (or cleared if the estimate later drops).
class SavingGoalRepository {
  SavingGoalRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Goals in creation order. Whether a goal is "reached" is derived live from
  /// the current savings estimate in the UI, so it isn't persisted here.
  Stream<List<SavingGoal>> watchAll() {
    return (_db.select(_db.savingGoals)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<int> add({
    required String title,
    required double targetAmount,
    required String currency,
  }) {
    return _db.into(_db.savingGoals).insert(
          SavingGoalsCompanion.insert(
            title: title,
            targetAmount: targetAmount,
            currency: Value(currency),
            createdAt: _clock.now(),
          ),
        );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.savingGoals)..where((t) => t.id.equals(id))).go();
  }
}
