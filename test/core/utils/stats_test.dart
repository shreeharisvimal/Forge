// Unit tests for the Forge training statistics helpers.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/utils/stats.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';

void main() {
  group('estimateOneRM (Epley)', () {
    test('computes weight * (1 + reps / 30)', () {
      // 100kg x 5 -> 100 * (1 + 5/30) = 116.67
      expect(estimateOneRM(100, 5), closeTo(116.67, 0.01));
    });

    test('is linear for bodyweight reps', () {
      expect(estimateOneRM(0, 10), 0);
    });

    test('returns 0 for non-positive reps', () {
      expect(estimateOneRM(100, 0), 0);
      expect(estimateOneRM(100, -3), 0);
    });

    test('returns 0 for non-positive weight', () {
      expect(estimateOneRM(-50, 5), 0);
    });
  });

  group('setVolume', () {
    test('multiplies weight by reps', () {
      final set = WorkoutSet(weight: 80, reps: 8);
      expect(setVolume(set), 640);
    });
  });

  group('sessionVolume', () {
    test('sums only completed sets', () {
      final session = WorkoutSession(
        date: DateTime(2026, 8, 4),
        exercises: [
          WorkoutExercise(
            exerciseId: 'e1',
            exerciseName: 'Squat',
            order: 0,
            sets: [
              WorkoutSet(weight: 100, reps: 5, completed: true),
              WorkoutSet(weight: 100, reps: 5, completed: true),
              WorkoutSet(weight: 100, reps: 3, completed: false),
            ],
          ),
          WorkoutExercise(
            exerciseId: 'e2',
            exerciseName: 'Curl',
            order: 1,
            sets: [WorkoutSet(weight: 20, reps: 10, completed: true)],
          ),
        ],
      );

      expect(sessionVolume(session), (100 * 5) + (100 * 5) + (20 * 10));
    });

    test('is zero for an empty session', () {
      final session = WorkoutSession(date: DateTime(2026, 8, 4));
      expect(sessionVolume(session), 0);
    });
  });

  group('roundTo', () {
    test('rounds to the requested precision', () {
      expect(roundTo(1.2345, 2), 1.23);
      expect(roundTo(1.2367, 2), 1.24);
      expect(roundTo(1.2345, 1), 1.2);
    });

    test('defaults to two decimal places', () {
      expect(roundTo(3.14159), 3.14);
    });
  });
}
