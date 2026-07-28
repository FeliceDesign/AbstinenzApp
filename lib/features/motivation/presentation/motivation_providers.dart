import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/motivation_repository.dart';
import '../domain/daily_pick.dart';

part 'motivation_providers.g.dart';

@riverpod
MotivationRepository motivationRepository(MotivationRepositoryRef ref) =>
    MotivationRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

@riverpod
Stream<List<Motivation>> motivationsByKind(
  MotivationsByKindRef ref,
  MotivationKind kind,
) =>
    ref.watch(motivationRepositoryProvider).watchByKind(kind);

@riverpod
Stream<List<Motivation>> pinnedWhys(PinnedWhysRef ref) =>
    ref.watch(motivationRepositoryProvider).watchPinnedWhys();

/// The "why of the day": a pinned why chosen deterministically per day.
@riverpod
Motivation? dailyWhy(DailyWhyRef ref) {
  final whys = ref.watch(pinnedWhysProvider).valueOrNull ?? const [];
  return pickDaily(whys, ref.watch(clockProvider).now());
}
