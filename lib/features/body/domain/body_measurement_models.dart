// Body measurement read models for the Forge application.
//
// Immutable value types produced by [BodyCalculations] and consumed by the
// Body providers and widgets. Kept free of Flutter and Riverpod imports so
// the whole analytics pipeline is unit-testable without a widget tree.
library;

import '../../../models/body_measurement.dart';
import '../../progress/domain/analytics_models.dart';
import '../../progress/domain/analytics_range.dart';
import 'body_goals.dart';
import 'body_measurement_fields.dart';

/// One value of a single field on a single date.
class BodyTrendPoint {
  /// Creates a trend point.
  const BodyTrendPoint({required this.date, required this.value});

  /// The measurement date.
  final DateTime date;

  /// The recorded value.
  final double value;
}

/// The time series of one field within the selected window.
class BodyFieldTrend {
  /// Creates a field trend.
  const BodyFieldTrend({
    required this.field,
    required this.points,
    this.latest,
    this.delta,
    this.min,
    this.max,
    this.average,
  });

  /// The tracked field.
  final BodyField field;

  /// The field's values, oldest first.
  final List<BodyTrendPoint> points;

  /// The most recent value in the window, or null.
  final double? latest;

  /// Change across the window (last minus first), or null.
  final double? delta;

  /// Smallest value in the window, or null.
  final double? min;

  /// Largest value in the window, or null.
  final double? max;

  /// Mean value in the window, or null.
  final double? average;

  /// Whether the window contains any values for this field.
  bool get hasData => points.isNotEmpty;
}

/// The latest value of a field versus the measurement before it.
class BodyComparisonEntry {
  /// Creates a comparison entry.
  const BodyComparisonEntry({
    required this.field,
    this.latest,
    this.previous,
    this.delta,
    this.deltaPct,
  });

  /// The compared field.
  final BodyField field;

  /// The most recent value, or null.
  final double? latest;

  /// The value on the measurement before the latest, or null.
  final double? previous;

  /// [latest] minus [previous], or null.
  final double? delta;

  /// Fractional change ([delta] / [previous]), or null.
  final double? deltaPct;

  /// Whether both values are present.
  bool get hasData => latest != null && previous != null;
}

/// The derived fat/lean split for one measurement day.
class BodyComposition {
  /// Creates a composition reading.
  const BodyComposition({
    required this.date,
    this.weight,
    this.bodyFat,
    this.bodyFatMass,
    this.leanMass,
  });

  /// The measurement date.
  final DateTime date;

  /// The day's body weight, or null.
  final double? weight;

  /// The day's body-fat percentage, or null.
  final double? bodyFat;

  /// Estimated fat mass (weight x body-fat fraction), or null.
  final double? bodyFatMass;

  /// Estimated lean mass (weight minus fat mass), or null.
  final double? leanMass;
}

/// The progress of one goal toward its target.
class BodyGoalProgress {
  /// Creates a goal progress reading.
  const BodyGoalProgress({
    required this.goal,
    this.current,
    this.start,
    this.progress,
  });

  /// The goal being tracked.
  final BodyGoal goal;

  /// The latest measured value, or null.
  final double? current;

  /// The first measured value in the window (the baseline), or null.
  final double? start;

  /// 0..1 fraction of the distance from [start] to the target, or null when
  /// no baseline exists yet.
  final double? progress;

  /// Whether the target has been reached.
  bool get isMet => progress != null && progress! >= 1;
}

/// A single generated body insight.
class BodyInsight {
  /// Creates an insight.
  const BodyInsight({
    required this.title,
    required this.message,
    required this.kind,
    required this.iconName,
  });

  /// Short headline, e.g. "Waist is shrinking".
  final String title;

  /// The supporting sentence.
  final String message;

  /// How the reading should be framed.
  final InsightKind kind;

  /// Icon key resolved by the presentation layer.
  final String iconName;
}

/// Everything the Body tab renders for one [AnalyticsRange].
class BodySnapshot {
  /// Creates a body snapshot.
  const BodySnapshot({
    required this.range,
    required this.now,
    required this.measurements,
    required this.latest,
    required this.previous,
    required this.trends,
    required this.comparisons,
    required this.goals,
    required this.composition,
    required this.insights,
  });

  /// The window the snapshot covers.
  final AnalyticsRange range;

  /// The reference clock used to build the snapshot.
  final DateTime now;

  /// The measurements within the window, oldest first.
  final List<BodyMeasurement> measurements;

  /// The most recent measurement in the window, or null.
  final BodyMeasurement? latest;

  /// The measurement before [latest] in the full history, or null.
  final BodyMeasurement? previous;

  /// One trend per field with data in the window.
  final List<BodyFieldTrend> trends;

  /// Latest-versus-previous deltas for every tracked field.
  final List<BodyComparisonEntry> comparisons;

  /// Goal progress readings.
  final List<BodyGoalProgress> goals;

  /// Derived fat/lean splits for the window's measurements.
  final List<BodyComposition> composition;

  /// Generated insights.
  final List<BodyInsight> insights;

  /// Number of measurements within the window.
  int get measurementCount => measurements.length;

  /// Whether any measurements exist in the window.
  bool get hasData => measurements.isNotEmpty;
}
