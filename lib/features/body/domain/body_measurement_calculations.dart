// Body measurement analytics for the Forge application.
//
// Turns the raw measurement history into the read models the Body tab
// renders: per-field time series, latest-versus-previous comparisons, goal
// progress, derived body composition and deterministic insights. Pure
// functions only — no Flutter or Riverpod imports.
library;

import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../../progress/domain/analytics_models.dart';
import '../../progress/domain/analytics_range.dart';
import 'body_goals.dart';
import 'body_measurement_fields.dart';
import 'body_measurement_models.dart';

/// Computes every body read model for one [AnalyticsRange].
abstract final class BodyCalculations {
  BodyCalculations._();

  /// Minimum absolute change (in the field's unit) before a trend counts as
  /// a real movement rather than noise.
  static const double _meaningfulDelta = 0.5;

  /// Minimum change in kg of derived mass before it counts as a movement.
  static const double _meaningfulMassDelta = 0.2;

  /// The maximum number of insights a snapshot carries.
  static const int _maxInsights = 4;

  /// Builds a [BodySnapshot] for [range] as of [now].
  ///
  /// [all] is the complete measurement history from the repository (any
  /// order); [goals] are the user's active targets.
  static BodySnapshot compute({
    required List<BodyMeasurement> all,
    required DateTime now,
    required AnalyticsRange range,
    required List<BodyGoal> goals,
  }) {
    final today = dateOnly(now);
    final from = range.startDate(today);

    final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
    final inRange = sorted
        .where((measurement) {
          final day = dateOnly(measurement.date);
          return (from == null || !day.isBefore(from)) && !day.isAfter(today);
        })
        .toList();

    final latest = inRange.isEmpty ? null : inRange.last;
    final previous = _predecessor(sorted, latest);

    final trends = <BodyFieldTrend>[];
    for (final field in BodyField.all) {
      final trend = _trend(field, inRange);
      if (trend.hasData) trends.add(trend);
    }

    final comparisons = <BodyComparisonEntry>[];
    for (final field in BodyField.all) {
      final entry = _comparison(field, latest, previous);
      if (entry.latest != null) comparisons.add(entry);
    }

    final goalProgress = [
      for (final goal in goals)
        _goalProgress(
          goal,
          start: _firstValue(goal.field, inRange),
          current: latest == null ? null : goal.field.valueOf(latest),
        ),
    ];

    final composition = _composition(inRange);

    return BodySnapshot(
      range: range,
      now: now,
      measurements: inRange,
      latest: latest,
      previous: previous,
      trends: trends,
      comparisons: comparisons,
      goals: goalProgress,
      composition: composition,
      insights: _insights(
        trends: trends,
        composition: composition,
        inRange: inRange,
        today: today,
      ),
    );
  }

  /// The measurement immediately before [latest] in [sorted], or null.
  static BodyMeasurement? _predecessor(
    List<BodyMeasurement> sorted,
    BodyMeasurement? latest,
  ) {
    if (latest == null || sorted.isEmpty) return null;
    final index = sorted.indexWhere((entry) => entry.id == latest.id);
    if (index <= 0) return null;
    return sorted[index - 1];
  }

  static BodyFieldTrend _trend(BodyField field, List<BodyMeasurement> inRange) {
    final points = <BodyTrendPoint>[];
    for (final measurement in inRange) {
      final value = field.valueOf(measurement);
      if (value != null) {
        points.add(BodyTrendPoint(date: measurement.date, value: value));
      }
    }
    if (points.isEmpty) {
      return BodyFieldTrend(field: field, points: points);
    }
    var min = points.first.value;
    var max = points.first.value;
    var sum = 0.0;
    for (final point in points) {
      if (point.value < min) min = point.value;
      if (point.value > max) max = point.value;
      sum += point.value;
    }
    return BodyFieldTrend(
      field: field,
      points: points,
      latest: points.last.value,
      delta: points.length >= 2 ? points.last.value - points.first.value : null,
      min: min,
      max: max,
      average: sum / points.length,
    );
  }

  static BodyComparisonEntry _comparison(
    BodyField field,
    BodyMeasurement? latest,
    BodyMeasurement? previous,
  ) {
    final current = latest == null ? null : field.valueOf(latest);
    final before = previous == null ? null : field.valueOf(previous);
    double? delta;
    if (current != null && before != null) delta = current - before;
    return BodyComparisonEntry(
      field: field,
      latest: current,
      previous: before,
      delta: delta,
      deltaPct: delta != null && before != null && before != 0
          ? delta / before
          : null,
    );
  }

  static double? _firstValue(BodyField field, List<BodyMeasurement> inRange) {
    for (final measurement in inRange) {
      final value = field.valueOf(measurement);
      if (value != null) return value;
    }
    return null;
  }

  static BodyGoalProgress _goalProgress(
    BodyGoal goal, {
    required double? start,
    required double? current,
  }) {
    if (current == null) {
      return BodyGoalProgress(goal: goal, current: null, start: start);
    }
    final reduction = goal.field.prefersReduction;
    if (reduction && current <= goal.target) {
      return BodyGoalProgress(
        goal: goal,
        current: current,
        start: start,
        progress: 1.0,
      );
    }
    if (!reduction && current >= goal.target) {
      return BodyGoalProgress(
        goal: goal,
        current: current,
        start: start,
        progress: 1.0,
      );
    }
    if (start == null) {
      return BodyGoalProgress(goal: goal, current: current, start: null);
    }
    final total = (goal.target - start).abs();
    if (total <= 0.0001) {
      return BodyGoalProgress(goal: goal, current: current, start: start);
    }
    final travelled = reduction ? start - current : current - start;
    return BodyGoalProgress(
      goal: goal,
      current: current,
      start: start,
      progress: (travelled / total).clamp(0.0, 1.0).toDouble(),
    );
  }

  static List<BodyComposition> _composition(List<BodyMeasurement> inRange) {
    final result = <BodyComposition>[];
    for (final measurement in inRange) {
      final weight = measurement.weight;
      final bodyFat = measurement.bodyFat;
      if (weight == null || bodyFat == null) continue;
      final fatMass = weight * bodyFat / 100;
      result.add(BodyComposition(
        date: measurement.date,
        weight: weight,
        bodyFat: bodyFat,
        bodyFatMass: fatMass,
        leanMass: weight - fatMass,
      ));
    }
    return result;
  }

  static List<BodyInsight> _insights({
    required List<BodyFieldTrend> trends,
    required List<BodyComposition> composition,
    required List<BodyMeasurement> inRange,
    required DateTime today,
  }) {
    final byField = {for (final trend in trends) trend.field: trend};
    final insights = <BodyInsight>[];

    void add(BodyInsight insight) {
      if (insights.length >= _maxInsights) return;
      insights.add(insight);
    }

    final waist = byField[BodyField.waist];
    if (waist != null && waist.delta != null) {
      if (waist.delta! <= -_meaningfulDelta) {
        add(BodyInsight(
          title: 'Waist is shrinking',
          message: 'Waist is ${waist.delta!.abs().toStringAsFixed(1)} smaller '
              'than at the start of this window.',
          kind: InsightKind.positive,
          iconName: 'linear_scale',
        ));
      } else if (waist.delta! >= _meaningfulDelta) {
        add(BodyInsight(
          title: 'Waist is creeping up',
          message: 'Waist grew ${waist.delta!.toStringAsFixed(1)} over this '
              'window.',
          kind: InsightKind.attention,
          iconName: 'linear_scale',
        ));
      }
    }

    final bodyFat = byField[BodyField.bodyFat];
    if (bodyFat != null && bodyFat.delta != null) {
      if (bodyFat.delta! <= -_meaningfulDelta) {
        add(BodyInsight(
          title: 'Body fat is down',
          message: 'Body fat dropped ${bodyFat.delta!.abs().toStringAsFixed(1)}'
              ' percentage points in this window.',
          kind: InsightKind.positive,
          iconName: 'percent',
        ));
      } else if (bodyFat.delta! >= _meaningfulDelta) {
        add(BodyInsight(
          title: 'Body fat is up',
          message: 'Body fat rose ${bodyFat.delta!.toStringAsFixed(1)} '
              'percentage points in this window.',
          kind: InsightKind.attention,
          iconName: 'percent',
        ));
      }
    }

    final armDelta = _armDelta(byField);
    if (armDelta != null && armDelta >= _meaningfulDelta) {
      add(BodyInsight(
        title: 'Arms are growing',
        message: 'Your arms gained ${armDelta.toStringAsFixed(1)} in this '
            'window.',
        kind: InsightKind.positive,
        iconName: 'fitness_center',
      ));
    }

    if (composition.length >= 2) {
      final lean = composition.last.leanMass! - composition.first.leanMass!;
      final fat = composition.last.bodyFatMass! - composition.first.bodyFatMass!;
      if (lean >= _meaningfulMassDelta) {
        add(BodyInsight(
          title: 'Lean mass is up',
          message: 'Estimated lean mass is ${lean.toStringAsFixed(1)} higher '
              'than its first reading here.',
          kind: InsightKind.positive,
          iconName: 'fitness_center',
        ));
      } else if (fat <= -_meaningfulMassDelta) {
        add(BodyInsight(
          title: 'Fat mass is down',
          message: 'Estimated fat mass is ${fat.abs().toStringAsFixed(1)} '
              'lower than its first reading here.',
          kind: InsightKind.positive,
          iconName: 'whatshot',
        ));
      }
    }

    final weight = byField[BodyField.weight];
    if (weight != null && weight.delta != null) {
      if (weight.delta! <= -_meaningfulDelta) {
        add(BodyInsight(
          title: 'Weight trending down',
          message: 'Body weight is ${weight.delta!.abs().toStringAsFixed(1)} '
              'lower than at the start of this window.',
          kind: InsightKind.positive,
          iconName: 'monitor_weight',
        ));
      } else if (weight.delta! >= _meaningfulDelta) {
        add(BodyInsight(
          title: 'Weight creeping up',
          message: 'Body weight rose ${weight.delta!.toStringAsFixed(1)} over '
              'this window.',
          kind: InsightKind.attention,
          iconName: 'monitor_weight',
        ));
      }
    }

    final recent = _countInTrailingDays(inRange, today, 30);
    if (recent >= 2) {
      add(BodyInsight(
        title: 'Consistent tracking',
        message: 'You logged measurements on $recent days in the last month. '
            'Keep the cadence.',
        kind: InsightKind.neutral,
        iconName: 'event_repeat',
      ));
    } else if (inRange.isNotEmpty && recent == 0) {
      add(BodyInsight(
        title: 'Time to measure again',
        message: 'Your latest measurement is more than a month old.',
        kind: InsightKind.attention,
        iconName: 'schedule',
      ));
    }

    return insights;
  }

  /// The larger of the two arm deltas, or null when neither arm is tracked.
  static double? _armDelta(Map<BodyField, BodyFieldTrend> byField) {
    final left = byField[BodyField.leftArm]?.delta;
    final right = byField[BodyField.rightArm]?.delta;
    if (left == null && right == null) return null;
    if (left == null) return right;
    if (right == null) return left;
    return left >= right ? left : right;
  }

  /// How many measurement days fall within the trailing [days] window.
  static int _countInTrailingDays(
    List<BodyMeasurement> inRange,
    DateTime today,
    int days,
  ) {
    final threshold = today.subtract(Duration(days: days - 1));
    var count = 0;
    for (final measurement in inRange) {
      if (!dateOnly(measurement.date).isBefore(threshold)) count += 1;
    }
    return count;
  }
}
