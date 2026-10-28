// Unit tests for the dashboard recovery service.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/constants/exercise_categories.dart';
import 'package:forge/features/dashboard/domain/dashboard_models.dart';
import 'package:forge/features/dashboard/domain/recovery_service.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';

void main() {
  final now = DateTime(2026, 2, 4, 12);

  WorkoutSession session({
    required DateTime date,
    List<String> muscleGroups = const [],
    bool completedSets = true,
  }) {
    return WorkoutSession(
      date: date,
      completed: completedSets,
      exercises: [
        for (final group in muscleGroups)
          WorkoutExercise(
            exerciseId: group,
            exerciseName: group,
            sets: [
              WorkoutSet(
                weight: 50,
                reps: 8,
                completed: completedSets,
              ),
            ],
          ),
      ],
    );
  }

  Iterable<RecoveryGroup> resolve(WorkoutExercise performed) =>
      RecoveryGroupResolver.resolve(performed.exerciseId);

  double percentFor(List<MuscleRecovery> readings, RecoveryGroup group) {
    return readings.firstWhere((reading) => reading.group == group).percent;
  }

  group('RecoveryGroupResolver', () {
    test('maps each canonical muscle group onto a bucket', () {
      expect(RecoveryGroupResolver.resolve(MuscleGroups.chest),
          [RecoveryGroup.chest]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.back),
          [RecoveryGroup.back]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.lowerBack),
          [RecoveryGroup.back]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.sideDelts),
          [RecoveryGroup.shoulders]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.biceps),
          [RecoveryGroup.arms]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.forearms),
          [RecoveryGroup.arms]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.quadriceps),
          [RecoveryGroup.legs]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.calves),
          [RecoveryGroup.legs]);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.abs),
          [RecoveryGroup.core]);
    });

    test('full-body work fatigues every bucket', () {
      expect(
        RecoveryGroupResolver.resolve(MuscleGroups.fullBody),
        RecoveryGroup.values,
      );
    });

    test('cardio and mobility are not attributed to a bucket', () {
      expect(RecoveryGroupResolver.resolve(MuscleGroups.cardio), isEmpty);
      expect(RecoveryGroupResolver.resolve(MuscleGroups.mobility), isEmpty);
    });
  });

  group('RecoveryService.compute', () {
    test('never-trained buckets report fully recovered', () {
      final readings =
          RecoveryService.compute(sessions: [], now: now, resolve: resolve);

      expect(readings, hasLength(RecoveryGroup.values.length));
      for (final reading in readings) {
        expect(reading.percent, 1.0);
        expect(reading.lastTrained, isNull);
      }
    });

    test('training today collapses that bucket to 0', () {
      final readings = RecoveryService.compute(
        sessions: [session(date: now, muscleGroups: [MuscleGroups.chest])],
        now: now,
        resolve: resolve,
      );

      expect(percentFor(readings, RecoveryGroup.chest), 0.0);
      expect(percentFor(readings, RecoveryGroup.back), 1.0);
      expect(readings
          .firstWhere((reading) => reading.group == RecoveryGroup.chest)
          .lastTrained, now);
    });

    test('recovery scales linearly across the rest window', () {
      final readings = RecoveryService.compute(
        sessions: [
          session(
            date: now.subtract(const Duration(hours: 24)),
            muscleGroups: [MuscleGroups.chest],
          ),
        ],
        now: now,
        resolve: resolve,
      );

      expect(percentFor(readings, RecoveryGroup.chest), closeTo(0.5, 0.001));
    });

    test('buckets are fully recovered after their rest window', () {
      final readings = RecoveryService.compute(
        sessions: [
          session(
            date: now.subtract(const Duration(days: 4)),
            muscleGroups: [MuscleGroups.chest, MuscleGroups.back],
          ),
        ],
        now: now,
        resolve: resolve,
      );

      expect(percentFor(readings, RecoveryGroup.chest), 1.0);
      expect(percentFor(readings, RecoveryGroup.back), 1.0);
    });

    test('incomplete sessions do not affect recovery', () {
      final readings = RecoveryService.compute(
        sessions: [
          session(
            date: now,
            muscleGroups: [MuscleGroups.chest],
            completedSets: false,
          ),
        ],
        now: now,
        resolve: resolve,
      );

      for (final reading in readings) {
        expect(reading.percent, 1.0);
        expect(reading.lastTrained, isNull);
      }
    });

    test('the most recent session wins for a bucket', () {
      final readings = RecoveryService.compute(
        sessions: [
          session(
            date: now.subtract(const Duration(hours: 24)),
            muscleGroups: [MuscleGroups.quadriceps],
          ),
          session(date: now, muscleGroups: [MuscleGroups.quadriceps]),
        ],
        now: now,
        resolve: resolve,
      );

      expect(percentFor(readings, RecoveryGroup.legs), 0.0);
    });
  });
}