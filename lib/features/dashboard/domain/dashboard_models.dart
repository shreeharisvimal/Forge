// Dashboard domain models for the Forge application.
//
// Plain, immutable value types produced by the dashboard domain services
// and consumed by the Riverpod providers. Kept free of Flutter imports so
// the logic stays unit-testable without a widget tree.
library;

import '../../../models/personal_record.dart';
import '../../../models/workout_split_day.dart';
import '../../../models/workout_split_exercise.dart';

/// The six muscle buckets shown in the recovery panel.
enum RecoveryGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  arms('Arms'),
  legs('Legs'),
  core('Core');

  const RecoveryGroup(this.label);

  /// Display label of the muscle bucket.
  final String label;
}

/// Recovery status for a single [RecoveryGroup].
class MuscleRecovery {
  /// Creates a recovery reading.
  const MuscleRecovery({
    required this.group,
    required this.percent,
    this.lastTrained,
  });

  /// The muscle bucket.
  final RecoveryGroup group;

  /// How recovered the muscle is, 0.0 (just trained) to 1.0 (fully rested).
  final double percent;

  /// When the bucket was last trained, or null if never trained.
  final DateTime? lastTrained;
}

/// Aggregates for the weekly summary panel.
class WeeklySummaryData {
  /// Creates weekly summary data.
  const WeeklySummaryData({
    required this.streak,
    required this.workouts,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.minutes,
  });

  /// Consecutive days with at least one logged session, ending today (or
  /// yesterday when today is still empty).
  final int streak;

  /// Number of sessions performed this week (Monday..today).
  final int workouts;

  /// Number of completed sets this week.
  final int sets;

  /// Number of repetitions completed this week.
  final int reps;

  /// Total training volume (weight x reps) this week.
  final double volume;

  /// Total training minutes this week.
  final int minutes;

  /// Whether any training happened this week.
  bool get hasData => workouts > 0;
}

/// A personal record shown on the dashboard, with the previous best.
class RecentPrEntry {
  /// Creates a dashboard PR row.
  const RecentPrEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.estimatedOneRM,
    this.bestWeight,
    this.bestReps,
    this.previous,
    required this.date,
  });

  /// The exercise this record belongs to.
  final String exerciseId;

  /// Display name of the exercise.
  final String exerciseName;

  /// Current estimated one-rep max (Epley).
  final double estimatedOneRM;

  /// Heaviest recorded weight for the exercise.
  final double? bestWeight;

  /// Best recorded rep count for the exercise.
  final int? bestReps;

  /// Best estimated one-rep max before the current record, or null.
  final double? previous;

  /// When the record was last updated.
  final DateTime date;

  /// The improvement over [previous], or null when there is no baseline.
  double? get improvement {
    final baseline = previous;
    if (baseline == null) return null;
    return estimatedOneRM - baseline;
  }
}

/// The day selected by the active split's weekly cycle.
class SplitDaySnapshot {
  /// Creates a split day snapshot.
  const SplitDaySnapshot({
    required this.date,
    required this.day,
    this.isToday = false,
  });

  /// The calendar date this day maps to.
  final DateTime date;

  /// The split day for that date (may be a rest day).
  final WorkoutSplitDay day;

  /// Whether this snapshot represents today.
  final bool isToday;
}

/// A row for the recent activity feed.
class ActivityItem {
  /// Creates an activity row.
  const ActivityItem({
    required this.kind,
    required this.title,
    this.subtitle,
    required this.date,
  });

  /// The category of the activity.
  final ActivityKind kind;

  /// Headline text.
  final String title;

  /// Supporting detail.
  final String? subtitle;

  /// When the activity happened.
  final DateTime date;
}

/// Categories of entries in the recent activity feed.
enum ActivityKind { workout, weight, measurement, record }

/// A weight trend point for the mini chart.
class WeightPoint {
  /// Creates a weight trend point.
  const WeightPoint({required this.date, required this.weight});

  /// The weigh-in date.
  final DateTime date;

  /// The recorded weight.
  final double weight;
}

/// All data the current-weight panel needs.
class DashboardWeightData {
  /// Creates weight panel data.
  const DashboardWeightData({
    required this.latest,
    required this.delta,
    required this.trend,
    required this.goal,
    required this.unit,
  });

  /// Most recent weigh-in, or null when none exists.
  final double? latest;

  /// Change versus the previous weigh-in, or null.
  final double? delta;

  /// Last 14 days of weigh-ins, oldest first.
  final List<WeightPoint> trend;

  /// The user's target body weight, or null.
  final double? goal;

  /// Weight unit label ("kg" / "lb").
  final String unit;

  /// Whether the weight panel has any data to render.
  bool get hasData => latest != null;

  /// Whether a goal is set and the latest reading is below it.
  bool get hasGoal => goal != null;
}

/// A single motivational quote.
class DashboardQuote {
  /// Creates a quote.
  const DashboardQuote(this.text, this.author);

  /// The quote body.
  final String text;

  /// Attributed speaker/source.
  final String author;
}

/// Convenience view over a [PersonalRecord] plus its history-derived
/// baseline, used to compute previous bests.
class PersonalRecordWithHistory {
  /// Creates the view.
  const PersonalRecordWithHistory({
    required this.record,
    this.previous,
    this.exerciseName = '',
  });

  /// The stored record.
  final PersonalRecord record;

  /// Best estimated one-rep max before the record's update, or null.
  final double? previous;

  /// Display name of the exercise.
  final String exerciseName;
}

/// A snapshot of a split training day's exercise plan.
class SplitDayPlan {
  /// Creates a plan snapshot.
  const SplitDayPlan({
    required this.dayName,
    required this.focus,
    required this.exercises,
    required this.isRestDay,
  });

  /// The day's name, e.g. "Push".
  final String dayName;

  /// Optional focus description.
  final String focus;

  /// The assigned exercises.
  final List<WorkoutSplitExercise> exercises;

  /// Whether this is a rest/recovery day.
  final bool isRestDay;
}

/// Everything the "today's workout" panel needs to render.
class TodayWorkoutData {
  /// Creates today's workout data.
  const TodayWorkoutData({
    required this.hasSplit,
    required this.splitName,
    required this.splitColor,
    required this.today,
    required this.loggedToday,
    this.estimatedMinutes = 0,
    this.muscleGroups = const [],
    this.recoveryPercent,
    this.recordCount = 0,
  });

  /// Whether an active split drives the schedule.
  final bool hasSplit;

  /// Name of the active split.
  final String? splitName;

  /// Accent color (ARGB) of the active split.
  final int splitColor;

  /// The split day scheduled for today (rest day or training day).
  final SplitDaySnapshot? today;

  /// Whether a completed session was already logged today.
  final bool loggedToday;

  /// Estimated session length in minutes, derived from the day's sets and
  /// rest periods.
  final int estimatedMinutes;

  /// Friendly labels of the muscle buckets today's plan targets.
  final List<String> muscleGroups;

  /// Average recovery (0.0–1.0) of the targeted muscles, or null when the
  /// plan targets no strength buckets.
  final double? recoveryPercent;

  /// How many of today's exercises already have a lifetime record (prime
  /// PR-hunting targets).
  final int recordCount;

  /// True when [today] is a rest day.
  bool get isRestDay => today?.day.isRestDay ?? false;
}
