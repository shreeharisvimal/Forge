// PrEvent repository for the Forge application.
//
// Persistence and queries for the append-only [PrEvent] timeline.
library;

import '../../../services/repositories/base_repository.dart';
import 'pr_event.dart';

/// Query surface for [PrEvent] records.
abstract class PrEventRepository extends BaseRepository<PrEvent> {
  /// Creates a repository backed by [box].
  PrEventRepository(super.box);

  /// Every record for [exerciseId], newest first.
  List<PrEvent> forExercise(String exerciseId) {
    final result = all()
        .where((event) => event.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Every record produced by the workout [workoutId], newest first.
  List<PrEvent> forWorkout(String workoutId) {
    final result = all()
        .where((event) => event.workoutId == workoutId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// The [limit] newest records across every exercise.
  List<PrEvent> recent(int limit) {
    final sorted = List<PrEvent>.of(all())
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Total number of records for [exerciseId].
  int countForExercise(String exerciseId) =>
      all().where((event) => event.exerciseId == exerciseId).length;
}

/// Hive-backed [PrEventRepository].
class HivePrEventRepository extends PrEventRepository {
  /// Creates a repository backed by [box].
  HivePrEventRepository(super.box);
}
