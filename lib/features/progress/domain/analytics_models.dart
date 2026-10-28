// Progress analytics models for the Forge application.
//
// Immutable value types produced by [ProgressCalculations] and consumed by
// the Progress providers and widgets. Kept free of Flutter and Riverpod
// imports so the whole analytics pipeline is unit-testable without a widget
// tree.
library;

import '../../prs/data/pr_event.dart';
import 'analytics_range.dart';

/// Aggregates for the Overview section.
class OverviewStats {
  /// Creates overview stats.
  const OverviewStats({
    required this.range,
    required this.workouts,
    required this.sets,
    required this.reps,
    required this.volume,
    required this.minutes,
    required this.activeDays,
    required this.prs,
    required this.streak,
    required this.prevWorkouts,
    required this.prevSets,
    required this.prevReps,
    required this.prevVolume,
  });

  /// The window these stats cover.
  final AnalyticsRange range;

  /// Number of completed sessions in the window.
  final int workouts;

  /// Number of completed sets in the window.
  final int sets;

  /// Number of repetitions completed in the window.
  final int reps;

  /// Total tonnage (weight x reps) moved in the window.
  final double volume;

  /// Total training minutes in the window.
  final int minutes;

  /// Distinct days with at least one completed session.
  final int activeDays;

  /// Number of personal records set in the window.
  final int prs;

  /// The current consecutive-day streak, as of today.
  final int streak;

  /// Completed sessions in the period of equal length before the window.
  final int prevWorkouts;

  /// Completed sets in the previous period.
  final int prevSets;

  /// Repetitions in the previous period.
  final int prevReps;

  /// Tonnage in the previous period.
  final double prevVolume;

  /// Whether any training happened in the window.
  bool get hasData => workouts > 0 || volume > 0;

  /// Sets per workout (0 when the window is empty).
  double get avgSetsPerWorkout => workouts == 0 ? 0 : sets / workouts;

  /// Volume per session (0 when the window is empty).
  double get avgVolumePerSession => workouts == 0 ? 0 : volume / workouts;

  /// Fractional workout change versus the previous period, or null.
  double? get workoutsDelta =>
      _delta(workouts.toDouble(), prevWorkouts.toDouble());

  /// Fractional set change versus the previous period, or null.
  double? get setsDelta => _delta(sets.toDouble(), prevSets.toDouble());

  /// Fractional volume change versus the previous period, or null.
  double? get volumeDelta => _delta(volume, prevVolume);

  /// Fractional reps change versus the previous period, or null.
  double? get repsDelta => _delta(reps.toDouble(), prevReps.toDouble());

  static double? _delta(double current, double previous) {
    if (previous <= 0) return current > 0 ? null : null;
    return (current - previous) / previous;
  }
}

/// One bar of the volume chart.
class VolumeBucket {
  /// Creates a volume bucket.
  const VolumeBucket({
    required this.label,
    required this.start,
    required this.volume,
    required this.sets,
  });

  /// Short bucket label, e.g. "Feb 4" or "Jan".
  final String label;

  /// The bucket's start date.
  final DateTime start;

  /// Total tonnage in the bucket.
  final double volume;

  /// Completed sets in the bucket.
  final int sets;

  /// The peak tonnage across the full chart, for bar scaling.
  double get maxVolume => volume;
}

/// One day cell of the frequency heatmap.
class FrequencyDay {
  /// Creates a frequency day.
  const FrequencyDay({
    required this.date,
    required this.sets,
    required this.intensity,
  });

  /// The calendar day.
  final DateTime date;

  /// Completed sets logged that day.
  final int sets;

  /// 0..1 normalized intensity used for the fill opacity.
  final double intensity;

  /// Whether any training happened that day.
  bool get trained => sets > 0;
}

/// The heatmap grid: one row per week, seven day cells (Mon..Sun).
class FrequencyHeatmapData {
  /// Creates heatmap data.
  const FrequencyHeatmapData({
    required this.weeks,
    required this.maxSets,
    required this.totalWorkouts,
  });

  /// Weeks oldest-first; each row holds seven cells (null after today).
  final List<List<FrequencyDay?>> weeks;

  /// The highest daily set count, for normalization.
  final int maxSets;

  /// Number of active days in the grid.
  final int totalWorkouts;
}

/// Body-weight trend over the window.
class WeightTrendData {
  /// Creates weight trend data.
  const WeightTrendData({
    required this.points,
    this.latest,
    this.delta,
    this.min,
    this.max,
    this.average,
  });

  /// Weigh-in points, oldest first.
  final List<WeightPoint> points;

  /// Most recent weigh-in, or null when none exists.
  final double? latest;

  /// Change across the window (last minus first), or null.
  final double? delta;

  /// Lightest reading in the window, or null.
  final double? min;

  /// Heaviest reading in the window, or null.
  final double? max;

  /// Mean reading in the window, or null.
  final double? average;

  /// Whether the window contains any weigh-ins.
  bool get hasData => points.isNotEmpty;
}

/// A single weigh-in point for the weight chart.
class WeightPoint {
  /// Creates a weight point.
  const WeightPoint({required this.date, required this.weight});

  /// The weigh-in date.
  final DateTime date;

  /// The recorded weight.
  final double weight;
}

/// A ranked view of one exercise's performance in the window.
class ExerciseAnalytics {
  /// Creates exercise analytics.
  const ExerciseAnalytics({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.isCompound,
    required this.sessions,
    required this.sets,
    required this.volume,
    required this.volumePerSession,
    required this.estimatedOneRM,
    required this.estOneRMStart,
    required this.estOneRMEnd,
    required this.estOneRMDelta,
    required this.prs,
  });

  /// The exercise's library id.
  final String exerciseId;

  /// Denormalized display name.
  final String exerciseName;

  /// Primary muscle group, or '' when the library row is missing.
  final String muscleGroup;

  /// Whether the movement is compound.
  final bool isCompound;

  /// How many sessions included the exercise.
  final int sessions;

  /// Completed sets performed in the window.
  final int sets;

  /// Total tonnage of the exercise in the window.
  final double volume;

  /// Volume per session it was performed.
  final double volumePerSession;

  /// Current estimated one-rep max (from the stored record when available).
  final double estimatedOneRM;

  /// Estimated 1RM at the start of the window (0 when never tracked).
  final double estOneRMStart;

  /// Estimated 1RM at the end of the window.
  final double estOneRMEnd;

  /// [estOneRMEnd] minus [estOneRMStart].
  final double estOneRMDelta;

  /// Number of PRs set for this exercise in the window.
  final int prs;
}

/// The estimated 1RM of one exercise at one date.
class OneRmPoint {
  /// Creates a trajectory point.
  const OneRmPoint({required this.date, required this.value});

  /// The date the estimate was recorded.
  final DateTime date;

  /// The estimated one-rep max.
  final double value;
}

/// A full exercise estimated-1RM trajectory over the window.
class OneRmTrajectory {
  /// Creates a trajectory.
  const OneRmTrajectory({
    required this.exerciseId,
    required this.exerciseName,
    required this.points,
  });

  /// The exercise's library id.
  final String exerciseId;

  /// Display name.
  final String exerciseName;

  /// Sorted estimates, oldest first.
  final List<OneRmPoint> points;
}

/// The strength section data: the composite score plus the top trajectories.
class StrengthTrendData {
  /// Creates strength trend data.
  const StrengthTrendData({
    required this.totalOneRM,
    required this.bestOneRM,
    required this.trajectories,
  });

  /// Sum of current estimated 1RMs across tracked exercises.
  final double totalOneRM;

  /// The highest single estimated 1RM.
  final double bestOneRM;

  /// The most-performed exercises' trajectories in the window.
  final List<OneRmTrajectory> trajectories;
}

/// The tone of an insight.
enum InsightKind {
  /// An encouraging, good-news reading.
  positive,

  /// A neutral observation.
  neutral,

  /// A pattern worth the user's attention.
  attention,
}

/// A single generated insight.
class Insight {
  /// Creates an insight.
  const Insight({
    required this.title,
    required this.message,
    required this.kind,
    required this.iconName,
  });

  /// Short headline, e.g. "Volume is up".
  final String title;

  /// The supporting sentence.
  final String message;

  /// How the reading should be framed.
  final InsightKind kind;

  /// Icon key resolved by the presentation layer.
  final String iconName;
}

/// Everything the Progress tab renders for one [AnalyticsRange].
class AnalyticsSnapshot {
  /// Creates an analytics snapshot.
  const AnalyticsSnapshot({
    required this.range,
    required this.now,
    required this.overview,
    required this.volumeBuckets,
    required this.heatmap,
    required this.weight,
    required this.exercises,
    required this.strength,
    required this.prEvents,
  });

  /// The window the snapshot covers.
  final AnalyticsRange range;

  /// The reference clock used to build the snapshot.
  final DateTime now;

  /// The overview aggregates.
  final OverviewStats overview;

  /// Ordered volume bars for the chart.
  final List<VolumeBucket> volumeBuckets;

  /// The training-frequency grid.
  final FrequencyHeatmapData heatmap;

  /// The body-weight trend.
  final WeightTrendData weight;

  /// Per-exercise performance rows, ranked by volume.
  final List<ExerciseAnalytics> exercises;

  /// The composite score plus estimated-1RM trajectories.
  final StrengthTrendData strength;

  /// PR events within the window, newest first.
  final List<PrEvent> prEvents;

  /// Whether any sessions or weigh-ins exist in the window.
  bool get hasData => overview.hasData || weight.hasData;

  /// Whether any sessions exist in the window at all.
  bool get hasSessions => overview.hasData;
}
