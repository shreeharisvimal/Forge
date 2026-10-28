// Seeder for the Forge application.
//
// Populates the exercise library and marks the schema version on a fresh
// install. Idempotent: [runIfNeeded] is a no-op once the schema version
// is recorded in the meta box.
library;

import '../services/repositories/exercise_repository.dart';
import 'database_service.dart';
import 'default_exercises.dart';

/// Seeds first-launch data.
class Seeder {
  /// Creates a [Seeder] with the services it needs.
  const Seeder({
    required DatabaseService databaseService,
    required ExerciseRepository exerciseRepository,
  })  : _databaseService = databaseService,
        _exerciseRepository = exerciseRepository;

  final DatabaseService _databaseService;
  final ExerciseRepository _exerciseRepository;

  /// Seeds default data exactly once (first launch).
  ///
  /// Returns the number of exercises written, or 0 if already seeded.
  Future<int> runIfNeeded() async {
    if (!_databaseService.isFirstLaunch) return 0;

    final exercises = defaultExercises();
    await _exerciseRepository.saveAll(exercises);
    await _databaseService.markSchemaApplied();
    return exercises.length;
  }
}
