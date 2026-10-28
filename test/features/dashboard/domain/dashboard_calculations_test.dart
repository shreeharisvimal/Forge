// Unit tests for the dashboard calculations.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/utils/dates.dart';
import 'package:forge/features/dashboard/domain/dashboard_calculations.dart';
import 'package:forge/models/exercise_history.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/models/workout_split.dart';
import 'package:forge/models/workout_split_day.dart';
import 'package:forge/models/workout_split_exercise.dart';

void main() {
  final now = DateTime(2026, 2, 4, 12); // Wednesday

  WorkoutSession session({
    required DateTime date,
    int sets = 1,
    int reps = 10,
    double weight = 100,
    int minutes = 0,
    bool completed = true,
  }) {
    return WorkoutSession(
      date: date,
      completed: completed,
      durationMinutes: minutes,
      exercises: [
        WorkoutExercise(
          exerciseId: 'ex-1',
          exerciseName: 'Bench Press',
          sets: [
            for (var i = 0; i < sets; i++)
              WorkoutSet(
                weight: weight,
                reps: reps,
                completed: completed,
              ),
          ],
        ),
      ],
    );
  }

  WorkoutSplitDay day(String name, {bool rest = false}) => WorkoutSplitDay(
        name: name,
        focus: name,
        isRestDay: rest,
        exercises: [
          WorkoutSplitExercise(exerciseId: 'ex-1', exerciseName: 'Bench Press'),
        ],
      );

  group('mondayOf', () {
    test('returns the Monday of the current week', () {
      expect(DashboardCalculations.mondayOf(now),
          DateTime(2026, 2, 2));
    });

    test('returns the same day when it is already a Monday', () {
      expect(DashboardCalculations.mondayOf(DateTime(2026, 2, 2)),
          DateTime(2026, 2, 2));
    });
  });

  group('dayIndex', () {
    final createdAt = DateTime(2026, 2, 2); // Monday

    test('anchors to the Monday of the creation week', () {
      expect(
        DashboardCalculations.dayIndex(
          date: DateTime(2026, 2, 2),
          splitCreatedAt: createdAt,
          dayCount: 7,
        ),
        0,
      );
      expect(
        DashboardCalculations.dayIndex(
          date: DateTime(2026, 2, 4),
          splitCreatedAt: createdAt,
          dayCount: 7,
        ),
        2,
      );
    });

    test('the same weekday always maps to the same index', () {
      final indexA = DashboardCalculations.dayIndex(
        date: DateTime(2026, 2, 4),
        splitCreatedAt: createdAt,
        dayCount: 7,
      );
      final indexB = DashboardCalculations.dayIndex(
        date: DateTime(2026, 2, 11),
        splitCreatedAt: createdAt,
        dayCount: 7,
      );
      expect(indexA, indexB);
    });

    test('returns 0 for an empty day list', () {
      expect(
        DashboardCalculations.dayIndex(
          date: now,
          splitCreatedAt: createdAt,
          dayCount: 0,
        ),
        0,
      );
    });
  });

  group('WeeklySplitSchedule.snapshotFor', () {
    test('maps dates onto the split day list', () {
      final schedule = WeeklySplitSchedule(
        split: WorkoutSplit(
          name: 'PPL',
          createdAt: DateTime(2026, 2, 2),
          days: [
            day('Push'),
            day('Pull'),
            day('Legs'),
            day('Rest', rest: true),
          ],
        ),
        days: [
          day('Push'),
          day('Pull'),
          day('Legs'),
          day('Rest', rest: true),
        ],
        createdAt: DateTime(2026, 2, 2),
      );

      final wednesday = schedule.snapshotFor(DateTime(2026, 2, 4));
      expect(wednesday.day.name, 'Legs');
      expect(wednesday.isToday, isTrue);
    });
  });

  group('nextTrainingDay', () {
    final days = [
      day('Push'),
      day('Pull'),
      day('Legs'),
      day('Rest', rest: true),
      day('Rest', rest: true),
      day('Rest', rest: true),
      day('Rest', rest: true),
    ];

    test('skips rest days until the next training day', () {
      final next = DashboardCalculations.nextTrainingDay(
        days: days,
        splitCreatedAt: DateTime(2026, 2, 2),
        from: DateTime(2026, 2, 4), // Wednesday -> Legs
      );
      expect(next, isNotNull);
      expect(next!.day.name, 'Push');
      expect(next.date, DateTime(2026, 2, 9)); // next Monday
    });

    test('returns null when every day is rest', () {
      final allRest = [day('R1', rest: true), day('R2', rest: true)];
      expect(
        DashboardCalculations.nextTrainingDay(
          days: allRest,
          splitCreatedAt: DateTime(2026, 2, 2),
          from: now,
        ),
        isNull,
      );
    });

    test('returns null for an empty split', () {
      expect(
        DashboardCalculations.nextTrainingDay(
          days: const [],
          splitCreatedAt: DateTime(2026, 2, 2),
          from: now,
        ),
        isNull,
      );
    });
  });

  group('weeklySummary', () {
    test('aggregates completed sets and sessions for the week', () {
      final summary = DashboardCalculations.weeklySummary(
        sessions: [
          session(
            date: now,
            sets: 2,
            reps: 8,
            weight: 100,
            minutes: 45,
          ),
          session(
            date: now.subtract(const Duration(days: 1)),
            sets: 3,
            reps: 6,
            weight: 120,
            minutes: 40,
          ),
          session(
            date: DateTime(2026, 1, 26), // previous week
            sets: 1,
            reps: 10,
            weight: 100,
            minutes: 30,
          ),
        ],
        now: now,
      );

      expect(summary.workouts, 2);
      expect(summary.sets, 5);
      expect(summary.reps, 8 * 2 + 6 * 3);
      expect(summary.volume, closeTo(100 * 8 * 2 + 120 * 6 * 3, 0.001));
      expect(summary.minutes, 85);
    });

    test('ignores incomplete sessions entirely', () {
      final summary = DashboardCalculations.weeklySummary(
        sessions: [
          session(date: now, sets: 2, completed: false),
        ],
        now: now,
      );

      expect(summary.workouts, 0);
      expect(summary.sets, 0);
      expect(summary.reps, 0);
      expect(summary.hasData, isFalse);
    });

    test('streak counts consecutive days ending today', () {
      final summary = DashboardCalculations.weeklySummary(
        sessions: [
          session(date: now),
          session(date: now.subtract(const Duration(days: 1))),
        ],
        now: now,
      );

      expect(summary.streak, 2);
    });

    test('streak tolerates an empty today', () {
      final summary = DashboardCalculations.weeklySummary(
        sessions: [
          session(date: now.subtract(const Duration(days: 1))),
        ],
        now: now,
      );

      expect(summary.streak, 1);
    });

    test('streak resets when a day is skipped', () {
      final summary = DashboardCalculations.weeklySummary(
        sessions: [
          session(date: now),
          session(date: now.subtract(const Duration(days: 2))),
        ],
        now: now,
      );

      expect(summary.streak, 1);
    });
  });

  group('previousBest', () {
    test('finds the best estimate strictly before the cutoff day', () {
      final best = DashboardCalculations.previousBest(
        history: [
          ExerciseHistory(
            exerciseId: 'ex-1',
            date: DateTime(2026, 2, 1),
            estimatedOneRM: 100,
          ),
          ExerciseHistory(
            exerciseId: 'ex-1',
            date: DateTime(2026, 2, 2),
            estimatedOneRM: 110,
          ),
          ExerciseHistory(
            exerciseId: 'ex-1',
            date: DateTime(2026, 2, 4),
            estimatedOneRM: 120,
          ),
        ],
        before: DateTime(2026, 2, 3, 12),
      );

      expect(best, 110);
    });

    test('excludes history recorded on the cutoff day', () {
      final best = DashboardCalculations.previousBest(
        history: [
          ExerciseHistory(
            exerciseId: 'ex-1',
            date: DateTime(2026, 2, 3),
            estimatedOneRM: 999,
          ),
        ],
        before: DateTime(2026, 2, 3, 12),
      );

      expect(best, isNull);
    });

    test('returns null when there is no prior history', () {
      final best = DashboardCalculations.previousBest(
        history: const [],
        before: now,
      );

      expect(best, isNull);
    });
  });

  group('date utilities', () {
    test('isSameDay compares calendar days', () {
      expect(
        isSameDay(DateTime(2026, 2, 4, 8), DateTime(2026, 2, 4, 22)),
        isTrue,
      );
      expect(
        isSameDay(DateTime(2026, 2, 4, 8), DateTime(2026, 2, 5, 8)),
        isFalse,
      );
    });
  });
}
