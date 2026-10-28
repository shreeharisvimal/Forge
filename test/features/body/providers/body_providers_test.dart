// Provider tests for the Body tab.
//
// Boots the body providers against a real temp-dir Hive store with a pinned
// clock and verifies the snapshot read model, range/field selection, reactive
// updates through the box-change streams, and the settings read.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/body/domain/body_measurement_fields.dart';
import 'package:forge/features/body/providers/body_providers.dart';
import 'package:forge/features/progress/domain/analytics_range.dart';
import 'package:forge/models/body_measurement.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/services/providers.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ProviderContainer container;

  final pinnedNow = DateTime(2026, 8, 30, 9);

  setUp(() async {
    env = await HiveTestEnv.create();

    await env.databaseService.measurementBox.putAll({
      for (final measurement in [
        BodyMeasurement(
          id: 'm1',
          date: DateTime(2026, 8, 1),
          weight: 80,
          waist: 88,
        ),
        BodyMeasurement(
          id: 'm2',
          date: DateTime(2026, 8, 25),
          weight: 79,
          waist: 86,
        ),
      ])
        measurement.id: measurement,
    });

    container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(env.databaseService),
        bodyNowProvider.overrideWithValue(pinnedNow),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await env.dispose();
  });

  group('bodySnapshotProvider', () {
    test('computes the read model from stored measurements', () {
      final snapshot = container.read(bodySnapshotProvider);

      expect(snapshot.hasData, isTrue);
      expect(snapshot.measurementCount, 2);
      expect(snapshot.latest!.weight, 79);
      final waist =
          snapshot.trends.singleWhere((t) => t.field == BodyField.waist);
      expect(waist.latest, 86);
      expect(waist.delta, -2);
    });

    test('narrowing the range filters the snapshot', () {
      container.read(bodyRangeProvider.notifier).state =
          AnalyticsRange.last7Days;

      final snapshot = container.read(bodySnapshotProvider);
      expect(snapshot.measurementCount, 1);
      expect(snapshot.latest!.date.day, 25);
    });
  });

  group('bodyChartTrendProvider', () {
    test('follows the selected chart field', () {
      final trend = container.read(bodyChartTrendProvider);
      expect(trend, isNotNull);
      expect(trend!.field, BodyField.waist);
      expect(trend.points.map((p) => p.value), [88, 86]);
    });

    test('is null for a field with no data', () {
      container.read(bodyChartFieldProvider.notifier).state =
          BodyField.bodyFat;

      expect(container.read(bodyChartTrendProvider), isNull);
    });
  });

  group('reactive updates', () {
    test('saving a measurement refreshes the snapshot', () async {
      final editor = container.read(bodyMeasurementEditorProvider);
      await editor.save(BodyMeasurement(
        date: DateTime(2026, 8, 29),
        weight: 78,
      ));
      await pumpEventQueue();

      final snapshot = container.read(bodySnapshotProvider);
      expect(snapshot.measurementCount, 3);
      expect(snapshot.latest!.weight, 78);
    });

    test('deleting a measurement refreshes the snapshot', () async {
      final editor = container.read(bodyMeasurementEditorProvider);
      await editor.delete(DateTime(2026, 8, 1));
      await pumpEventQueue();

      final snapshot = container.read(bodySnapshotProvider);
      expect(snapshot.measurementCount, 1);
      expect(snapshot.latest!.id, 'm2');
    });

    test('setting a goal surfaces its progress', () async {
      final editor = container.read(bodyGoalEditorProvider);
      await editor.set(field: BodyField.waist, target: 85);
      await pumpEventQueue();

      final snapshot = container.read(bodySnapshotProvider);
      expect(snapshot.goals.single.goal.field, BodyField.waist);
      expect(snapshot.goals.single.current, 86);
      expect(snapshot.goals.single.progress, closeTo(2 / 3, 0.0001));
    });
  });

  group('bodySettingsProvider', () {
    test('reads the stored unit preferences', () async {
      await env.databaseService.settingsBox.put(
        'settings',
        SettingsModel(weightUnit: 'lb', lengthUnit: 'in'),
      );
      await pumpEventQueue();

      final settings = container.read(bodySettingsProvider);
      expect(settings.weightUnit, 'lb');
      expect(settings.lengthUnit, 'in');
    });

    test('falls back to defaults on a fresh install', () {
      final settings = container.read(bodySettingsProvider);
      expect(settings.weightUnit, 'kg');
      expect(settings.lengthUnit, 'cm');
    });
  });
}
