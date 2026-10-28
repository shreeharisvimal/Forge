// Tests for the body measurement analytics.
//
// Verifies window filtering, per-field trends, latest-versus-previous
// comparisons, goal progress, fat/lean composition and the deterministic
// insight generation.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/body/domain/body_goals.dart';
import 'package:forge/features/body/domain/body_measurement_calculations.dart';
import 'package:forge/features/body/domain/body_measurement_fields.dart';
import 'package:forge/features/progress/domain/analytics_models.dart';
import 'package:forge/features/progress/domain/analytics_range.dart';
import 'package:forge/models/body_measurement.dart';

BodyMeasurement _measurement({
  required int day,
  double? weight,
  double? waist,
  double? bodyFat,
  double? leftArm,
  double? rightArm,
  String id = 'm',
}) {
  return BodyMeasurement(
    id: '$id$day',
    date: DateTime(2026, 8, day),
    weight: weight,
    waist: waist,
    bodyFat: bodyFat,
    leftArm: leftArm,
    rightArm: rightArm,
  );
}

void main() {
  final now = DateTime(2026, 8, 30);

  group('window filtering', () {
    test('keeps only measurements within the range', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80),
          _measurement(day: 15, weight: 79),
          _measurement(day: 25, weight: 78),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        goals: const [],
      );

      expect(snapshot.measurements.map((m) => m.date.day), [25]);
      expect(snapshot.measurementCount, 1);
    });

    test('lifetime includes everything up to today', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80),
          _measurement(day: 29, weight: 78),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.measurementCount, 2);
    });

    test('excludes measurements after the reference clock', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 29, weight: 78),
          BodyMeasurement(
            id: 'future',
            date: DateTime(2026, 9, 2),
            weight: 77,
          ),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.measurementCount, 1);
    });
  });

  group('trends', () {
    test('computes points, latest, delta, min, max and average', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, waist: 86),
          _measurement(day: 15, waist: 85),
          _measurement(day: 29, waist: 84),
        ],
        now: now,
        range: AnalyticsRange.last30Days,
        goals: const [],
      );

      final trend = snapshot.trends.singleWhere((t) => t.field == BodyField.waist);
      expect(trend.points.map((p) => p.value), [86, 85, 84]);
      expect(trend.latest, 84);
      expect(trend.delta, -2);
      expect(trend.min, 84);
      expect(trend.max, 86);
      expect(trend.average, 85);
    });

    test('single point has latest but no delta', () {
      final snapshot = BodyCalculations.compute(
        all: [_measurement(day: 1, weight: 80)],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      final trend =
          snapshot.trends.singleWhere((t) => t.field == BodyField.weight);
      expect(trend.points.length, 1);
      expect(trend.delta, isNull);
      expect(trend.latest, 80);
    });

    test('fields without data are omitted', () {
      final snapshot = BodyCalculations.compute(
        all: [_measurement(day: 1, weight: 80)],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.trends.map((t) => t.field), [BodyField.weight]);
    });
  });

  group('comparisons', () {
    test('compares latest against the measurement before it', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80),
          _measurement(day: 15, weight: 79),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      final entry = snapshot.comparisons
          .singleWhere((e) => e.field == BodyField.weight);
      expect(entry.latest, 79);
      expect(entry.previous, 80);
      expect(entry.delta, -1);
      expect(entry.deltaPct, closeTo(-0.0125, 0.0001));
    });

    test('the first measurement has no previous', () {
      final snapshot = BodyCalculations.compute(
        all: [_measurement(day: 1, weight: 80)],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      final entry = snapshot.comparisons
          .singleWhere((e) => e.field == BodyField.weight);
      expect(entry.latest, 80);
      expect(entry.previous, isNull);
      expect(entry.hasData, isFalse);
    });

    test('previous comes from the full history even outside the window', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 82, id: 'early'),
          _measurement(day: 25, weight: 80, id: 'late'),
        ],
        now: now,
        range: AnalyticsRange.last7Days,
        goals: const [],
      );

      final entry = snapshot.comparisons
          .singleWhere((e) => e.field == BodyField.weight);
      expect(entry.latest, 80);
      expect(entry.previous, 82);
    });
  });

  group('goals', () {
    BodyGoal goal(BodyField field, double target) =>
        BodyGoal(field: field, target: target, createdAt: DateTime(2026, 8, 1));

    test('reduction goal is met when current is at or below target', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, waist: 88),
          _measurement(day: 29, waist: 84),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: [goal(BodyField.waist, 85)],
      );

      final progress = snapshot.goals.single;
      expect(progress.current, 84);
      expect(progress.start, 88);
      expect(progress.progress, 1.0);
      expect(progress.isMet, isTrue);
    });

    test('reduction goal progress is the travelled fraction', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, waist: 88),
          _measurement(day: 29, waist: 86),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: [goal(BodyField.waist, 84)],
      );

      final progress = snapshot.goals.single;
      expect(progress.progress, closeTo(0.5, 0.0001));
      expect(progress.isMet, isFalse);
    });

    test('growth goal is met when current is at or above target', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, leftArm: 36),
          _measurement(day: 29, leftArm: 40),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: [goal(BodyField.leftArm, 39)],
      );

      final progress = snapshot.goals.single;
      expect(progress.isMet, isTrue);
    });

    test('a single measurement has not travelled toward the target', () {
      final snapshot = BodyCalculations.compute(
        all: [_measurement(day: 29, waist: 84)],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: [goal(BodyField.waist, 82)],
      );

      final progress = snapshot.goals.single;
      expect(progress.current, 84);
      expect(progress.start, 84);
      expect(progress.progress, 0.0);
      expect(progress.isMet, isFalse);
    });

    test('a goal for an unmeasured field reports null current', () {
      final snapshot = BodyCalculations.compute(
        all: [_measurement(day: 1, weight: 80)],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: [goal(BodyField.waist, 80)],
      );

      expect(snapshot.goals.single.current, isNull);
    });
  });

  group('composition', () {
    test('derives fat and lean mass from weight and body fat', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80, bodyFat: 20),
          _measurement(day: 29, weight: 78, bodyFat: 18),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.composition.length, 2);
      final latest = snapshot.composition.last;
      expect(latest.bodyFatMass, closeTo(14.04, 0.0001));
      expect(latest.leanMass, closeTo(63.96, 0.0001));
    });

    test('skips measurements without weight or body fat', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80, bodyFat: 20),
          _measurement(day: 15, waist: 84),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.composition.length, 1);
    });
  });

  group('insights', () {
    test('reports a shrinking waist as positive', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, waist: 90),
          _measurement(day: 29, waist: 88),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      final insight = snapshot.insights
          .firstWhere((i) => i.title == 'Waist is shrinking');
      expect(insight.kind, InsightKind.positive);
    });

    test('reports a growing waist as attention', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, waist: 84),
          _measurement(day: 29, waist: 87),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      final insight = snapshot.insights
          .firstWhere((i) => i.title == 'Waist is creeping up');
      expect(insight.kind, InsightKind.attention);
    });

    test('reports lean mass gains', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 70, bodyFat: 20),
          _measurement(day: 29, weight: 74, bodyFat: 18),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(
        snapshot.insights.any((i) => i.title == 'Lean mass is up'),
        isTrue,
      );
    });

    test('reports consistent tracking for multiple recent entries', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 80),
          _measurement(day: 15, weight: 79),
          _measurement(day: 29, weight: 78),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(
        snapshot.insights.any((i) => i.title == 'Consistent tracking'),
        isTrue,
      );
    });

    test('flags a measurement more than a month old', () {
      final snapshot = BodyCalculations.compute(
        all: [
          BodyMeasurement(
            id: 'old1',
            date: DateTime(2026, 7, 26),
            weight: 80,
          ),
          BodyMeasurement(
            id: 'old2',
            date: DateTime(2026, 7, 29),
            weight: 79,
          ),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(
        snapshot.insights.any((i) => i.title == 'Time to measure again'),
        isTrue,
      );
    });

    test('caps the number of insights', () {
      final snapshot = BodyCalculations.compute(
        all: [
          _measurement(day: 1, weight: 90, waist: 95, bodyFat: 25, leftArm: 30, rightArm: 30),
          _measurement(day: 29, weight: 80, waist: 85, bodyFat: 20, leftArm: 35, rightArm: 35),
        ],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.insights.length, lessThanOrEqualTo(4));
    });
  });

  group('empty history', () {
    test('produces an empty snapshot without throwing', () {
      final snapshot = BodyCalculations.compute(
        all: const [],
        now: now,
        range: AnalyticsRange.lifetime,
        goals: const [],
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.latest, isNull);
      expect(snapshot.trends, isEmpty);
      expect(snapshot.comparisons, isEmpty);
      expect(snapshot.insights, isEmpty);
    });
  });
}
