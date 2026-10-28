// Unit tests for the progress providers.
//
// Seeds a real Hive store with a rich history and verifies the snapshot
// composition, the range resizing, the goal provider and the achievement
// engine wiring.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/body/domain/body_measurement_fields.dart';
import 'package:forge/features/prs/providers/pr_providers.dart';
import 'package:forge/features/progress/domain/achievements.dart';
import 'package:forge/features/progress/domain/analytics_range.dart';
import 'package:forge/features/progress/providers/progress_providers.dart';
import 'package:forge/services/providers.dart';

import '../../helpers/hive_test_env.dart';
import 'progress_test_data.dart';

void main() {
  group('with seeded history', () {
    late HiveTestEnv env;

    setUp(() async {
      env = await HiveTestEnv.create();
      await seedProgressData(env.databaseService);
    });

    tearDown(() async {
      await env.dispose();
    });

    ProviderContainer container({
      AnalyticsRange range = AnalyticsRange.last90Days,
    }) {
      final providerContainer = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(env.databaseService),
          progressNowProvider.overrideWithValue(pinnedProgressNow),
          prNowProvider.overrideWithValue(pinnedProgressNow),
        ],
      );
      providerContainer.read(progressRangeProvider.notifier).state = range;
      addTearDown(providerContainer.dispose);
      return providerContainer;
    }

    test('snapshot aggregates the 90-day window', () {
      final snapshot = container().read(progressSnapshotProvider);

      expect(snapshot.range, AnalyticsRange.last90Days);
      expect(snapshot.overview.workouts, 6);
      expect(snapshot.overview.prs, 3);
      expect(snapshot.overview.hasData, isTrue);
      expect(snapshot.hasSessions, isTrue);
      expect(snapshot.prEvents.length, 3);
      expect(snapshot.exercises.isNotEmpty, isTrue);
      expect(snapshot.volumeBuckets.isNotEmpty, isTrue);
      expect(snapshot.heatmap.weeks.isNotEmpty, isTrue);
      expect(snapshot.weight.hasData, isTrue);
      expect(snapshot.weight.latest, 82.5);
    });

    test('previous-period deltas use the equal-length window before it', () {
      final snapshot = container().read(progressSnapshotProvider);

      // The 90-day window starts 2025-11-07; the previous window holds the
      // single 2025-10-15 session.
      expect(snapshot.overview.prevWorkouts, 1);
      expect(snapshot.overview.prevSets, 1);
      expect(snapshot.overview.workoutsDelta, closeTo(5.0, 0.001));
    });

    test('changing the range rescopes the snapshot', () {
      final providerContainer = container();

      providerContainer.read(progressRangeProvider.notifier).state =
          AnalyticsRange.last7Days;
      final snapshot = providerContainer.read(progressSnapshotProvider);

      expect(snapshot.overview.workouts, 2);
      expect(snapshot.prEvents, isEmpty);
      expect(snapshot.weight.hasData, isTrue);
    });

    test('lifetime snapshot spans the whole history', () {
      final snapshot = container().read(progressLifetimeSnapshotProvider);

      expect(snapshot.overview.workouts, 7);
      expect(snapshot.overview.prs, 3);
    });

    test('goal weight provider reads the weight goal', () {
      final goal = container().read(progressGoalWeightProvider);

      expect(goal, isNotNull);
      expect(goal!.field, BodyField.weight);
      expect(goal.target, 80);
    });

    test('achievements evaluate against lifetime data', () {
      final states = container().read(progressAchievementsProvider);
      AchievementState stateOf(String id) =>
          states.firstWhere((state) => state.achievement.id == id);

      expect(stateOf('first_workout').status, AchievementStatus.unlocked);
      expect(stateOf('ten_workouts').status, AchievementStatus.inProgress);
      expect(stateOf('first_record').status, AchievementStatus.unlocked);
      expect(stateOf('weight_entries_10').status, AchievementStatus.inProgress);
      expect(stateOf('score_70').progress, inInclusiveRange(0.0, 1.0));
    });
  });

  group('fresh install', () {
    late HiveTestEnv env;

    setUp(() async {
      env = await HiveTestEnv.create();
    });

    tearDown(() async {
      await env.dispose();
    });

    test('snapshot stays empty without any history', () {
      final providerContainer = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(env.databaseService),
          progressNowProvider.overrideWithValue(pinnedProgressNow),
        ],
      );
      addTearDown(providerContainer.dispose);

      final snapshot = providerContainer.read(progressSnapshotProvider);
      expect(snapshot.hasData, isFalse);
      expect(snapshot.hasSessions, isFalse);
    });
  });
}
