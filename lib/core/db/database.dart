import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Kinds of habit the app can track. Stored as the enum name (text) via drift's
/// `intEnum`-free text mapping below.
enum HabitType { alcohol, nicotine, cannabis, sugar, gaming, porn, other }

/// Kind of motivation entry.
enum MotivationKind { why, benefit, consequence }

// --- Tables ------------------------------------------------------------------

/// A tracked habit. Multiple habits can run in parallel (multi-habit app).
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get type => textEnum<HabitType>()();
  TextColumn get unitLabel => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// A single attempt at staying clean. The active attempt (endedAt == null)
/// drives the current streak.
class QuitAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

/// A recorded relapse. Data point, never a punishment.
class RelapseEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get quitAttemptId =>
      integer().references(QuitAttempts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get trigger => text().nullable()();
  TextColumn get situation => text().nullable()();
  IntColumn get moodBefore => integer().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get wasPlanned => boolean().withDefault(const Constant(false))();
}

/// One mood entry per calendar day.
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get moodScore => integer()();
  IntColumn get energy => integer()();
  IntColumn get sleepQuality => integer().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

/// Daily check-in answers ("Abfragen").
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get answersJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get completedAt => dateTime()();
}

/// A recorded urge and its outcome (the core reward loop).
class UrgeEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()
      .nullable()
      .references(Habits, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get intensityStart => integer()();
  IntColumn get intensityEnd => integer().nullable()();
  TextColumn get techniqueUsed => text().nullable()();
  BoolColumn get survived => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
}

/// Time and health milestones. Presets are seeded when a habit is created.
class Milestones extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get key => text()();
  IntColumn get thresholdSeconds => integer()();
  DateTimeColumn get achievedAt => dateTime().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

/// Personal motivations: why / benefit / consequence.
class Motivations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()
      .nullable()
      .references(Habits, #id, onDelete: KeyAction.cascade)();
  // Named `content` rather than `text`: `text` collides with drift's
  // `Table.text()` column builder.
  TextColumn get content => text()();
  TextColumn get kind => textEnum<MotivationKind>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// For `benefit` entries: when the user marked it as "already noticed".
  /// Null = not yet noticed. Added in schema v2.
  DateTimeColumn get noticedAt => dateTime().nullable()();
}

/// Versioned baseline consumption, used for savings and calorie counters.
/// A new row is inserted (rather than updated) whenever the user edits the
/// baseline, so historical calculations stay correct from each [validFrom].
class BaselineUsages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  RealColumn get unitsPerDay => real()();
  RealColumn get costPerUnit => real()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  RealColumn get kcalPerUnit => real().nullable()();
  DateTimeColumn get validFrom => dateTime()();
}

/// A savings goal ("new lens, 800 €"). Funded by the running savings estimate.
/// App-wide (not tied to a single habit) so total savings across habits count.
/// Added in schema v3.
class SavingGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  RealColumn get targetAmount => real()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get achievedAt => dateTime().nullable()();
}

// --- Database ----------------------------------------------------------------

@DriftDatabase(
  tables: [
    Habits,
    QuitAttempts,
    RelapseEvents,
    MoodEntries,
    CheckIns,
    UrgeEvents,
    Milestones,
    Motivations,
    BaselineUsages,
    SavingGoals,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests, taking an in-memory / custom executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v2: benefits can be marked "already noticed" with a date.
          if (from < 2) {
            await m.addColumn(motivations, motivations.noticedAt);
          }
          // v3: savings goals.
          if (from < 3) {
            await m.createTable(savingGoals);
          }
        },
        beforeOpen: (details) async {
          // Enforce foreign keys — off by default in SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'clean_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
