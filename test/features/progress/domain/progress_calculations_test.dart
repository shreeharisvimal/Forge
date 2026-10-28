// Unit tests for the progress analytics calculations.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/data/pr_event.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/features/progress/domain/analytics_range.dart';
import 'package:forge/features/progress/domain/progress_calculations.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';

void main() {
  final now = DateTime(2026, 2, 4, 9); // Wednesday

  WorkoutSession session({
    required DateTime date,
    List<({String id, String name, int sets, int reps, double weight})>
        exercises = const [
          (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
        ],
    int minutes = 0,
  }) {
    return WorkoutSession(
      id: 'sess-${date.millisecondsSinceEpoch}',
      date: date,
      durationMinutes: minutes,
      exercises: [
        for (final exercise in exercises)
          WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: [
              for (var i = 0; i < exercise.sets; i++)
                WorkoutSet(
                  weight: exercise.weight,
                  reps: exercise.reps,
                  completed: true,
                ),
            ],
          ),
      ],
    );
  }

  WorkoutSession emptySession(DateTime date) => WorkoutSession(
        id: 'empty-${date.millisecondsSinceEpoch}',
        date: date,
        exercises: [
          WorkoutExercise(
            exerciseId: 'ex-bench',
            exerciseName: 'Bench Press',
            sets: [WorkoutSet(weight: 100, reps: 10, completed: false)],
          ),
        ],
      );

  WeightEntry weighIn(DateTime date, double weight) =>
      WeightEntry(date: date, weight: weight);

  Exercise exercise({String id = 'ex-bench', String name = 'Bench Press'}) =>
      Exercise(
        id: id,
        name: name,
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        isCompound: true,
      );

  PrEvent prEvent(DateTime date, {String exerciseId = 'ex-bench'}) => PrEvent(
        exerciseId: exerciseId,
        exerciseName: 'Bench Press',
        type: PrType.heaviestWeight.name,
        value: 120,
        date: date,
      );

  PersonalRecord record(String exerciseId, double estimatedOneRM) =>
      PersonalRecord(
        exerciseId: exerciseId,
        estimatedOneRM: estimatedOneRM,
      );

  group('overview', () {
    test('aggregates sessions within the window only', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 3)),
          session(date: DateTime(2026, 2, 1)),
          session(date: DateTime(2026, 1, 25)), // outside 7D
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.workouts, 2);
      expect(snapshot.overview.sets, 2);
      expect(snapshot.overview.reps, 20);
      expect(snapshot.overview.volume, 2000);
      expect(snapshot.overview.activeDays, 2);
      expect(snapshot.overview.hasData, isTrue);
      expect(snapshot.hasSessions, isTrue);
    });

    test('skips sessions without completed sets', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [emptySession(DateTime(2026, 2, 3))],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.workouts, 0);
      expect(snapshot.overview.hasData, isFalse);
    });

    test('computes previous-period deltas', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 4), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 2, reps: 10, weight: 100),
          ]),
          session(date: DateTime(2026, 1, 25), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
          ]),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      final overview = snapshot.overview;
      expect(overview.prevWorkouts, 1);
      expect(overview.prevSets, 1);
      expect(overview.prevVolume, 1000);
      expect(overview.workoutsDelta, closeTo(0.0, 1e-9));
      expect(overview.setsDelta, closeTo(1.0, 1e-9));
      expect(overview.volumeDelta, closeTo(1.0, 1e-9));
      expect(overview.repsDelta, closeTo(1.0, 1e-9));
    });

    test('lifetime windows never produce previous deltas', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2025, 1, 1)),
          session(date: DateTime(2026, 2, 1)),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.workouts, 2);
      expect(snapshot.overview.prevWorkouts, 0);
      expect(snapshot.overview.workoutsDelta, isNull);
    });
  });

  group('streak', () {
    test('counts back from today and tolerates a rest day', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 4)),
          session(date: DateTime(2026, 2, 3)),
          session(date: DateTime(2026, 2, 2)),
          session(date: DateTime(2026, 1, 31)),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.streak, 3);
    });

    test('breaks at the first missing day', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 4)),
          session(date: DateTime(2026, 2, 2)),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.streak, 1);
    });
  });

  group('volume buckets', () {
    test('buckets daily in the 7D window with zero-filled gaps', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 4), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
          ]),
          session(date: DateTime(2026, 2, 2)),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.volumeBuckets.length, 7);
      expect(snapshot.volumeBuckets.first.start, DateTime(2026, 1, 29));
      expect(snapshot.volumeBuckets.first.volume, 0);
      expect(snapshot.volumeBuckets.last.volume, 1000);
    });

    test('buckets monthly for lifetime windows', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2025, 12, 20)),
          session(date: DateTime(2026, 1, 5)),
          session(date: DateTime(2026, 2, 2)),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.volumeBuckets.length, 3);
      expect(snapshot.volumeBuckets.first.label, 'Dec');
      expect(snapshot.volumeBuckets.last.label, 'Feb');
      expect(snapshot.volumeBuckets.first.volume, 1000);
    });

    test('caps the bucket list at 60, keeping the most recent', () {
      final sessions = [
        for (var month = 0; month < 72; month++)
          session(date: DateTime(2020, 2, 1).add(Duration(days: 30 * month))),
      ];
      final snapshot = ProgressCalculations.compute(
        sessions: sessions,
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.volumeBuckets.length, 60);
      expect(snapshot.volumeBuckets.first.start, DateTime(2021, 3, 1));
      expect(snapshot.volumeBuckets.last.start, DateTime(2026, 2, 1));
    });
  });

  group('frequency heatmap', () {
    test('builds week rows from the Monday before the window', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 3)), // Tuesday
          session(date: DateTime(2026, 1, 29)), // Thursday
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.heatmap.weeks.length, 2);
      expect(snapshot.heatmap.totalWorkouts, 2);
      final allDays = snapshot.heatmap.weeks.expand((week) => week);
      final trained = allDays.where((day) => day?.trained ?? false).toList();
      expect(trained.length, 2);
      expect(snapshot.heatmap.maxSets, 1);
    });

    test('reports zero intensity without training', () {
      final snapshot = ProgressCalculations.compute(
        sessions: const [],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.heatmap.totalWorkouts, 0);
      expect(snapshot.heatmap.maxSets, 0);
    });
  });

  group('weight trend', () {
    test('filters and orders weigh-ins within the window', () {
      final snapshot = ProgressCalculations.compute(
        sessions: const [],
        now: now,
        range: AnalyticsRange.last30Days,
        weightEntries: [
          weighIn(DateTime(2026, 1, 20), 80),
          weighIn(DateTime(2026, 1, 10), 81),
          weighIn(DateTime(2025, 12, 1), 82), // outside window
          weighIn(DateTime(2026, 2, 4), 79),
        ],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      final weight = snapshot.weight;
      expect(weight.points.length, 3);
      expect(weight.points.first.weight, 81);
      expect(weight.latest, 79);
      expect(weight.delta, closeTo(-2.0, 1e-9));
      expect(weight.min, 79);
      expect(weight.max, 81);
      expect(weight.average, closeTo(80.0, 1e-9));
      expect(weight.hasData, isTrue);
    });

    test('handles an empty weigh-in history', () {
      final snapshot = ProgressCalculations.compute(
        sessions: const [],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.weight.points, isEmpty);
      expect(snapshot.weight.hasData, isFalse);
      expect(snapshot.hasData, isFalse);
    });
  });

  group('exercise analytics', () {
    test('ranks rows by volume and counts sessions once per day', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 3), exercises: const [
            (id: 'ex-squat', name: 'Squat', sets: 2, reps: 5, weight: 100),
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
          ]),
          session(date: DateTime(2026, 2, 1), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
          ]),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {
          'ex-squat': exercise(id: 'ex-squat', name: 'Squat'),
          'ex-bench': exercise(),
        },
      );

      expect(snapshot.exercises.length, 2);
      expect(snapshot.exercises.first.exerciseId, 'ex-bench');
      expect(snapshot.exercises.first.sessions, 2);
      expect(snapshot.exercises.first.sets, 2);
      expect(snapshot.exercises.first.volume, 2000);
      expect(snapshot.exercises.first.volumePerSession, 1000);
      expect(snapshot.exercises.first.muscleGroup, 'Chest');
      expect(snapshot.exercises.last.exerciseId, 'ex-squat');
    });

    test('counts PRs per exercise from the window events', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [session(date: DateTime(2026, 2, 3))],
        now: now,
        range: AnalyticsRange.last30Days,
        weightEntries: const [],
        prEvents: [
          prEvent(DateTime(2026, 1, 20)),
          prEvent(DateTime(2026, 2, 1)),
          prEvent(DateTime(2025, 12, 1)), // outside window
        ],
        records: const [],
        exercisesById: {},
      );

      expect(snapshot.overview.prs, 2);
      expect(snapshot.exercises.first.prs, 2);
      expect(snapshot.prEvents.length, 2);
    });
  });

  group('strength', () {
    test('sums records and keeps the best one-rep max', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [session(date: DateTime(2026, 2, 3))],
        now: now,
        range: AnalyticsRange.lifetime,
        weightEntries: const [],
        prEvents: const [],
        records: [
          record('ex-bench', 100),
          record('ex-squat', 150),
        ],
        exercisesById: {},
      );

      expect(snapshot.strength.totalOneRM, closeTo(250, 1e-9));
      expect(snapshot.strength.bestOneRM, closeTo(150, 1e-9));
    });

    test('tracks estimated-1RM trajectory per day using the formula', () {
      final snapshot = ProgressCalculations.compute(
        sessions: [
          session(date: DateTime(2026, 2, 1), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 100),
          ]),
          session(date: DateTime(2026, 2, 3), exercises: const [
            (id: 'ex-bench', name: 'Bench Press', sets: 1, reps: 10, weight: 110),
          ]),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        weightEntries: const [],
        prEvents: const [],
        records: const [],
        exercisesById: {},
      );

      final row = snapshot.exercises.first;
      expect(row.estOneRMStart, closeTo(100 * (1 + 10 / 30), 1e-9));
      expect(row.estOneRMEnd, closeTo(110 * (1 + 10 / 30), 1e-9));
      expect(row.estOneRMDelta, closeTo(10 * (1 + 10 / 30), 1e-9));
      expect(row.estimatedOneRM, closeTo(row.estOneRMEnd, 1e-9));

      final trajectory = snapshot.strength.trajectories.first;
      expect(trajectory.points.length, 2);
      expect(trajectory.points.first.value, lessThan(trajectory.points.last.value));
    });
  });
}
