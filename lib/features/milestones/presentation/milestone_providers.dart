import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../data/milestone_repository.dart';

part 'milestone_providers.g.dart';

@riverpod
MilestoneRepository milestoneRepository(MilestoneRepositoryRef ref) =>
    MilestoneRepository(ref.watch(databaseProvider));

@riverpod
Stream<List<Milestone>> milestonesForHabit(
  MilestonesForHabitRef ref,
  int habitId,
) =>
    ref.watch(milestoneRepositoryProvider).watchForHabit(habitId);
