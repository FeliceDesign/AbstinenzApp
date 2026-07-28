import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/dates.dart';

/// Data access for daily check-ins.
///
/// One check-in per habit per calendar day. There is no DB-level unique
/// constraint (the schema keeps `date` plain), so a same-day re-submit updates
/// the existing row rather than stacking duplicates — done by query-then-write.
/// Back-dating is supported: [day] can be up to a week in the past while
/// [completedAt] records when it was actually filled in.
class CheckinRepository {
  CheckinRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// All check-ins across habits, oldest first.
  Stream<List<CheckIn>> watchAll() {
    return (_db.select(_db.checkIns)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  /// The check-in for a habit on a given day, or null.
  Future<CheckIn?> forDay(int habitId, DateTime day) {
    final DateTime d = dayStart(day);
    return (_db.select(_db.checkIns)
          ..where((t) => t.habitId.equals(habitId) & t.date.equals(d)))
        .getSingleOrNull();
  }

  /// Creates or updates the check-in for [habitId] on [day].
  Future<void> saveForDay({
    required int habitId,
    required DateTime day,
    required Map<String, dynamic> answers,
  }) async {
    final DateTime d = dayStart(day);
    final String answersJson = jsonEncode(answers);
    final DateTime now = _clock.now();

    await _db.transaction(() async {
      final CheckIn? existing = await (_db.select(_db.checkIns)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(d)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.checkIns).insert(
              CheckInsCompanion.insert(
                date: d,
                habitId: habitId,
                answersJson: Value(answersJson),
                completedAt: now,
              ),
            );
      } else {
        await (_db.update(_db.checkIns)..where((t) => t.id.equals(existing.id)))
            .write(
          CheckInsCompanion(
            answersJson: Value(answersJson),
            completedAt: Value(now),
          ),
        );
      }
    });
  }
}

/// Decodes a stored `answersJson` payload.
Map<String, dynamic> decodeAnswers(String answersJson) {
  final dynamic decoded = jsonDecode(answersJson);
  if (decoded is Map<String, dynamic>) return decoded;
  return const <String, dynamic>{};
}
