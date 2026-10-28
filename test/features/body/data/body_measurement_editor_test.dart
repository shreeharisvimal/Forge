// Tests for the body measurement editor.
//
// Verifies that records upsert per calendar day (keeping the stored id),
// fully empty records are pruned, and deleting removes the day's row.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/body/data/body_measurement_editor.dart';
import 'package:forge/models/body_measurement.dart';
import 'package:forge/services/repositories/measurement_repository.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late BodyMeasurementEditor editor;

  setUp(() async {
    env = await HiveTestEnv.create();
    editor = BodyMeasurementEditor(
      measurements:
          HiveMeasurementRepository(env.databaseService.measurementBox),
    );
  });

  tearDown(() => env.dispose());

  test('saves a new measurement for the day', () async {
    await editor.save(BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 82,
      waist: 86,
    ));

    final stored = editor.onDate(DateTime(2026, 8, 4));
    expect(stored, isNotNull);
    expect(stored!.weight, 82);
    expect(stored.waist, 86);
  });

  test('re-saving on the same day keeps the stored id', () async {
    final original = BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 82,
    );
    await editor.save(original);

    final replacement = BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 81,
      waist: 85,
    );
    await editor.save(replacement);

    final stored = editor.onDate(DateTime(2026, 8, 4))!;
    expect(stored.id, original.id);
    expect(stored.weight, 81);
    expect(stored.waist, 85);
    expect(editor.measurements.count, 1);
  });

  test('a new fully-empty record is pruned', () async {
    await editor.save(BodyMeasurement(date: DateTime(2026, 8, 4)));

    expect(editor.onDate(DateTime(2026, 8, 4)), isNull);
    expect(editor.measurements.count, 0);
  });

  test('emptying an existing record removes the row', () async {
    await editor.save(BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 82,
    ));
    expect(editor.measurements.count, 1);

    await editor.save(BodyMeasurement(date: DateTime(2026, 8, 4)));

    expect(editor.measurements.count, 0);
    expect(editor.onDate(DateTime(2026, 8, 4)), isNull);
  });

  test('delete removes the stored day record', () async {
    await editor.save(BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 82,
    ));
    expect(editor.onDate(DateTime(2026, 8, 4)), isNotNull);

    await editor.delete(DateTime(2026, 8, 4));

    expect(editor.onDate(DateTime(2026, 8, 4)), isNull);
  });

  test('delete on an empty day is a no-op', () async {
    await editor.delete(DateTime(2026, 8, 10));

    expect(editor.measurements.count, 0);
  });

  test('different days coexist as separate records', () async {
    await editor.save(BodyMeasurement(
      date: DateTime(2026, 8, 4),
      weight: 82,
    ));
    await editor.save(BodyMeasurement(
      date: DateTime(2026, 8, 11),
      weight: 81,
    ));

    expect(editor.measurements.count, 2);
    expect(editor.onDate(DateTime(2026, 8, 4))!.weight, 82);
    expect(editor.onDate(DateTime(2026, 8, 11))!.weight, 81);
  });
}
