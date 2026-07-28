import '../../../core/db/database.dart';

/// App-data operations that span every table: the "delete everything" action
/// today, and (with export/import) the user's data-ownership tools.
class DataRepository {
  DataRepository(this._db);

  final AppDatabase _db;

  /// Deletes all rows from every table (child tables first). Used by the
  /// double-confirmed "delete all data" action.
  Future<void> wipeAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.relapseEvents).go();
      await _db.delete(_db.urgeEvents).go();
      await _db.delete(_db.checkIns).go();
      await _db.delete(_db.moodEntries).go();
      await _db.delete(_db.milestones).go();
      await _db.delete(_db.motivations).go();
      await _db.delete(_db.baselineUsages).go();
      await _db.delete(_db.savingGoals).go();
      await _db.delete(_db.quitAttempts).go();
      await _db.delete(_db.habits).go();
    });
  }
}
