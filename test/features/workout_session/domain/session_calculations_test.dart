// Domain tests for session statistics and achievements.
//
// Pure math: stats aggregation, Epley one-rep max, MET calorie estimation
// and milestone achievements.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/domain/session_calculations.dart';
import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';

final _now = DateTime(2026, 2, 4, 12, 0);

ActiveSession _sessionWithSets(List<WorkoutSet> sets) {
  final exercise = WorkoutExercise(
    exerciseId: 'e1',
    exerciseName: 'Bench',
    sets: sets,
  );
  return ActiveSession(
    content: WorkoutSession(
      name: 'Test',
      date: _now,
      startedAt: _now,
      exercises: [exercise],
    ),
    ui: const SessionUiState(stage: SessionStage.active),
  );
}

WorkoutSet _done(double weight, int reps, {double? rpe}) => WorkoutSet(
      weight: weight,
      reps: reps,
      rpe: rpe,
      restSeconds: 90,
      completed: true,
    );

void main() {
  group('SessionCalculations.statsFor', () {
    test('aggregates completed sets and volume', () {
      final session = _sessionWithSets([
        _done(80, 5),
        _done(100, 3),
        WorkoutSet(weight: 50, reps: 10),
      ]);
      final stats = SessionCalculations.statsFor(
        session,
        now: _now,
      );
      expect(stats.sets, 2);
      expect(stats.reps, 8);
      expect(stats.volume, 700);
      expect(stats.bestWeight, 100);
      expect(stats.exercises, 1);
    });

    test('averages RPE across completed sets with an RPE', () {
      final session = _sessionWithSets([_done(80, 5, rpe: 8), _done(90, 3, rpe: 9)]);
      final stats = SessionCalculations.statsFor(session, now: _now);
      expect(stats.averageRpe, closeTo(8.5, 0.001));
    });

    test('omits average RPE when no set records one', () {
      final stats = SessionCalculations.statsFor(
        _sessionWithSets([_done(80, 5)]),
        now: _now,
      );
      expect(stats.averageRpe, isNull);
    });

    test('estimates calories only with volume, duration and body weight', () {
      final session = _sessionWithSets([_done(80, 5)]).copyWith(
        content: _sessionWithSets([_done(80, 5)]).content.copyWith(
              startedAt: () => _now,
            ),
        ui: _sessionWithSets([_done(80, 5)]).ui.copyWith(stage: SessionStage.active),
      );
      final stats = SessionCalculations.statsFor(
        session,
        now: _now.add(const Duration(minutes: 60)),
        bodyWeightKg: 80,
      );
      expect(stats.calories, greaterThan(0));
      expect(stats.durationSeconds, 3600);
    });
  });

  group('SessionCalculations.oneRepMax', () {
    test('applies the Epley formula', () {
      expect(SessionCalculations.oneRepMax(100, 10), closeTo(133.33, 0.01));
    });

    test('returns zero for non-positive inputs', () {
      expect(SessionCalculations.oneRepMax(0, 10), 0);
      expect(SessionCalculations.oneRepMax(100, 0), 0);
    });
  });

  group('SessionCalculations.estimateCalories', () {
    test('returns zero when any input is missing', () {
      expect(
        SessionCalculations.estimateCalories(
          totalVolumeKg: 0,
          durationSeconds: 3600,
          bodyWeightKg: 80,
        ),
        0,
      );
      expect(
        SessionCalculations.estimateCalories(
          totalVolumeKg: 5000,
          durationSeconds: 0,
          bodyWeightKg: 80,
        ),
        0,
      );
    });
  });

  group('SessionCalculations.achievements', () {
    test('unlocks the first-set milestone for any completed set', () {
      final stats = SessionCalculations.statsFor(
        _sessionWithSets([_done(80, 5)]),
        now: _now,
      );
      final earned = SessionCalculations.achievements(stats: stats);
      expect(earned.any((a) => a.id == SessionAchievementId.firstSet), isTrue);
      expect(earned.any((a) => a.id == SessionAchievementId.sets5), isFalse);
    });

    test('unlocks volume milestones at 2.5t and 5t', () {
      final heavy = SessionCalculations.statsFor(
        _sessionWithSets([_done(210, 12), _done(210, 12)]),
        now: _now,
      );
      expect(heavy.volume, greaterThanOrEqualTo(5000));
      final earned = SessionCalculations.achievements(stats: heavy);
      expect(earned.any((a) => a.id == SessionAchievementId.volume2500), isTrue);
      expect(earned.any((a) => a.id == SessionAchievementId.volume5000), isTrue);
    });

    test('unlocks the intensity milestone for RPE 8+ averages', () {
      final stats = SessionCalculations.statsFor(
        _sessionWithSets([_done(80, 5, rpe: 8.5)]),
        now: _now,
      );
      final earned = SessionCalculations.achievements(stats: stats);
      expect(earned.any((a) => a.id == SessionAchievementId.intensity), isTrue);
    });

    test('body-weight lifts unlock heavy lifter achievements', () {
      final stats = SessionCalculations.statsFor(
        _sessionWithSets([_done(200, 1)]),
        now: _now,
      );
      final earned = SessionCalculations.achievements(
        stats: stats,
        bodyWeightKg: 100,
      );
      expect(earned.any((a) => a.id == SessionAchievementId.heavyLifter), isTrue);
      expect(earned.any((a) => a.id == SessionAchievementId.bigLifter), isTrue);
    });

    test('an empty session unlocks nothing', () {
      final stats = SessionCalculations.statsFor(
        ActiveSession(
          content: WorkoutSession(name: 'E', date: _now, startedAt: _now),
          ui: const SessionUiState(stage: SessionStage.active),
        ),
        now: _now,
      );
      expect(SessionCalculations.achievements(stats: stats), isEmpty);
    });
  });
}
