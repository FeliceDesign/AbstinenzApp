import 'dart:convert';

import '../../../core/db/database.dart';

/// App-data operations that span every table: delete-everything, and the
/// user's data-ownership tools (JSON export / import).
class DataRepository {
  DataRepository(this._db);

  final AppDatabase _db;

  /// Deletes all rows from every table (child tables first). Used by the
  /// double-confirmed "delete all data" action.
  Future<void> wipeAll() => _db.transaction(_deleteEverything);

  Future<void> _deleteEverything() async {
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
  }

  /// Serializes every table to a portable, human-readable JSON document, so the
  /// user fully owns their data (spec: local-first, export/import).
  Future<String> exportJson() async {
    final Map<String, dynamic> data = <String, dynamic>{
      'app': 'unbound',
      'schemaVersion': _db.schemaVersion,
      'habits':
          (await _db.select(_db.habits).get()).map((e) => e.toJson()).toList(),
      'quitAttempts': (await _db.select(_db.quitAttempts).get())
          .map((e) => e.toJson())
          .toList(),
      'relapseEvents': (await _db.select(_db.relapseEvents).get())
          .map((e) => e.toJson())
          .toList(),
      'moodEntries': (await _db.select(_db.moodEntries).get())
          .map((e) => e.toJson())
          .toList(),
      'checkIns': (await _db.select(_db.checkIns).get())
          .map((e) => e.toJson())
          .toList(),
      'urgeEvents': (await _db.select(_db.urgeEvents).get())
          .map((e) => e.toJson())
          .toList(),
      'milestones': (await _db.select(_db.milestones).get())
          .map((e) => e.toJson())
          .toList(),
      'motivations': (await _db.select(_db.motivations).get())
          .map((e) => e.toJson())
          .toList(),
      'baselineUsages': (await _db.select(_db.baselineUsages).get())
          .map((e) => e.toJson())
          .toList(),
      'savingGoals': (await _db.select(_db.savingGoals).get())
          .map((e) => e.toJson())
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Replaces all data with the contents of a previously exported document.
  /// Parents are inserted before children so foreign keys resolve; ids are
  /// preserved. Throws if the document isn't valid JSON.
  Future<void> importJson(String jsonStr) async {
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    List<Map<String, dynamic>> list(String key) =>
        ((data[key] as List<dynamic>?) ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      await _deleteEverything();
      for (final Map<String, dynamic> m in list('habits')) {
        await _db.into(_db.habits).insert(Habit.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('quitAttempts')) {
        await _db.into(_db.quitAttempts).insert(QuitAttempt.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('relapseEvents')) {
        await _db.into(_db.relapseEvents).insert(RelapseEvent.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('moodEntries')) {
        await _db.into(_db.moodEntries).insert(MoodEntry.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('checkIns')) {
        await _db.into(_db.checkIns).insert(CheckIn.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('urgeEvents')) {
        await _db.into(_db.urgeEvents).insert(UrgeEvent.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('milestones')) {
        await _db.into(_db.milestones).insert(Milestone.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('motivations')) {
        await _db.into(_db.motivations).insert(Motivation.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('baselineUsages')) {
        await _db.into(_db.baselineUsages).insert(BaselineUsage.fromJson(m));
      }
      for (final Map<String, dynamic> m in list('savingGoals')) {
        await _db.into(_db.savingGoals).insert(SavingGoal.fromJson(m));
      }
    });
  }
}
