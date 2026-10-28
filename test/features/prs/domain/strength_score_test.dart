// Tests for the composite strength score.
//
// Verifies the 0-100 Forge composite, the DOTS and Wilks formulas against the
// published worked examples, and the null guards when inputs are missing.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/domain/strength_score.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/models/workout_session.dart';

PersonalRecord record(
  String exerciseId, {
  double oneRM = 0,
  double weight = 0,
  int reps = 0,
}) {
  return PersonalRecord(
    exerciseId: exerciseId,
    estimatedOneRM: oneRM,
    highestWeight: weight,
    bestReps: reps,
  );
}

WorkoutSet set(double weight, int reps) =>
    WorkoutSet(weight: weight, reps: reps, completed: true);

WorkoutExercise exercise(String id, List<WorkoutSet> sets) =>
    WorkoutExercise(exerciseId: id, exerciseName: id, sets: sets);

WorkoutSession sessionAt(DateTime date, {List<WorkoutExercise>? exercises}) =>
    WorkoutSession(date: date, exercises: exercises ?? const []);

void main() {
  final now = DateTime(2026, 2, 4, 12);

  group('StrengthScoreCalculator.calculate', () {
    test('empty history reports no data', () {
      final score = StrengthScoreCalculator.calculate(
        records: const [],
        sessions: const [],
        now: now,
      );
      expect(score.hasData, isFalse);
      expect(score.overall, 0);
      expect(score.exercises, 0);
      expect(score.dots, isNull);
      expect(score.wilks, isNull);
    });

    test('sums record 1RMs and tracks exercise count and best', () {
      final score = StrengthScoreCalculator.calculate(
        records: [
          record('bench', oneRM: 100),
          record('squat', oneRM: 150),
          record('deadlift', oneRM: 130),
        ],
        sessions: const [],
        now: now,
      );
      expect(score.exercises, 3);
      expect(score.totalOneRM, 380);
      expect(score.bestOneRM, 150);
    });

    test('computes the body-weight ratio from the best lift', () {
      final score = StrengthScoreCalculator.calculate(
        records: [record('bench', oneRM: 150)],
        sessions: const [],
        bodyWeightKg: 75,
        now: now,
      );
      expect(score.bodyweightRatio, 2.0);
    });

    test('counts completed workouts in the trailing 28 days', () {
      final sessions = [
        sessionAt(now.subtract(const Duration(days: 2))),
        sessionAt(now.subtract(const Duration(days: 5))),
        sessionAt(now.subtract(const Duration(days: 40))),
      ];
      final score = StrengthScoreCalculator.calculate(
        records: const [],
        sessions: sessions,
        now: now,
      );
      // Sessions without completed sets do not count towards frequency.
      expect(score.workoutsPerWeek, 0);
    });

    test('ignores sessions without completed sets for volume', () {
      final sessions = [
        WorkoutSession(
          date: now,
          exercises: [
            exercise('bench', [WorkoutSet(weight: 100, reps: 5)]),
          ],
        ),
      ];
      final score = StrengthScoreCalculator.calculate(
        records: const [],
        sessions: sessions,
        now: now,
      );
      expect(score.lifetimeVolume, 0);
      expect(score.hasData, isFalse);
    });

    test('reaches 100 at full scale on every factor', () {
      final records = [
        record('bench', oneRM: 500),
        record('squat', oneRM: 500),
        record('deadlift', oneRM: 500),
      ];
      final sessions = [
        for (var i = 0; i < 20; i++)
          WorkoutSession(
            date: now.subtract(Duration(days: i % 10)),
            exercises: [
              exercise('bench', [set(100, 1)]),
            ],
          ),
        // Volume drive to the 100000 cap.
        WorkoutSession(
          date: now,
          exercises: [
            exercise(
              'bench',
              [for (var i = 0; i < 20; i++) set(100, 50)],
            ),
          ],
        ),
      ];
      final score = StrengthScoreCalculator.calculate(
        records: records,
        sessions: sessions,
        bodyWeightKg: 250,
        now: now,
      );
      expect(score.overall, closeTo(100, 0.001));
      expect(score.lifetimeVolume, greaterThanOrEqualTo(100000));
      expect(score.workoutsPerWeek, greaterThanOrEqualTo(5));
    });

    test('clamps the composite to 100 when a factor is oversized', () {
      final score = StrengthScoreCalculator.calculate(
        records: [record('bench', oneRM: 99999)],
        sessions: const [],
        bodyWeightKg: 1,
        now: now,
      );
      expect(score.overall, lessThanOrEqualTo(100));
    });
  });

  group('StrengthScoreCalculator.dots', () {
    test('matches the published worked example (male, 80kg, 500kg total)', () {
      // Official DOTS example: denominator ~725.11 -> score ~344.77.
      expect(
        StrengthScoreCalculator.dots(totalOneRM: 500, bodyWeightKg: 80),
        closeTo(344.77, 0.05),
      );
    });

    test('is null when either input is missing', () {
      expect(
        StrengthScoreCalculator.dots(totalOneRM: 0, bodyWeightKg: 80),
        isNull,
      );
      expect(
        StrengthScoreCalculator.dots(totalOneRM: 500, bodyWeightKg: 0),
        isNull,
      );
    });

    test('clamps body weight to the official band', () {
      final clamped =
          StrengthScoreCalculator.dots(totalOneRM: 300, bodyWeightKg: 20);
      final atBand =
          StrengthScoreCalculator.dots(totalOneRM: 300, bodyWeightKg: 40);
      expect(clamped, atBand);
    });

    test('uses different male and female curves', () {
      final male = StrengthScoreCalculator.dots(
        totalOneRM: 500,
        bodyWeightKg: 70,
        gender: StrengthGender.male,
      );
      final female = StrengthScoreCalculator.dots(
        totalOneRM: 500,
        bodyWeightKg: 70,
        gender: StrengthGender.female,
      );
      expect(male, isNotNull);
      expect(female, isNotNull);
      expect(male, isNot(closeTo(female!, 0.001)));
    });
  });

  group('StrengthScoreCalculator.wilks', () {
    test('matches the known Wilks value (male, 80kg, 500kg total)', () {
      // The classic Wilks table puts an 80kg male with a 500kg total around
      // 341.3 points.
      expect(
        StrengthScoreCalculator.wilks(totalOneRM: 500, bodyWeightKg: 80),
        closeTo(341.3, 0.5),
      );
    });

    test('is null when either input is missing', () {
      expect(
        StrengthScoreCalculator.wilks(totalOneRM: 0, bodyWeightKg: 80),
        isNull,
      );
      expect(
        StrengthScoreCalculator.wilks(totalOneRM: 500, bodyWeightKg: 0),
        isNull,
      );
    });

    test('differs between genders at the same body weight', () {
      final male = StrengthScoreCalculator.wilks(
        totalOneRM: 500,
        bodyWeightKg: 70,
        gender: StrengthGender.male,
      );
      final female = StrengthScoreCalculator.wilks(
        totalOneRM: 500,
        bodyWeightKg: 70,
        gender: StrengthGender.female,
      );
      expect(male, isNotNull);
      expect(female, isNotNull);
      expect(male, isNot(closeTo(female!, 0.001)));
    });
  });
}
