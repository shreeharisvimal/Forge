// Tests for the PR calculator.
//
// Verifies per-exercise metric aggregation, volume queries and the comparison
// rules (first-ever, tie, lifetime beat, miss) with their epsilon tolerance.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/domain/one_rep_max.dart';
import 'package:forge/features/prs/domain/pr_calculator.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/models/workout_session.dart';

WorkoutSet completedSet({double weight = 0, int reps = 0, bool isWarmup = false}) {
  return WorkoutSet(weight: weight, reps: reps, completed: true, isWarmup: isWarmup);
}

WorkoutSet incompleteSet({double weight = 0, int reps = 0}) {
  return WorkoutSet(weight: weight, reps: reps, completed: false);
}

WorkoutExercise exercise({
  List<WorkoutSet> sets = const [],
  String exerciseId = 'bench',
  String exerciseName = 'Bench Press',
}) {
  return WorkoutExercise(exerciseId: exerciseId, exerciseName: exerciseName, sets: sets);
}

void main() {
  group('PrCalculator.metricsFor', () {
    test('aggregates completed, non-warm-up sets', () {
      final metrics = PrCalculator.metricsFor(
        exercise(sets: [
          completedSet(weight: 100, reps: 5),
          completedSet(weight: 90, reps: 8),
          completedSet(weight: 60, reps: 12, isWarmup: true),
          incompleteSet(weight: 120, reps: 1),
        ]),
      );

      expect(metrics.completedSets, 2);
      expect(metrics.bestWeight, 100);
      expect(metrics.bestReps, 8);
      // max(100 * (1 + 5/30), 90 * (1 + 8/30)) = max(116.67, 114)
      expect(metrics.bestOneRM, closeTo(116.667, 0.001));
      // 100*5 + 90*8 = 1220; warm-up and incomplete sets excluded.
      expect(metrics.volume, 1220);
    });

    test('best one-rep max respects the configured formula', () {
      final metrics = PrCalculator.metricsFor(
        exercise(sets: [completedSet(weight: 100, reps: 10)]),
        formula: OneRepMaxFormula.brzycki,
      );
      expect(metrics.bestOneRM, closeTo(133.333, 0.001));
    });

    test('empty exercises yield zeroed metrics', () {
      final metrics = PrCalculator.metricsFor(exercise());
      expect(metrics.completedSets, 0);
      expect(metrics.bestWeight, 0);
      expect(metrics.bestReps, 0);
      expect(metrics.bestOneRM, 0);
      expect(metrics.volume, 0);
    });
  });

  group('PrCalculator volume queries', () {
    final single = WorkoutSession(
      date: DateTime(2026, 2, 4),
      exercises: [exercise(sets: [completedSet(weight: 100, reps: 5)])],
    );
    final double = WorkoutSession(
      date: DateTime(2026, 2, 6),
      exercises: [exercise(sets: [completedSet(weight: 60, reps: 10)])],
    );
    final older = WorkoutSession(
      date: DateTime(2025, 12, 1),
      exercises: [exercise(sets: [completedSet(weight: 50, reps: 10)])],
    );

    test('exerciseVolume sums completed sets', () {
      expect(PrCalculator.exerciseVolume(single.exercises.first), 500);
    });

    test('workoutVolume sums every exercise', () {
      final session = WorkoutSession(
        date: DateTime(2026, 2, 4),
        exercises: [
          exercise(sets: [completedSet(weight: 100, reps: 5)]),
          exercise(
            sets: [completedSet(weight: 60, reps: 10)],
            exerciseId: 'squat',
            exerciseName: 'Squat',
          ),
        ],
      );
      expect(PrCalculator.workoutVolume(session), 1100);
    });

    test('volumeBetween is inclusive and date-bounded', () {
      final sessions = [single, double, older];
      expect(
        PrCalculator.volumeBetween(
          sessions,
          DateTime(2026, 2, 1),
          DateTime(2026, 2, 7),
        ),
        1100,
      );
    });

    test('weeklyVolume counts from the Monday of the given week', () {
      // Feb 4 2026 is a Wednesday; the week started Monday Feb 2.
      expect(PrCalculator.weeklyVolume([single, older], DateTime(2026, 2, 4)), 500);
    });

    test('monthlyVolume counts from the first of the month', () {
      expect(PrCalculator.monthlyVolume([single, older], DateTime(2026, 2, 4)), 500);
    });

    test('lifetimeVolume ignores dates', () {
      expect(PrCalculator.lifetimeVolume([single, double, older]), 1600);
    });
  });

  group('PrCalculator.compare', () {
    test('first ever yields newPr with firstEver scope', () {
      final result = PrCalculator.compare(type: PrType.heaviestWeight, value: 100);
      expect(result.status, PrStatus.newPr);
      expect(result.scope, PrScope.firstEver);
      expect(result.isPr, isTrue);
      expect(result.previous, isNull);
      expect(result.difference, 100);
    });

    test('a beat within epsilon is a tie, not a PR', () {
      final result = PrCalculator.compare(
        type: PrType.heaviestWeight,
        value: 100.005,
        previous: 100,
      );
      expect(result.status, PrStatus.tiedPr);
      expect(result.isPr, isFalse);
    });

    test('beating the previous best is a lifetime PR', () {
      final result = PrCalculator.compare(
        type: PrType.mostReps,
        value: 10,
        previous: 8,
      );
      expect(result.status, PrStatus.newPr);
      expect(result.scope, PrScope.lifetime);
      expect(result.isPr, isTrue);
      expect(result.previous, 8);
      expect(result.difference, 2);
    });

    test('falling short of the previous best is noPr', () {
      final result = PrCalculator.compare(
        type: PrType.mostReps,
        value: 7,
        previous: 8,
      );
      expect(result.status, PrStatus.noPr);
      expect(result.isPr, isFalse);
      expect(result.difference, -1);
    });
  });
}
