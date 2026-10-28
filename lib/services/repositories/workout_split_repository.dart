// WorkoutSplit repository for the Forge application.
//
// Persistence and queries for [WorkoutSplit] weekly plans, including the
// single-active-split invariant.
library;

import '../../models/workout_split.dart';
import 'base_repository.dart';

/// Query surface for [WorkoutSplit] plans.
abstract class WorkoutSplitRepository extends BaseRepository<WorkoutSplit> {
  /// Creates a repository backed by [box].
  WorkoutSplitRepository(super.box);

  /// The split currently driving the schedule, or null if none is active.
  WorkoutSplit? get activeSplit =>
      all().where((split) => split.isActive).firstOrNull;

  /// All splits, newest first.
  List<WorkoutSplit> sorted() {
    final result = [...all()]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  /// Makes [splitId] the only active split.
  ///
  /// Deactivates every other split first so at most one plan is active.
  Future<void> activate(String splitId) async {
    final changes = <WorkoutSplit>[];
    for (final split in all()) {
      if (split.isActive && split.id != splitId) {
        changes.add(split.copyWith(isActive: false));
      }
    }
    final target = byId(splitId);
    if (target != null && !target.isActive) {
      changes.add(target.copyWith(isActive: true));
    }
    await saveAll(changes);
  }

  /// Clears the active flag on every split.
  Future<void> deactivateAll() async {
    await saveAll(
      all().where((split) => split.isActive).map((split) => split.copyWith(isActive: false)),
    );
  }
}

/// Hive-backed [WorkoutSplitRepository].
class HiveWorkoutSplitRepository extends WorkoutSplitRepository {
  /// Creates a repository backed by [box].
  HiveWorkoutSplitRepository(super.box);
}
