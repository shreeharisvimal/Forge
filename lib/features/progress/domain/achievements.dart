// Achievements for the Forge application.
//
// Deterministic milestones computed from the analytics snapshot, the
// composite strength score and the weigh-in history. Pure Dart — no Flutter
// or Riverpod imports, so the engine is fully unit-testable.
library;

import 'analytics_models.dart';

/// The progress of an achievement toward its goal.
enum AchievementStatus {
  /// The milestone is fully reached.
  unlocked,

  /// The milestone is reachable and partially progressed.
  inProgress,

  /// No data has been recorded toward it yet.
  locked,
}

/// A single achievement definition.
class Achievement {
  /// Creates an achievement.
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
  });

  /// Stable identifier.
  final String id;

  /// Short display title.
  final String title;

  /// The supporting description.
  final String description;

  /// Icon key resolved by the presentation layer.
  final String iconName;
}

/// The evaluated state of one achievement.
class AchievementState {
  /// Creates an achievement state.
  const AchievementState({
    required this.achievement,
    required this.status,
    required this.progress,
    required this.current,
    required this.target,
  });

  /// The achievement definition.
  final Achievement achievement;

  /// How far the milestone has been reached.
  final AchievementStatus status;

  /// 0..1 progress toward the target.
  final double progress;

  /// The current measured value.
  final double current;

  /// The value required to unlock.
  final double target;
}

/// The catalog of achievements.
abstract final class Achievements {
  Achievements._();

  /// Every achievement in display order.
  static const List<Achievement> all = [
    Achievement(
      id: 'first_workout',
      title: 'First workout',
      description: 'Log your very first session.',
      iconName: 'fitness',
    ),
    Achievement(
      id: 'consistent_week',
      title: 'Consistent week',
      description: 'Train seven days in a row.',
      iconName: 'local_fire_department',
    ),
    Achievement(
      id: 'iron_month',
      title: 'Iron month',
      description: 'Keep a 30-day training streak.',
      iconName: 'whatshot',
    ),
    Achievement(
      id: 'ten_workouts',
      title: 'Getting going',
      description: 'Complete ten workouts.',
      iconName: 'fitness_center',
    ),
    Achievement(
      id: 'fifty_workouts',
      title: 'Fifty strong',
      description: 'Complete fifty workouts.',
      iconName: 'military_tech',
    ),
    Achievement(
      id: 'hundred_workouts',
      title: 'Century club',
      description: 'Complete one hundred workouts.',
      iconName: 'emoji_events',
    ),
    Achievement(
      id: 'volume_tons',
      title: 'A ton of work',
      description: 'Move 1,000 kg of total volume.',
      iconName: 'layers',
    ),
    Achievement(
      id: 'volume_truckload',
      title: 'Truckload',
      description: 'Move 10,000 kg of total volume.',
      iconName: 'local_shipping',
    ),
    Achievement(
      id: 'volume_heavy',
      title: 'Heavy hitter',
      description: 'Move 50,000 kg of total volume.',
      iconName: 'iron',
    ),
    Achievement(
      id: 'five_hundred_sets',
      title: 'Set collector',
      description: 'Complete 500 sets.',
      iconName: 'format_list_numbered',
    ),
    Achievement(
      id: 'two_thousand_sets',
      title: 'Set master',
      description: 'Complete 2,000 sets.',
      iconName: 'flag',
    ),
    Achievement(
      id: 'first_record',
      title: 'Record breaker',
      description: 'Set your first personal record.',
      iconName: 'bolt',
    ),
    Achievement(
      id: 'ten_records',
      title: 'Record machine',
      description: 'Set ten personal records.',
      iconName: 'emoji_events',
    ),
    Achievement(
      id: 'score_70',
      title: 'Peak form',
      description: 'Reach a strength score of 70.',
      iconName: 'trending_up',
    ),
    Achievement(
      id: 'bodyweight_ratio',
      title: 'Bodyweight elite',
      description: 'Lift 1.5x your body weight for 1RM.',
      iconName: 'accessibility_new',
    ),
    Achievement(
      id: 'weight_entries_10',
      title: 'In the loop',
      description: 'Log ten weigh-ins.',
      iconName: 'monitor_weight',
    ),
  ];
}

/// Computes achievement states from the analytics snapshot.
abstract final class AchievementEngine {
  AchievementEngine._();

  /// Evaluates every achievement against [snapshot] (use the lifetime
  /// range), the composite [score], the [bodyweightRatio] (best 1RM divided
  /// by the latest body weight) and the weigh-in [weighInCount].
  static List<AchievementState> evaluate({
    required AnalyticsSnapshot snapshot,
    required double score,
    required double bodyweightRatio,
    required int weighInCount,
  }) {
    final overview = snapshot.overview;

    return [
      _count(
        id: 'first_workout',
        value: overview.workouts.toDouble(),
        target: 1,
      ),
      _count(id: 'consistent_week', value: overview.streak.toDouble(), target: 7),
      _count(id: 'iron_month', value: overview.streak.toDouble(), target: 30),
      _count(id: 'ten_workouts', value: overview.workouts.toDouble(), target: 10),
      _count(
        id: 'fifty_workouts',
        value: overview.workouts.toDouble(),
        target: 50,
      ),
      _count(
        id: 'hundred_workouts',
        value: overview.workouts.toDouble(),
        target: 100,
      ),
      _count(
        id: 'volume_tons',
        value: overview.volume,
        target: 1000,
      ),
      _count(
        id: 'volume_truckload',
        value: overview.volume,
        target: 10000,
      ),
      _count(id: 'volume_heavy', value: overview.volume, target: 50000),
      _count(id: 'five_hundred_sets', value: overview.sets.toDouble(), target: 500),
      _count(
        id: 'two_thousand_sets',
        value: overview.sets.toDouble(),
        target: 2000,
      ),
      _count(id: 'first_record', value: overview.prs.toDouble(), target: 1),
      _count(id: 'ten_records', value: overview.prs.toDouble(), target: 10),
      _count(id: 'score_70', value: score, target: 70),
      _count(
        id: 'bodyweight_ratio',
        value: bodyweightRatio,
        target: 1.5,
      ),
      _count(
        id: 'weight_entries_10',
        value: weighInCount.toDouble(),
        target: 10,
      ),
    ];
  }

  static AchievementState _count({
    required String id,
    required double value,
    required double target,
  }) {
    final achievement = Achievements.all.firstWhere((entry) => entry.id == id);
    final progress = value >= target ? 1.0 : (target <= 0 ? 0.0 : value / target);
    final status = value >= target
        ? AchievementStatus.unlocked
        : value > 0
            ? AchievementStatus.inProgress
            : AchievementStatus.locked;
    return AchievementState(
      achievement: achievement,
      status: status,
      progress: progress,
      current: value,
      target: target,
    );
  }
}
