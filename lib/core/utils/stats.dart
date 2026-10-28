// Training statistics helpers for the Forge application.
//
// Pure functions for the derived numbers shown across the app: one-rep-max
// estimates, set volume and session totals. No I/O here.
library;

import 'dart:math';

import '../../models/workout_session.dart';
import '../../models/workout_set.dart';

/// Estimates a one-rep max using the Epley formula.
///
/// Returns 0 for non-positive [reps] (bodyweight-only or incomplete sets
/// have no meaningful 1RM).
double estimateOneRM(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return 0;
  return weight * (1 + reps / 30);
}

/// The tonnage of a single set: weight x reps.
double setVolume(WorkoutSet set) => set.weight * set.reps;

/// The tonnage of every completed set in [session].
double sessionVolume(WorkoutSession session) {
  var total = 0.0;
  for (final exercise in session.exercises) {
    for (final set in exercise.sets) {
      if (set.completed) total += setVolume(set);
    }
  }
  return total;
}

/// Rounds [value] to [precision] decimal places.
double roundTo(double value, [int precision = 2]) {
  final factor = pow(10, precision).toDouble();
  return (value * factor).roundToDouble() / factor;
}
