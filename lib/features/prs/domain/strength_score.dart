// Composite strength score for the Forge application.
//
// Pure math only — no Flutter or Riverpod imports. Turns the stored records
// and performed sessions into a single 0-100 Forge score plus the standard
// DOTS / Wilks points, so a user's whole training history fits on one card.
library;

import 'dart:math';

import '../../../models/personal_record.dart';
import '../../../models/workout_session.dart';
import 'pr_calculator.dart';

/// The strength-score systems the [StrengthScore] can report.
enum StrengthFormula {
  /// The Forge composite 0-100 score.
  overall,

  /// OpenPowerlifting DOTS points.
  dots,

  /// Wilks coefficient-based points.
  wilks,
}

/// Body-weight class used by the DOTS / Wilks score systems.
///
/// Future-ready: Forge does not collect a gender today, so callers default
/// to the [male] coefficients and can switch once the profile exists.
enum StrengthGender {
  /// Male coefficients.
  male,

  /// Female coefficients.
  female,
}

/// The composite strength score for the whole training history.
class StrengthScore {
  /// Creates a strength score.
  const StrengthScore({
    required this.exercises,
    required this.totalOneRM,
    required this.bestOneRM,
    required this.bodyweightRatio,
    required this.lifetimeVolume,
    required this.workoutsPerWeek,
    required this.overall,
    this.dots,
    this.wilks,
  });

  /// Number of exercises with a stored record.
  final int exercises;

  /// Sum of every exercise's current estimated one-rep max.
  final double totalOneRM;

  /// Highest single estimated one-rep max across exercises.
  final double bestOneRM;

  /// [bestOneRM] divided by the latest body weight (unit-agnostic).
  final double bodyweightRatio;

  /// Total volume moved across all completed sessions.
  final double lifetimeVolume;

  /// Completed workouts per week over the trailing four weeks.
  final double workoutsPerWeek;

  /// The Forge composite score, 0-100.
  final double overall;

  /// OpenPowerlifting DOTS points, or null when inputs are missing.
  final double? dots;

  /// Wilks points, or null when inputs are missing.
  final double? wilks;

  /// Whether any meaningful training data exists yet.
  bool get hasData => exercises > 0 || lifetimeVolume > 0;
}

/// Computes the composite strength score and its standard variants.
abstract final class StrengthScoreCalculator {
  StrengthScoreCalculator._();

  /// The Forge composite 0-100 strength score.
  ///
  /// Four normalized sub-scores drive the composite: total estimated 1RM,
  /// best lift to body-weight ratio, lifetime volume and weekly frequency.
  /// [now] pins the four-week window for tests.
  static StrengthScore calculate({
    required List<PersonalRecord> records,
    required List<WorkoutSession> sessions,
    double bodyWeightKg = 0,
    DateTime? now,
    StrengthGender gender = StrengthGender.male,
  }) {
    final reference = now ?? DateTime.now();
    var totalOneRM = 0.0;
    var bestOneRM = 0.0;
    for (final record in records) {
      totalOneRM += record.estimatedOneRM;
      bestOneRM = max(bestOneRM, record.estimatedOneRM);
    }

    var volume = 0.0;
    var recentWorkouts = 0;
    final monthAgo = reference.subtract(const Duration(days: 28));
    for (final session in sessions) {
      if (!_hasCompletedSets(session)) continue;
      volume += PrCalculator.workoutVolume(session);
      if (!session.date.isBefore(monthAgo)) recentWorkouts++;
    }

    final bodyweightRatio =
        bodyWeightKg > 0 && bestOneRM > 0 ? bestOneRM / bodyWeightKg : 0.0;
    final workoutsPerWeek = recentWorkouts / 4.0;

    final oneRmFactor = (totalOneRM / 1500).clamp(0.0, 1.0);
    final ratioFactor = (bodyweightRatio / 2.0).clamp(0.0, 1.0);
    final volumeFactor = (volume / 100000).clamp(0.0, 1.0);
    final frequencyFactor = (workoutsPerWeek / 5).clamp(0.0, 1.0);
    final overall =
        (0.35 * oneRmFactor +
            0.30 * ratioFactor +
            0.20 * volumeFactor +
            0.15 * frequencyFactor) *
        100;

    return StrengthScore(
      exercises: records.length,
      totalOneRM: totalOneRM,
      bestOneRM: bestOneRM,
      bodyweightRatio: bodyweightRatio,
      lifetimeVolume: volume,
      workoutsPerWeek: workoutsPerWeek,
      overall: overall,
      dots: dots(totalOneRM: totalOneRM, bodyWeightKg: bodyWeightKg, gender: gender),
      wilks: wilks(totalOneRM: totalOneRM, bodyWeightKg: bodyWeightKg, gender: gender),
    );
  }

  /// OpenPowerlifting DOTS points for [totalOneRM] at [bodyWeightKg].
  ///
  /// Uses the official 4th-degree DOTS polynomial (Tim Konertz, 2020) with the
  /// published body-weight band. Returns null when either input is missing so
  /// the caller can hide the score instead of showing a misleading number.
  static double? dots({
    required double totalOneRM,
    required double bodyWeightKg,
    StrengthGender gender = StrengthGender.male,
  }) {
    if (totalOneRM <= 0 || bodyWeightKg <= 0) return null;
    final bw = switch (gender) {
      StrengthGender.male => bodyWeightKg.clamp(40.0, 210.0),
      StrengthGender.female => bodyWeightKg.clamp(40.0, 150.0),
    }.toDouble();
    final bw2 = bw * bw;
    final bw3 = bw2 * bw;
    final bw4 = bw3 * bw;
    final denominator = switch (gender) {
      StrengthGender.male =>
        -307.75076 +
            (24.0900756 * bw) +
            (-0.1918759221 * bw2) +
            (0.0007391293 * bw3) +
            (-0.0000010930 * bw4),
      StrengthGender.female =>
        -57.96288 +
            (13.6175032 * bw) +
            (-0.1126655495 * bw2) +
            (0.0005158568 * bw3) +
            (-0.0000010706 * bw4),
    };
    if (denominator <= 0) return null;
    return totalOneRM * 500 / denominator;
  }

  /// Wilks points for [totalOneRM] at [bodyWeightKg] using the standard
  /// coefficients. Returns null when either input is missing.
  static double? wilks({
    required double totalOneRM,
    required double bodyWeightKg,
    StrengthGender gender = StrengthGender.male,
  }) {
    if (totalOneRM <= 0 || bodyWeightKg <= 0) return null;
    final bw = bodyWeightKg;
    final denominator = switch (gender) {
      StrengthGender.male =>
        -216.0475144 +
            (16.2606339 * bw) +
            (-0.002388645 * pow(bw, 2)) +
            (-0.00113732 * pow(bw, 3)) +
            (7.01863e-6 * pow(bw, 4)) +
            (-1.291e-8 * pow(bw, 5)),
      StrengthGender.female =>
        594.31747775582 +
            (-27.23842536447 * bw) +
            (0.82112226871 * pow(bw, 2)) +
            (-0.00930733913 * pow(bw, 3)) +
            (4.731582e-5 * pow(bw, 4)) +
            (-9.054e-8 * pow(bw, 5)),
    };
    if (denominator <= 0) return null;
    return totalOneRM * 500 / denominator;
  }

  static bool _hasCompletedSets(WorkoutSession session) {
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) return true;
      }
    }
    return false;
  }
}
