// One-rep-max estimation for the Forge application.
//
// Pure formula implementations, no I/O. Every formula returns 0 for sets
// without a meaningful load or repetition count so callers can safely skip
// bodyweight-only or incomplete sets.
library;

import 'dart:math';

/// The one-rep-max estimation formulas supported by the engine.
enum OneRepMaxFormula {
  /// Epley: weight x (1 + reps / 30).
  epley('epley'),

  /// Brzycki: weight x 36 / (37 - reps).
  brzycki('brzycki'),

  /// Lombardi: weight x reps^0.10.
  lombardi('lombardi');

  const OneRepMaxFormula(this.storageKey);

  /// The persisted settings-string representation.
  final String storageKey;

  /// Parses a settings string ('epley' etc.); unknown values default to
  /// [epley] so a fresh install never resolves to an invalid formula.
  static OneRepMaxFormula fromStorageKey(String? key) =>
      values.firstWhere(
        (formula) => formula.storageKey == key,
        orElse: () => OneRepMaxFormula.epley,
      );
}

/// One-rep-max estimation math.
abstract final class OneRepMax {
  OneRepMax._();

  /// Estimates the one-rep max for a [weight] x [reps] set using [formula].
  ///
  /// Returns 0 when [weight] or [reps] is not positive.
  static double estimate(
    double weight,
    int reps, {
    OneRepMaxFormula formula = OneRepMaxFormula.epley,
  }) {
    if (weight <= 0 || reps <= 0) return 0;
    return switch (formula) {
      OneRepMaxFormula.epley => weight * (1 + reps / 30),
      // Brzycki divides by (37 - reps); cap reps at 36 so the denominator
      // never reaches zero for very high rep sets.
      OneRepMaxFormula.brzycki => weight * (36 / (37 - reps.clamp(1, 36))),
      OneRepMaxFormula.lombardi => weight * pow(reps, 0.10).toDouble(),
    };
  }
}
