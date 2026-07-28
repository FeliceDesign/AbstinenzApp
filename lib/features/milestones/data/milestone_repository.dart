import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/milestone_content.dart';

/// Persists milestones. Presets are seeded once per habit; custom milestones
/// store the user's text directly in [Milestones.key] (there is no separate
/// title column — a custom key *is* its title, resolved as-is in the UI).
class MilestoneRepository {
  MilestoneRepository(this._db);

  final AppDatabase _db;

  Stream<List<Milestone>> watchForHabit(int habitId) {
    return (_db.select(_db.milestones)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.asc(t.thresholdSeconds)]))
        .watch();
  }

  /// Seeds the preset ladder for [habitId] if it has none yet. Idempotent.
  Future<void> ensureSeeded(int habitId, HabitType type) async {
    final int count = await (_db.select(_db.milestones)
          ..where((t) => t.habitId.equals(habitId)))
        .get()
        .then((List<Milestone> rows) => rows.length);
    if (count > 0) return;

    await _db.batch((Batch batch) {
      for (final MilestoneDef def in presetMilestones(type)) {
        batch.insert(
          _db.milestones,
          MilestonesCompanion.insert(
            habitId: habitId,
            key: def.key,
            thresholdSeconds: def.thresholdSeconds,
            isCustom: const Value(false),
          ),
        );
      }
    });
  }

  Future<int> addCustom({
    required int habitId,
    required String title,
    required int thresholdSeconds,
  }) {
    return _db.into(_db.milestones).insert(
          MilestonesCompanion.insert(
            habitId: habitId,
            key: title,
            thresholdSeconds: thresholdSeconds,
            isCustom: const Value(true),
          ),
        );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.milestones)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markAchieved(int id, DateTime at) {
    return (_db.update(_db.milestones)..where((t) => t.id.equals(id)))
        .write(MilestonesCompanion(achievedAt: Value(at)));
  }

  /// Clears achievement flags for a habit — used when a relapse restarts the
  /// streak, so the milestones can be earned again in the new attempt.
  Future<void> resetAchievements(int habitId) {
    return (_db.update(_db.milestones)..where((t) => t.habitId.equals(habitId)))
        .write(const MilestonesCompanion(achievedAt: Value<DateTime>(null)));
  }
}
