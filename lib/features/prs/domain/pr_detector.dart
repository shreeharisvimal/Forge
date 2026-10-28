// Live PR detection for the Forge application.
//
// Pure functions only — no Flutter or Riverpod imports. Answers "does this
// in-progress exercise beat the stored record right now?" for every tracked
// record type, so the active workout can show a live badge the moment a set
// goes past the previous best.
library;

import '../../../models/personal_record.dart';
import '../../../models/workout_exercise.dart';
import 'one_rep_max.dart';
import 'pr_calculator.dart';
import 'pr_types.dart';

/// Live per-set detection against stored lifetime records.
abstract final class PrDetector {
  PrDetector._();

  /// Live per-type comparisons of the in-progress [exercise] against the
  /// stored lifetime [record]. Future-proof types are omitted until a
  /// measurement exists.
  static List<PrComparison> live(
    WorkoutExercise exercise, {
    PersonalRecord? record,
    OneRepMaxFormula formula = OneRepMaxFormula.epley,
  }) {
    final metrics = PrCalculator.metricsFor(exercise, formula: formula);
    if (metrics.completedSets == 0) return const [];
    return [
      PrCalculator.compare(
        type: PrType.heaviestWeight,
        value: metrics.bestWeight,
        previous: record?.highestWeight,
      ),
      PrCalculator.compare(
        type: PrType.mostReps,
        value: metrics.bestReps.toDouble(),
        previous: record?.bestReps.toDouble(),
      ),
      PrCalculator.compare(
        type: PrType.estimatedOneRM,
        value: metrics.bestOneRM,
        previous: record?.estimatedOneRM,
      ),
      PrCalculator.compare(
        type: PrType.bestVolume,
        value: metrics.volume,
        previous: record?.bestVolume,
      ),
    ];
  }
}
