// Reference checking for the exercise library.
//
// Prevents deleting an exercise that is still used by workout plans,
// templates, performed sessions, personal records or history aggregates.
library;

import '../../../services/repositories/exercise_history_repository.dart';
import '../../../services/repositories/personal_record_repository.dart';
import '../../../services/repositories/workout_repository.dart';
import '../../../services/repositories/workout_session_repository.dart';
import '../../../services/repositories/workout_template_repository.dart';

/// Counts how many places reference a given exercise.
class ExerciseReferenceInfo {
  /// Creates a reference report.
  const ExerciseReferenceInfo({
    this.workouts = 0,
    this.templates = 0,
    this.sessions = 0,
    this.records = 0,
  });

  /// Workout plans referencing the exercise.
  final int workouts;

  /// Templates referencing the exercise.
  final int templates;

  /// Performed sessions referencing the exercise.
  final int sessions;

  /// Personal records + history rows referencing the exercise.
  final int records;

  /// Total number of references.
  int get total => workouts + templates + sessions + records;

  /// Whether the exercise is referenced anywhere.
  bool get isReferenced => total > 0;
}

/// Looks up where an exercise is still in use.
class ExerciseReferenceChecker {
  /// Creates a checker with the repositories it queries.
  const ExerciseReferenceChecker({
    required WorkoutRepository workoutRepository,
    required WorkoutTemplateRepository workoutTemplateRepository,
    required WorkoutSessionRepository workoutSessionRepository,
    required PersonalRecordRepository personalRecordRepository,
    required ExerciseHistoryRepository exerciseHistoryRepository,
  })  : _workoutRepository = workoutRepository,
        _workoutTemplateRepository = workoutTemplateRepository,
        _workoutSessionRepository = workoutSessionRepository,
        _personalRecordRepository = personalRecordRepository,
        _exerciseHistoryRepository = exerciseHistoryRepository;

  final WorkoutRepository _workoutRepository;
  final WorkoutTemplateRepository _workoutTemplateRepository;
  final WorkoutSessionRepository _workoutSessionRepository;
  final PersonalRecordRepository _personalRecordRepository;
  final ExerciseHistoryRepository _exerciseHistoryRepository;

  /// Counts references to [exerciseId] across all persisted data.
  ExerciseReferenceInfo referencesFor(String exerciseId) {
    final workouts = _workoutRepository.all()
        .where((workout) => workout.exerciseIds.contains(exerciseId))
        .length;

    final templates = _workoutTemplateRepository.all()
        .where((template) => template.exerciseIds.contains(exerciseId))
        .length;

    final sessions = _workoutSessionRepository.all().where((session) {
      return session.exercises
          .any((exercise) => exercise.exerciseId == exerciseId);
    }).length;

    final records = _personalRecordRepository.all()
        .where((record) => record.exerciseId == exerciseId)
        .length;
    final history = _exerciseHistoryRepository.all()
        .where((history) => history.exerciseId == exerciseId)
        .length;

    return ExerciseReferenceInfo(
      workouts: workouts,
      templates: templates,
      sessions: sessions,
      records: records + history,
    );
  }
}
