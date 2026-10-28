// Session statistics and estimation for the Forge application.
//
// Pure functions only — no Flutter or Riverpod imports. Volume, rep counts,
// estimated one-rep max (Epley), a simple MET-based calorie estimate, and
// milestone achievements derived from a finished session.
library;

import 'session_models.dart';

/// Immutable aggregate of the numbers shown during and after a workout.
class SessionStats {
  /// Creates session stats.
  const SessionStats({
    required this.exercises,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.durationSeconds,
    required this.averageRpe,
    required this.calories,
    required this.bestWeight,
  });

  /// Number of exercises in the session.
  final int exercises;

  /// Number of completed sets.
  final int sets;

  /// Number of repetitions in completed sets.
  final int reps;

  /// Total volume (kg) of completed sets.
  final double volume;

  /// Session duration in seconds.
  final int durationSeconds;

  /// Weighted average RPE, or null when none recorded.
  final double? averageRpe;

  /// Estimated calories burned, or 0 when unknown.
  final int calories;

  /// Heaviest single completed lift in kg, or 0.
  final double bestWeight;
}

/// Session math: stats, one-rep max, calorie estimation and achievements.
abstract final class SessionCalculations {
  SessionCalculations._();

  /// Computes aggregate stats using an explicit clock and body weight.
  static SessionStats statsFor(
    ActiveSession session, {
    required DateTime now,
    double bodyWeightKg = 0,
  }) {
    var sets = 0;
    var reps = 0;
    var volume = 0.0;
    var bestWeight = 0.0;
    var rpeSum = 0.0;
    var rpeCount = 0;
    for (final exercise in session.content.exercises) {
      for (final set in exercise.sets) {
        if (!set.completed) continue;
        sets++;
        reps += set.reps;
        volume += set.weight * set.reps;
        if (set.weight > bestWeight) bestWeight = set.weight;
        final rpe = set.rpe;
        if (rpe != null) {
          rpeSum += rpe;
          rpeCount++;
        }
      }
    }
    final durationSeconds = session.elapsedMsAt(now) ~/ 1000;
    return SessionStats(
      exercises: session.content.exercises.length,
      sets: sets,
      reps: reps,
      volume: volume,
      durationSeconds: durationSeconds,
      averageRpe: rpeCount == 0 ? null : rpeSum / rpeCount,
      calories: estimateCalories(
        totalVolumeKg: volume,
        durationSeconds: durationSeconds,
        bodyWeightKg: bodyWeightKg,
      ),
      bestWeight: bestWeight,
    );
  }

  /// Estimated one-rep max using the Epley formula.
  static double oneRepMax(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return weight * (1 + reps / 30);
  }

  /// Best estimated one-rep max across a session's completed sets.
  static double bestOneRepMax(ActiveSession session) {
    var best = 0.0;
    for (final exercise in session.content.exercises) {
      for (final set in exercise.sets) {
        if (!set.completed) continue;
        final estimate = oneRepMax(set.weight, set.reps);
        if (estimate > best) best = estimate;
      }
    }
    return best;
  }

  /// Simple MET-based calorie estimate for a strength session.
  ///
  /// Intensity (MET) scales with how much load was moved per hour, then the
  /// standard MET formula (kcal = MET x weight x hours x 1.05) is applied.
  /// Returns 0 when there is nothing to estimate.
  static int estimateCalories({
    required double totalVolumeKg,
    required int durationSeconds,
    required double bodyWeightKg,
  }) {
    if (durationSeconds <= 0 || totalVolumeKg <= 0 || bodyWeightKg <= 0) {
      return 0;
    }
    final hours = durationSeconds / 3600;
    final volumePerHour = totalVolumeKg / hours;
    final met = 3.0 + 3.0 * (volumePerHour / 20000).clamp(0.0, 1.0);
    return (met * bodyWeightKg * hours * 1.05).round();
  }

  /// Evaluates which achievements a session has unlocked.
  static List<SessionAchievement> achievements({
    required SessionStats stats,
    double bodyWeightKg = 0,
  }) {
    final earned = <SessionAchievement>[];
    void add(SessionAchievement achievement) => earned.add(achievement);

    if (stats.sets >= 1) {
      add(const SessionAchievement(
        id: SessionAchievementId.firstSet,
        title: 'First set in the books',
        subtitle: 'You completed your first set of the session.',
        iconName: 'flag',
      ));
    }
    if (stats.sets >= 5) {
      add(const SessionAchievement(
        id: SessionAchievementId.sets5,
        title: 'Five and flowing',
        subtitle: 'Five completed sets and counting.',
        iconName: 'repeat',
      ));
    }
    if (stats.reps >= 100) {
      add(const SessionAchievement(
        id: SessionAchievementId.century,
        title: 'Century',
        subtitle: 'Over 100 reps in a single session.',
        iconName: 'numbers',
      ));
    }
    if (stats.volume >= 2500) {
      add(const SessionAchievement(
        id: SessionAchievementId.volume2500,
        title: 'Heavy volume',
        subtitle: 'More than 2.5 tons moved this session.',
        iconName: 'scale',
      ));
    }
    if (stats.volume >= 5000) {
      add(const SessionAchievement(
        id: SessionAchievementId.volume5000,
        title: 'Tonne club',
        subtitle: 'Over 5 tons of total volume. Serious work.',
        iconName: 'scale',
      ));
    }
    final rpe = stats.averageRpe;
    if (rpe != null && rpe >= 8) {
      add(const SessionAchievement(
        id: SessionAchievementId.intensity,
        title: 'Push to the edge',
        subtitle: 'Average intensity of RPE 8 or higher.',
        iconName: 'bolt',
      ));
    }
    if (stats.durationSeconds >= 3600) {
      add(const SessionAchievement(
        id: SessionAchievementId.hourPlus,
        title: 'Hour of power',
        subtitle: 'You trained for 60 minutes or more.',
        iconName: 'schedule',
      ));
    }
    if (stats.exercises >= 5) {
      add(const SessionAchievement(
        id: SessionAchievementId.variety,
        title: 'Jack of all trades',
        subtitle: 'Five or more different exercises.',
        iconName: 'grid_view',
      ));
    }
    if (bodyWeightKg > 0 && stats.bestWeight >= bodyWeightKg * 1.5) {
      add(const SessionAchievement(
        id: SessionAchievementId.heavyLifter,
        title: 'Heavy lifter',
        subtitle: 'Lifted 1.5x your body weight.',
        iconName: 'fitness_center',
      ));
    }
    if (bodyWeightKg > 0 && stats.bestWeight >= bodyWeightKg * 2) {
      add(const SessionAchievement(
        id: SessionAchievementId.bigLifter,
        title: 'Big lifter',
        subtitle: 'Lifted double your body weight.',
        iconName: 'fitness_center',
      ));
    }
    return earned;
  }
}

/// Identifiers of the milestone achievements.
enum SessionAchievementId {
  firstSet,
  sets5,
  century,
  volume2500,
  volume5000,
  intensity,
  hourPlus,
  variety,
  heavyLifter,
  bigLifter,
}

/// A milestone unlocked by a finished session.
class SessionAchievement {
  /// Creates an achievement.
  const SessionAchievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
  });

  /// The achievement's identifier.
  final SessionAchievementId id;

  /// Headline text.
  final String title;

  /// Supporting detail.
  final String subtitle;

  /// Name of the icon to render (resolved by the UI).
  final String iconName;
}
