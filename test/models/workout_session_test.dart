// Unit tests for the WorkoutSession model, including nested serialization
// of WorkoutExercise and WorkoutSet.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';

void main() {
  group('WorkoutSession', () {
    test('defaults to an empty exercise list', () {
      final session = WorkoutSession(date: DateTime(2026, 8, 4));
      expect(session.exercises, isEmpty);
      expect(session.completed, isFalse);
    });

    test('round-trips nested exercises and sets through toMap/fromMap', () {
      final original = WorkoutSession(
        id: 'session-1',
        workoutId: 'workout-1',
        date: DateTime(2026, 8, 4),
        durationMinutes: 70,
        notes: 'Good session',
        exercises: [
          WorkoutExercise(
            id: 'ex-1',
            exerciseId: 'e1',
            exerciseName: 'Back Squat',
            order: 0,
            notes: 'Deep',
            sets: [
              WorkoutSet(
                id: 'set-1',
                weight: 100,
                reps: 5,
                rpe: 8.5,
                restSeconds: 120,
                completed: true,
              ),
              WorkoutSet(id: 'set-2', weight: 110, reps: 3, completed: true),
            ],
          ),
        ],
        completed: true,
        volume: 830,
      );

      final restored = WorkoutSession.fromMap(original.toMap());
      expect(restored, original);
      expect(restored.exercises, hasLength(1));
      expect(restored.exercises.first.sets, hasLength(2));
      expect(restored.exercises.first.sets.last.weight, 110);
    });

    test('copyWith deep-replaces the exercise list', () {
      final original = WorkoutSession(date: DateTime(2026, 8, 4));
      final extra = WorkoutExercise(
        exerciseId: 'e1',
        exerciseName: 'Curl',
        order: 0,
      );
      final updated = original.copyWith(exercises: [extra]);

      expect(updated.exercises, hasLength(1));
      expect(updated.exercises.single.exerciseName, 'Curl');
      expect(original.exercises, isEmpty);
    });
  });
}
