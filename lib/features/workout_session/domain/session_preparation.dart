// Workout preparation for the Forge application.
//
// Builds the initial [ActiveSession] from a set of planned exercises and
// estimates the preparation read model (target volume, sets and duration).
// Pure functions only — no Flutter or Riverpod imports.
library;

import '../../../core/utils/dates.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_set.dart';
import '../../../models/workout_session.dart';
import 'session_models.dart';

/// A planned exercise with the targets and prefills it starts with.
class ActiveExercisePlan {
  /// Creates an exercise plan.
  const ActiveExercisePlan({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 3,
    this.targetReps = 10,
    this.rpe,
    this.restSeconds = 90,
    this.tempo,
    this.notes = '',
    this.warmup = false,
    this.prefillWeight = 0,
    this.prefillReps,
  });

  /// Library exercise id.
  final String exerciseId;

  /// Denormalized exercise name.
  final String exerciseName;

  /// Number of working sets to create.
  final int targetSets;

  /// Reps used for the working sets.
  final int targetReps;

  /// Suggested RPE for the working sets.
  final double? rpe;

  /// Rest seconds assigned to each working set.
  final int restSeconds;

  /// Suggested tempo for the working sets.
  final String? tempo;

  /// Free-form notes for the exercise instance.
  final String notes;

  /// Whether two warm-up sets are added before the working sets.
  final bool warmup;

  /// Weight (kg) the first working set starts with.
  final double prefillWeight;

  /// Reps the first working set starts with (falls back to [targetReps]).
  final int? prefillReps;

  /// Plan copy with a changed warm-up flag.
  ActiveExercisePlan withWarmup(bool value) => ActiveExercisePlan(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        targetSets: targetSets,
        targetReps: targetReps,
        rpe: rpe,
        restSeconds: restSeconds,
        tempo: tempo,
        notes: notes,
        warmup: value,
        prefillWeight: prefillWeight,
        prefillReps: prefillReps,
      );
}

/// Builds the initial [ActiveSession] state from [plans].
///
/// Each planned exercise materializes `targetSets` working sets; the first
/// working set is prefilled with the user's last performance. Warm-up sets
/// are not created yet — exercises flagged [ActiveExercisePlan.warmup] are
/// recorded on the session and get their warm-up sets inserted at start.
abstract final class ActiveSessionBuilder {
  ActiveSessionBuilder._();

  /// Builds the session in the preparation stage (no start time yet).
  static ActiveSession fromPlans({
    required String name,
    required DateTime now,
    required List<ActiveExercisePlan> plans,
  }) {
    final exercises = <WorkoutExercise>[];
    final warmupIds = <String>[];
    for (var i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final exercise = WorkoutExercise(
        exerciseId: plan.exerciseId,
        exerciseName: plan.exerciseName,
        order: i,
        notes: plan.notes,
        sets: _buildWorkingSets(plan),
      );
      if (plan.warmup) warmupIds.add(exercise.id);
      exercises.add(exercise);
    }
    final session = ActiveSession(
      content: WorkoutSession(
        name: name,
        date: dateOnly(now),
        exercises: exercises,
        completed: false,
      ),
      ui: SessionUiState(
        stage: SessionStage.preparation,
        warmupExerciseIds: warmupIds,
      ),
    );
    return session;
  }

  static List<WorkoutSet> _buildWorkingSets(ActiveExercisePlan plan) {
    return [
      for (var s = 0; s < plan.targetSets; s++)
        WorkoutSet(
          weight: plan.prefillWeight,
          reps: plan.prefillReps ?? plan.targetReps,
          rpe: plan.rpe,
          restSeconds: plan.restSeconds,
          completed: false,
          isWarmup: false,
          tempo: plan.tempo,
          notes: '',
        ),
    ];
  }
}

/// A planned exercise as shown in the preparation screen.
class PlannedExerciseView {
  /// Creates a preparation view.
  const PlannedExerciseView({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.targetSets,
    required this.targetReps,
    this.tempo,
    this.lastWeight,
    this.lastReps,
    this.lastOneRM,
    this.prOneRM,
  });

  /// Library exercise id.
  final String exerciseId;

  /// Exercise name.
  final String exerciseName;

  /// Canonical muscle group.
  final String muscleGroup;

  /// Number of planned working sets.
  final int targetSets;

  /// Planned reps per working set.
  final int targetReps;

  /// Planned tempo, if any.
  final String? tempo;

  /// Weight of the last recorded set, if any.
  final double? lastWeight;

  /// Reps of the last recorded set, if any.
  final int? lastReps;

  /// Estimated one-rep max of the last recorded set, if any.
  final double? lastOneRM;

  /// Lifetime best estimated one-rep max, if any.
  final double? prOneRM;
}

/// The full preparation read model for the screen.
class SessionPreparationData {
  /// Creates the preparation data.
  const SessionPreparationData({
    required this.name,
    required this.exercises,
    required this.estimatedMinutes,
    required this.targetSets,
    required this.targetVolume,
  });

  /// The session display name (editable).
  final String name;

  /// Planned exercises in order.
  final List<PlannedExerciseView> exercises;

  /// Estimated duration in minutes.
  final int estimatedMinutes;

  /// Total planned working sets.
  final int targetSets;

  /// Estimated target volume (weight x reps), or 0 when unknown.
  final double targetVolume;

  /// Distinct muscle groups trained.
  List<String> get muscleGroups {
    final result = <String>{};
    for (final exercise in exercises) {
      if (exercise.muscleGroup.isNotEmpty) result.add(exercise.muscleGroup);
    }
    return result.toList()..sort();
  }

  /// Whether any exercise lacks a previous performance to build from.
  bool get hasNoPrevious =>
      exercises.any((exercise) => exercise.lastWeight == null);
}
