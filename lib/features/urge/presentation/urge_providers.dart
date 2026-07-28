import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../data/urge_repository.dart';
import '../domain/urge_stats.dart';

part 'urge_providers.g.dart';

@riverpod
UrgeRepository urgeRepository(UrgeRepositoryRef ref) => UrgeRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    );

@riverpod
Stream<List<UrgeEvent>> urgeEvents(UrgeEventsRef ref) =>
    ref.watch(urgeRepositoryProvider).watchUrges();

/// Number of completed waves ridden out — the reward counter.
@riverpod
int wavesRiddenCount(WavesRiddenCountRef ref) {
  final events = ref.watch(urgeEventsProvider).valueOrNull ?? const [];
  return wavesRidden(events.map(_toOutcome).toList());
}

/// Per-technique effectiveness ("what really works for you"), best first.
@riverpod
List<TechniqueEffectiveness> techniqueEffectiveness(
  TechniqueEffectivenessRef ref,
) {
  final events = ref.watch(urgeEventsProvider).valueOrNull ?? const [];
  return effectivenessByTechnique(events.map(_toOutcome).toList());
}

UrgeOutcome _toOutcome(UrgeEvent e) => UrgeOutcome(
      intensityStart: e.intensityStart,
      intensityEnd: e.intensityEnd,
      technique: e.techniqueUsed,
    );
