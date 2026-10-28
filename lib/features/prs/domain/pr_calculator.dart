// PR detection and strength math for the Forge application.
//
// Pure functions only — no Flutter or Riverpod imports. The engine, the
// providers and the widgets all build on these, so the entire detection
// pipeline is unit-testable without a widget tree.
library;

import 'dart:math';

import '../../../core/utils/dates.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_session.dart';
import 'one_rep_max.dart';
import 'pr_types.dart';

/// Per-exercise metrics extracted from a performed workout.
class PrExerciseMetrics {
  /// Creates exercise metrics.
  const PrExerciseMetrics({
    required this.completedSets,
    required this.bestWeight,
    required this.bestReps,
    required this.bestOneRM,
    required this.volume,
    required this.bestHoldSeconds,
    required this.bestTimeSeconds,
  });

  /// Number of completed sets.
  final int completedSets;

  /// Heaviest single completed lift.
  final double bestWeight;

  /// Most repetitions in a single completed set.
  final int bestReps;

  /// Highest estimated one-rep max across completed sets.
  final double bestOneRM;

  /// Total volume (weight x reps) of completed sets.
  final double volume;

  /// Longest isometric hold across completed sets (future-proof).
  final double bestHoldSeconds;

  /// Fastest recorded time across completed sets (future-proof).
  final double bestTimeSeconds;
}

/// The outcome of comparing a candidate value against a previous best.
class PrComparison {
  /// Creates a comparison.
  const PrComparison({
    required this.type,
    required this.status,
    required this.scope,
    required this.value,
    this.previous,
  });

  /// The record type being compared.
  final PrType type;

  /// Whether the candidate is a new, tied or no PR.
  final PrStatus status;

  /// How the record was broken (first ever, session, lifetime).
  final PrScope scope;

  /// The candidate value.
  final double value;

  /// The previous best, or null for a first-ever record.
  final double? previous;

  /// Signed improvement over [previous] (the candidate when there is none).
  double get difference => previous == null ? value : value - previous!;

  /// Whether the candidate established a new PR.
  bool get isPr => status == PrStatus.newPr;
}

/// Per-exercise and whole-session metrics and comparisons.
abstract final class PrCalculator {
  PrCalculator._();

  /// Aggregates the completed sets of [exercise] into [PrExerciseMetrics].
  ///
  /// Warm-up and incomplete sets are ignored. The future-proof hold/time
  /// metrics read 0 until a set model carries those measurements.
  static PrExerciseMetrics metricsFor(
    WorkoutExercise exercise, {
    OneRepMaxFormula formula = OneRepMaxFormula.epley,
  }) {
    var completedSets = 0;
    var bestWeight = 0.0;
    var bestReps = 0;
    var bestOneRM = 0.0;
    var volume = 0.0;
    for (final set in exercise.sets) {
      if (!set.completed || set.isWarmup) continue;
      completedSets++;
      bestWeight = max(bestWeight, set.weight);
      bestReps = max(bestReps, set.reps);
      bestOneRM = max(
        bestOneRM,
        OneRepMax.estimate(set.weight, set.reps, formula: formula),
      );
      volume += set.weight * set.reps;
    }
    return PrExerciseMetrics(
      completedSets: completedSets,
      bestWeight: bestWeight,
      bestReps: bestReps,
      bestOneRM: bestOneRM,
      volume: volume,
      bestHoldSeconds: 0,
      bestTimeSeconds: 0,
    );
  }

  /// Volume (weight x reps) of every completed set in [exercise].
  static double exerciseVolume(WorkoutExercise exercise) {
    var total = 0.0;
    for (final set in exercise.sets) {
      if (set.completed) total += set.weight * set.reps;
    }
    return total;
  }

  /// Volume of every completed set across [session].
  static double workoutVolume(WorkoutSession session) {
    var total = 0.0;
    for (final exercise in session.exercises) {
      total += exerciseVolume(exercise);
    }
    return total;
  }

  /// Volume of completed sets across [sessions] within the inclusive day
  /// range [from]..[to].
  static double volumeBetween(
    List<WorkoutSession> sessions,
    DateTime from,
    DateTime to,
  ) {
    var total = 0.0;
    for (final session in sessions) {
      if (!isBetweenInclusive(session.date, from, to)) continue;
      total += workoutVolume(session);
    }
    return total;
  }

  /// Volume from the start of the week containing [now] through [now].
  static double weeklyVolume(List<WorkoutSession> sessions, DateTime now) {
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return volumeBetween(sessions, start, now);
  }

  /// Volume from the first day of [now]'s month through [now].
  static double monthlyVolume(List<WorkoutSession> sessions, DateTime now) {
    final start = DateTime(now.year, now.month, 1);
    return volumeBetween(sessions, start, now);
  }

  /// Volume of every completed session, ignoring the date.
  static double lifetimeVolume(List<WorkoutSession> sessions) {
    var total = 0.0;
    for (final session in sessions) {
      total += workoutVolume(session);
    }
    return total;
  }

  /// Compares [value] against [previous] for [type].
  ///
  /// A `null` [previous] means first ever. Values within [epsilon] of each
  /// other are treated as a tie so weight rounding never mints false PRs.
  static PrComparison compare({
    required PrType type,
    required double value,
    double? previous,
    double epsilon = 0.01,
  }) {
    if (previous == null) {
      return PrComparison(
        type: type,
        status: PrStatus.newPr,
        scope: PrScope.firstEver,
        value: value,
      );
    }
    final difference = value - previous;
    if (difference.abs() <= epsilon) {
      return PrComparison(
        type: type,
        status: PrStatus.tiedPr,
        scope: PrScope.lifetime,
        value: value,
        previous: previous,
      );
    }
    if (difference > 0) {
      return PrComparison(
        type: type,
        status: PrStatus.newPr,
        scope: PrScope.lifetime,
        value: value,
        previous: previous,
      );
    }
    return PrComparison(
      type: type,
      status: PrStatus.noPr,
      scope: PrScope.lifetime,
      value: value,
      previous: previous,
    );
  }
}
