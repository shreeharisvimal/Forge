// Personal Record engine for the Forge application.
//
// The engine owns PR detection: given a finished session it walks every
// performed exercise, computes the session bests and compares them against
// the stored lifetime bests, returning the events that should be appended to
// the timeline. It never writes history or record rows itself — the session
// service remains the single mutation point for those — it only produces the
// append-only [PrEvent] stream that preserves the PR history.
library;

import '../../../models/personal_record.dart';
import '../../../models/workout_session.dart';
import '../../../services/repositories/personal_record_repository.dart';
import '../data/pr_event.dart';
import '../data/pr_event_repository.dart';
import 'one_rep_max.dart';
import 'pr_calculator.dart';
import 'pr_types.dart';

/// Detects and serializes personal-record events.
class PrEngine {
  /// Creates the engine with its repositories.
  PrEngine({
    required this.personalRecordRepository,
    required this.prEventRepository,
  });

  /// Repository for lifetime bests.
  final PersonalRecordRepository personalRecordRepository;

  /// Repository for the append-only event timeline.
  final PrEventRepository prEventRepository;

  /// Detects the new records produced by the finished [session] and returns
  /// the events that must be persisted (new records only, in exercise order).
  ///
  /// Comparisons use the stored lifetime record at detection time. Future-proof
  /// record types are skipped until a set model carries a measurement for them.
  List<PrEvent> evaluateSession(
    WorkoutSession session, {
    OneRepMaxFormula formula = OneRepMaxFormula.epley,
  }) {
    final events = <PrEvent>[];
    for (final performed in session.exercises) {
      final metrics = PrCalculator.metricsFor(performed, formula: formula);
      if (metrics.completedSets == 0) continue;

      final record = personalRecordRepository.forExercise(performed.exerciseId);
      final candidates = <PrType, double>{
        PrType.heaviestWeight: metrics.bestWeight,
        PrType.mostReps: metrics.bestReps.toDouble(),
        PrType.estimatedOneRM: metrics.bestOneRM,
        PrType.bestVolume: metrics.volume,
      };

      for (final type in PrType.values) {
        final value = candidates[type];
        if (value == null || value <= 0) continue;
        final previous = _previousValue(record, type);
        final comparison = PrCalculator.compare(
          type: type,
          value: value,
          previous: previous,
        );
        if (!comparison.isPr) continue;
        events.add(PrEvent(
          exerciseId: performed.exerciseId,
          exerciseName: performed.exerciseName,
          type: type.name,
          value: value,
          previousValue: previous ?? 0,
          date: session.date,
          workoutId: session.id,
          formula: formula.storageKey,
          calculatedOneRM: metrics.bestOneRM,
        ));
      }
    }
    return events;
  }

  /// The stored best for [type] on [record], or null when no row exists.
  double? _previousValue(PersonalRecord? record, PrType type) => switch (type) {
        PrType.heaviestWeight => record?.highestWeight,
        PrType.mostReps => record?.bestReps.toDouble(),
        PrType.estimatedOneRM => record?.estimatedOneRM,
        PrType.bestVolume => record?.bestVolume,
        _ => null,
      };
}
