// Integration tests for the calendar day editor.
//
// Verifies every mutation keeps the calendar, weight and measurement boxes
// consistent, and that rows are pruned once nothing remains.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/calendar/data/calendar_day_editor.dart';
import 'package:forge/features/calendar/domain/calendar_models.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/measurement_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late CalendarRepository calendar;
  late WeightRepository weights;
  late MeasurementRepository measurements;
  late CalendarDayEditor editor;

  final day = DateTime(2026, 2, 4);

  setUp(() async {
    env = await HiveTestEnv.create();
    calendar = HiveCalendarRepository(env.databaseService.calendarBox);
    weights = HiveWeightRepository(env.databaseService.weightBox);
    measurements = HiveMeasurementRepository(env.databaseService.measurementBox);
    editor = CalendarDayEditor(
      calendar: calendar,
      weights: weights,
      measurements: measurements,
    );
  });

  tearDown(() => env.dispose());

  group('setWeight', () {
    test('writes the weigh-in to the calendar row and weight history',
        () async {
      await editor.setWeight(DateTime(2026, 2, 4, 15), 82.5);

      expect(editor.rowOn(day)?.weight, 82.5);
      expect(editor.weightOn(day)?.weight, 82.5);
      expect(weights.latest()?.weight, 82.5);
    });

    test('updates an existing weigh-in without duplicating rows', () async {
      await editor.setWeight(day, 80);
      await editor.setWeight(day, 79.5);

      expect(calendar.count, 1);
      expect(weights.count, 1);
      expect(editor.rowOn(day)?.weight, 79.5);
      expect(editor.weightOn(day)?.weight, 79.5);
    });

    test('clearing a weigh-in removes the row and the history entry', () async {
      await editor.setWeight(day, 80);
      await editor.setWeight(day, null);

      expect(editor.weightOn(day), isNull);
      expect(editor.rowOn(day), isNull, reason: 'empty row must be pruned');
      expect(calendar.count, 0);
      expect(weights.count, 0);
    });

    test('clearing with no stored weigh-in is a no-op', () async {
      await editor.setWeight(day, null);

      expect(calendar.count, 0);
      expect(weights.count, 0);
    });
  });

  group('setDaily', () {
    test('merges lifestyle fields into one row', () async {
      await editor.setDaily(
        date: day,
        sleepHours: () => 7.5,
        mood: () => 4,
      );
      await editor.setDaily(
        date: day,
        waterLitres: () => 2.5,
        durationMinutes: 45,
        workoutCompleted: true,
      );

      final row = editor.rowOn(day);
      expect(row?.sleepHours, 7.5);
      expect(row?.waterLitres, 2.5);
      expect(row?.mood, 4);
      expect(row?.durationMinutes, 45);
      expect(row?.workoutCompleted, isTrue);
      expect(calendar.count, 1);
    });

    test('notes are persisted', () async {
      await editor.setDaily(date: day, notes: 'Great session');

      expect(editor.rowOn(day)?.notes, 'Great session');
    });

    test('prunes the row when the last field is cleared', () async {
      await editor.setDaily(date: day, mood: () => 3);
      await editor.setDaily(date: day, mood: () => null);

      expect(editor.rowOn(day), isNull);
      expect(calendar.count, 0);
    });
  });

  group('setMeasurement', () {
    test('creates a record from non-null fields', () async {
      await editor.setMeasurement(
        date: day,
        fields: {
          MeasurementField.waist: 80,
          MeasurementField.chest: 100,
          MeasurementField.leftArm: 38,
          MeasurementField.bodyFat: 18,
        },
      );

      final measurement = editor.measurementOn(day);
      expect(measurement?.waist, 80);
      expect(measurement?.chest, 100);
      expect(measurement?.leftArm, 38);
      expect(measurement?.bodyFat, 18);
    });

    test('updates in place and preserves unset fields', () async {
      await editor.setMeasurement(
        date: day,
        fields: {MeasurementField.waist: 80, MeasurementField.chest: 100},
      );
      await editor.setMeasurement(
        date: day,
        fields: {MeasurementField.waist: 81},
      );

      final measurement = editor.measurementOn(day);
      expect(measurement?.waist, 81);
      expect(measurement?.chest, 100);
      expect(measurements.count, 1);
    });

    test('persists every editable field', () async {
      await editor.setMeasurement(
        date: day,
        fields: {
          MeasurementField.waist: 80,
          MeasurementField.neck: 38,
          MeasurementField.chest: 100,
          MeasurementField.shoulders: 120,
          MeasurementField.leftArm: 38,
          MeasurementField.rightArm: 39,
          MeasurementField.leftForearm: 30,
          MeasurementField.rightForearm: 31,
          MeasurementField.leftThigh: 60,
          MeasurementField.rightThigh: 61,
          MeasurementField.leftCalf: 38,
          MeasurementField.rightCalf: 39,
          MeasurementField.bodyFat: 18,
        },
      );

      final measurement = editor.measurementOn(day);
      expect(measurement?.waist, 80);
      expect(measurement?.neck, 38);
      expect(measurement?.chest, 100);
      expect(measurement?.shoulders, 120);
      expect(measurement?.leftArm, 38);
      expect(measurement?.rightArm, 39);
      expect(measurement?.leftForearm, 30);
      expect(measurement?.rightForearm, 31);
      expect(measurement?.leftThigh, 60);
      expect(measurement?.rightThigh, 61);
      expect(measurement?.leftCalf, 38);
      expect(measurement?.rightCalf, 39);
      expect(measurement?.bodyFat, 18);
    });

    test('deletes a record that becomes empty', () async {
      await editor.setMeasurement(
        date: day,
        fields: {MeasurementField.waist: 80},
      );
      await editor.setMeasurement(
        date: day,
        fields: {MeasurementField.waist: null},
      );

      expect(editor.measurementOn(day), isNull);
      expect(measurements.count, 0);
    });

    test('does not write when every field is null', () async {
      await editor.setMeasurement(
        date: day,
        fields: {MeasurementField.waist: null},
      );

      expect(editor.measurementOn(day), isNull);
      expect(measurements.count, 0);
    });
  });

  group('setPhotos', () {
    test('stores the photo and thumbnail paths', () async {
      await editor.setPhotos(day, ['photos/a.jpg'], ['photos/a_thumb.jpg']);

      final row = editor.rowOn(day);
      expect(row?.photos, ['photos/a.jpg']);
      expect(row?.photoThumbs, ['photos/a_thumb.jpg']);
    });

    test('prunes the row when photos are cleared', () async {
      await editor.setPhotos(day, ['photos/a.jpg'], ['photos/a_thumb.jpg']);
      await editor.setPhotos(day, [], []);

      expect(editor.rowOn(day), isNull);
      expect(calendar.count, 0);
    });
  });

  group('pruning', () {
    test('a row survives while any content remains', () async {
      await editor.setDaily(date: day, sleepHours: () => 7);
      await editor.setWeight(day, 80);
      await editor.setWeight(day, null);

      expect(editor.rowOn(day)?.sleepHours, 7);
      expect(editor.rowOn(day)?.weight, isNull);
    });
  });
}
