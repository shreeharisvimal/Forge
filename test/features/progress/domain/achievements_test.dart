// Unit tests for the progress achievements engine.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/progress/domain/achievements.dart';
import 'package:forge/features/progress/domain/analytics_models.dart';
import 'package:forge/features/progress/domain/analytics_range.dart';

AnalyticsSnapshot snapshot({
  int workouts = 0,
  int sets = 0,
  int reps = 0,
  double volume = 0,
  int prs = 0,
  int streak = 0,
  double bestOneRM = 0,
}) {
  return AnalyticsSnapshot(
    range: AnalyticsRange.lifetime,
    now: DateTime(2026, 2, 4),
    overview: OverviewStats(
      range: AnalyticsRange.lifetime,
      workouts: workouts,
      sets: sets,
      reps: reps,
      volume: volume,
      minutes: 0,
      activeDays: workouts,
      prs: prs,
      streak: streak,
      prevWorkouts: 0,
      prevSets: 0,
      prevReps: 0,
      prevVolume: 0,
    ),
    volumeBuckets: const [],
    heatmap: const FrequencyHeatmapData(weeks: [], maxSets: 0, totalWorkouts: 0),
    weight: const WeightTrendData(points: []),
    exercises: const [],
    strength: StrengthTrendData(
      totalOneRM: bestOneRM,
      bestOneRM: bestOneRM,
      trajectories: const [],
    ),
    prEvents: const [],
  );
}

void main() {
  group('evaluate', () {
    test('returns one state per achievement definition', () {
      final states = AchievementEngine.evaluate(
        snapshot: snapshot(),
        score: 0,
        bodyweightRatio: 0,
        weighInCount: 0,
      );

      expect(states.length, Achievements.all.length);
      expect(states.map((state) => state.achievement.id),
          Achievements.all.map((achievement) => achievement.id));
    });

    test('unlocks milestones when the target is reached', () {
      final states = AchievementEngine.evaluate(
        snapshot: snapshot(
          workouts: 100,
          sets: 2000,
          volume: 50000,
          prs: 10,
          streak: 30,
        ),
        score: 70,
        bodyweightRatio: 1.5,
        weighInCount: 10,
      );

      final unlocked = states
          .where((state) => state.status == AchievementStatus.unlocked)
          .map((state) => state.achievement.id)
          .toSet();
      expect(unlocked, containsAll(const [
        'first_workout',
        'consistent_week',
        'iron_month',
        'ten_workouts',
        'fifty_workouts',
        'hundred_workouts',
        'volume_tons',
        'volume_truckload',
        'volume_heavy',
        'five_hundred_sets',
        'two_thousand_sets',
        'first_record',
        'ten_records',
        'score_70',
        'bodyweight_ratio',
        'weight_entries_10',
      ]));
    });

    test('stays locked without any data', () {
      final states = AchievementEngine.evaluate(
        snapshot: snapshot(),
        score: 0,
        bodyweightRatio: 0,
        weighInCount: 0,
      );

      for (final state in states) {
        expect(state.status, AchievementStatus.locked, reason: state.achievement.id);
        expect(state.progress, 0);
      }
    });

    test('reports partial progress and in-progress status', () {
      final states = AchievementEngine.evaluate(
        snapshot: snapshot(workouts: 5, streak: 3),
        score: 0,
        bodyweightRatio: 0,
        weighInCount: 0,
      );

      final firstWorkout =
          states.firstWhere((state) => state.achievement.id == 'first_workout');
      expect(firstWorkout.status, AchievementStatus.unlocked);
      expect(firstWorkout.progress, 1.0);

      final tenWorkouts =
          states.firstWhere((state) => state.achievement.id == 'ten_workouts');
      expect(tenWorkouts.status, AchievementStatus.inProgress);
      expect(tenWorkouts.progress, closeTo(0.5, 1e-9));

      final consistentWeek =
          states.firstWhere((state) => state.achievement.id == 'consistent_week');
      expect(consistentWeek.status, AchievementStatus.inProgress);
      expect(consistentWeek.progress, closeTo(3 / 7, 1e-9));
    });

    test('clamps progress at the target', () {
      final states = AchievementEngine.evaluate(
        snapshot: snapshot(volume: 100000),
        score: 0,
        bodyweightRatio: 0,
        weighInCount: 0,
      );

      final heavy =
          states.firstWhere((state) => state.achievement.id == 'volume_heavy');
      expect(heavy.status, AchievementStatus.unlocked);
      expect(heavy.progress, 1.0);
    });
  });
}
