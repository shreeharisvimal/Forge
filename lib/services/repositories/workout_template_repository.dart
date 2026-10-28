// WorkoutTemplate repository for the Forge application.
//
// Persistence and queries for [WorkoutTemplate] routines.
library;

import '../../models/workout_template.dart';
import 'base_repository.dart';

/// Query surface for [WorkoutTemplate] routines.
abstract class WorkoutTemplateRepository extends BaseRepository<WorkoutTemplate> {
  /// Creates a repository backed by [box].
  WorkoutTemplateRepository(super.box);

  /// All templates, sorted by name.
  List<WorkoutTemplate> sorted() {
    final result = [...all()]..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}

/// Hive-backed [WorkoutTemplateRepository].
class HiveWorkoutTemplateRepository extends WorkoutTemplateRepository {
  /// Creates a repository backed by [box].
  HiveWorkoutTemplateRepository(super.box);
}
