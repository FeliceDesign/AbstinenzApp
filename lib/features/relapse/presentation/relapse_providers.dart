import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/relapse_repository.dart';

part 'relapse_providers.g.dart';

@riverpod
RelapseRepository relapseRepository(RelapseRepositoryRef ref) =>
    RelapseRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

/// Relapse history for a habit.
@riverpod
Stream<List<RelapseEvent>> habitRelapses(HabitRelapsesRef ref, int habitId) =>
    ref.watch(relapseRepositoryProvider).watchRelapses(habitId);

/// Every relapse across habits — used by the mood correlation on the stats tab.
@riverpod
Stream<List<RelapseEvent>> allRelapses(AllRelapsesRef ref) =>
    ref.watch(relapseRepositoryProvider).watchAllRelapses();
