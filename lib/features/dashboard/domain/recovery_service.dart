// Muscle recovery estimation for the Forge application.
//
// Estimates how recovered each of the six dashboard muscle buckets is from
// the session history: every performed exercise is attributed to a bucket,
// the most recent training date per bucket is found, and recovery decays
// linearly over a per-bucket rest window.
//
// Pure functions only — no Flutter or Riverpod imports.
library;

import '../../../core/constants/exercise_categories.dart';
import '../../../models/exercise.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_session.dart';
import 'dashboard_models.dart';

/// Default rest windows (hours) before a bucket is considered fully rested.
///
/// Science-backed ballparks: large muscles and lower-body work need more
/// time than small isolation muscles.
abstract final class RecoveryWindows {
  RecoveryWindows._();

  /// Hours to full recovery for each bucket.
  static const Map<RecoveryGroup, int> hours = {
    RecoveryGroup.chest: 48,
    RecoveryGroup.back: 72,
    RecoveryGroup.shoulders: 48,
    RecoveryGroup.arms: 48,
    RecoveryGroup.legs: 72,
    RecoveryGroup.core: 36,
  };
}

/// Maps the canonical [MuscleGroups] names onto the six dashboard buckets.
///
/// Full-body work counts as training every bucket; cardio and mobility are
/// not attributed to a muscle bucket.
abstract final class RecoveryGroupResolver {
  RecoveryGroupResolver._();

  /// Returns the bucket for a muscle group.
  ///
  /// Full-body returns every bucket, while cardio and mobility return an
  /// empty iterable (they do not fatigue a strength bucket).
  static Iterable<RecoveryGroup> resolve(String muscleGroup) {
    switch (muscleGroup) {
      case MuscleGroups.fullBody:
        return RecoveryGroup.values;
      case MuscleGroups.chest:
        return const [RecoveryGroup.chest];
      case MuscleGroups.back:
      case MuscleGroups.lowerBack:
        return const [RecoveryGroup.back];
      case MuscleGroups.shoulders:
      case MuscleGroups.frontDelts:
      case MuscleGroups.sideDelts:
      case MuscleGroups.rearDelts:
        return const [RecoveryGroup.shoulders];
      case MuscleGroups.biceps:
      case MuscleGroups.triceps:
      case MuscleGroups.forearms:
        return const [RecoveryGroup.arms];
      case MuscleGroups.quadriceps:
      case MuscleGroups.hamstrings:
      case MuscleGroups.glutes:
      case MuscleGroups.calves:
        return const [RecoveryGroup.legs];
      case MuscleGroups.abs:
      case MuscleGroups.obliques:
        return const [RecoveryGroup.core];
      default:
        return const [];
    }
  }
}

/// Computes recovery percentages for every muscle bucket.
abstract final class RecoveryService {
  RecoveryService._();

  /// Builds recovery readings from [sessions] as of [now].
  ///
  /// [resolve] maps a performed exercise to the muscle buckets it fatigues.
  /// Only sessions with at least one completed set count as training.
  /// Buckets never trained report fully recovered with a null
  /// [MuscleRecovery.lastTrained].
  static List<MuscleRecovery> compute({
    required List<WorkoutSession> sessions,
    required DateTime now,
    required Iterable<RecoveryGroup> Function(WorkoutExercise performed) resolve,
  }) {
    final lastTrained = <RecoveryGroup, DateTime>{};
    for (final session in sessions) {
      if (!_hasCompletedSet(session)) continue;
      for (final performed in session.exercises) {
        for (final group in resolve(performed)) {
          _record(lastTrained, group, session.date);
        }
      }
    }
    return [
      for (final group in RecoveryGroup.values)
        _reading(group, lastTrained[group], now),
    ];
  }

  static void _record(
    Map<RecoveryGroup, DateTime> lastTrained,
    RecoveryGroup group,
    DateTime date,
  ) {
    final existing = lastTrained[group];
    if (existing == null || date.isAfter(existing)) {
      lastTrained[group] = date;
    }
  }

  /// Whether [session] contains at least one completed set.
  static bool _hasCompletedSet(WorkoutSession session) {
    for (final performed in session.exercises) {
      for (final set in performed.sets) {
        if (set.completed) return true;
      }
    }
    return false;
  }

  static MuscleRecovery _reading(
    RecoveryGroup group,
    DateTime? lastTrained,
    DateTime now,
  ) {
    if (lastTrained == null) {
      return MuscleRecovery(group: group, percent: 1.0, lastTrained: null);
    }
    final window = RecoveryWindows.hours[group] ?? 48;
    final elapsed =
        now.difference(lastTrained).inHours.toDouble().clamp(0, double.infinity);
    final percent = (elapsed / window).clamp(0.0, 1.0);
    return MuscleRecovery(
      group: group,
      percent: percent,
      lastTrained: lastTrained,
    );
  }
}

/// Default resolver backed by the [Exercise] library.
///
/// Looks up each performed exercise's canonical muscle group by id.
abstract final class LibraryRecoveryResolver {
  LibraryRecoveryResolver._();

  /// Builds a resolver that looks up exercises from [exercisesByGroup].
  ///
  /// [exerciseId] maps to the exercise's muscle group; unknown ids resolve
  /// to no buckets.
  static Iterable<RecoveryGroup> Function(WorkoutExercise) fromLibrary(
    Map<String, Exercise> exercisesById,
  ) {
    return (performed) {
      final exercise = exercisesById[performed.exerciseId];
      if (exercise == null) return const [];
      return RecoveryGroupResolver.resolve(exercise.muscleGroup);
    };
  }
}
