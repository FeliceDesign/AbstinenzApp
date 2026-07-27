import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Single app-wide database instance.
///
/// Rationale: kept as a hand-written [Provider] rather than a `@riverpod`
/// code-gen provider because the database is a plain singleton with no
/// parameters — code generation would add a build step for no benefit. Feature
/// DAOs/repositories will be generated providers where they carry real logic.
final databaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
