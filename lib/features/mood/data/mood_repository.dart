import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/dates.dart';

/// Data access for daily mood entries (one row per calendar day).
///
/// The `date` column carries a UNIQUE constraint, so writes normalise to local
/// midnight and upsert manually (query-then-update/insert) — drift's
/// `insertOnConflictUpdate` targets the primary key, not our custom unique key,
/// so it would create duplicates here.
class MoodRepository {
  MoodRepository(this._db);

  final AppDatabase _db;

  /// All entries, oldest first (chart-friendly order).
  Stream<List<MoodEntry>> watchAll() {
    return (_db.select(_db.moodEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  /// The entry for a given day, or null. Reactive so the entry screen reflects
  /// edits immediately.
  Stream<MoodEntry?> watchForDay(DateTime day) {
    final DateTime d = dayStart(day);
    return (_db.select(_db.moodEntries)..where((t) => t.date.equals(d)))
        .watchSingleOrNull();
  }

  /// One-shot read for a day (used to prefill the entry screen).
  Future<MoodEntry?> forDay(DateTime day) {
    final DateTime d = dayStart(day);
    return (_db.select(_db.moodEntries)..where((t) => t.date.equals(d)))
        .getSingleOrNull();
  }

  /// Creates or replaces the entry for [day].
  Future<void> upsertForDay({
    required DateTime day,
    required int moodScore,
    required int energy,
    int? sleepQuality,
    List<String> tags = const <String>[],
    String? note,
  }) async {
    final DateTime d = dayStart(day);
    final String tagsJson = jsonEncode(tags);
    final String? cleanNote =
        (note == null || note.trim().isEmpty) ? null : note.trim();

    await _db.transaction(() async {
      final MoodEntry? existing = await (_db.select(_db.moodEntries)
            ..where((t) => t.date.equals(d)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.moodEntries).insert(
              MoodEntriesCompanion.insert(
                date: d,
                moodScore: moodScore,
                energy: energy,
                sleepQuality: Value(sleepQuality),
                tags: Value(tagsJson),
                note: Value(cleanNote),
              ),
            );
      } else {
        await (_db.update(_db.moodEntries)..where((t) => t.id.equals(existing.id)))
            .write(
          MoodEntriesCompanion(
            moodScore: Value(moodScore),
            energy: Value(energy),
            sleepQuality: Value(sleepQuality),
            tags: Value(tagsJson),
            note: Value(cleanNote),
          ),
        );
      }
    });
  }
}

/// Decodes the JSON-list `tags` column into a Dart list.
List<String> decodeTags(String tagsJson) {
  final dynamic decoded = jsonDecode(tagsJson);
  if (decoded is List) {
    return decoded.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
