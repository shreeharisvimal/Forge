// Tests for live PR detection.
//
// Verifies the per-type comparisons produced for an in-progress exercise
// against the stored lifetime record, including the empty and first-ever
// cases.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/domain/pr_detector.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_set.dart';

WorkoutExercise exercise({List<WorkoutSet> sets = const []}) {
  return WorkoutExercise(
    exerciseId: 'bench',
    exerciseName: 'Bench Press',
    sets: sets,
  );
}

void main() {
  test('returns nothing for an exercise without completed sets', () {
    final result = PrDetector.live(
      exercise(sets: [
        WorkoutSet(weight: 100, reps: 5),
        WorkoutSet(weight: 100, reps: 5, completed: true, isWarmup: true),
      ]),
    );
    expect(result, isEmpty);
  });

  test('a first-ever set flags every record type as new', () {
    final result = PrDetector.live(
      exercise(sets: [
        WorkoutSet(weight: 100, reps: 5, completed: true),
      ]),
    );

    expect(result.map((c) => c.type), [
      PrType.heaviestWeight,
      PrType.mostReps,
      PrType.estimatedOneRM,
      PrType.bestVolume,
    ]);
    for (final comparison in result) {
      expect(comparison.status, PrStatus.newPr);
      expect(comparison.scope, PrScope.firstEver);
      expect(comparison.isPr, isTrue);
    }
  });

  test('beating the stored record flags lifetime PRs with deltas', () {
    final record = PersonalRecord(
      exerciseId: 'bench',
      highestWeight: 80,
      bestReps: 6,
      estimatedOneRM: 96,
      bestVolume: 500,
    );

    final result = PrDetector.live(
      exercise(sets: [
        WorkoutSet(weight: 80, reps: 6, completed: true),
        WorkoutSet(weight: 100, reps: 5, completed: true),
      ]),
      record: record,
    );

    final byType = {for (final c in result) c.type: c};
    // bestWeight 100 > 80
    expect(byType[PrType.heaviestWeight]!.status, PrStatus.newPr);
    expect(byType[PrType.heaviestWeight]!.previous, 80);
    // bestReps 6 == 6
    expect(byType[PrType.mostReps]!.status, PrStatus.tiedPr);
    // best 1RM max(116.67, 96) > 96
    expect(byType[PrType.estimatedOneRM]!.status, PrStatus.newPr);
    // volume 480 + 500 = 980 > 500
    expect(byType[PrType.bestVolume]!.status, PrStatus.newPr);
    expect(byType[PrType.bestVolume]!.difference, 480);
  });

  test('missing the stored record reports noPr', () {
    final record = PersonalRecord(
      exerciseId: 'bench',
      highestWeight: 120,
      bestReps: 10,
      estimatedOneRM: 140,
      bestVolume: 1500,
    );

    final result = PrDetector.live(
      exercise(sets: [
        WorkoutSet(weight: 100, reps: 5, completed: true),
      ]),
      record: record,
    );

    for (final comparison in result) {
      expect(comparison.status, PrStatus.noPr);
      expect(comparison.isPr, isFalse);
    }
  });

  test('future-proof types are omitted until a measurement exists', () {
    final result = PrDetector.live(
      exercise(sets: [
        WorkoutSet(weight: 100, reps: 5, completed: true),
      ]),
    );
    final types = result.map((c) => c.type).toSet();
    expect(types, isNot(contains(PrType.longestHold)));
    expect(types, isNot(contains(PrType.bestTime)));
  });
}
