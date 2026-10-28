// Integration tests for DatabaseService bootstrap.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/box_names.dart';
import 'package:forge/database/database_service.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_db_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('opens every box eagerly after initialize', () {
    expect(databaseService.calendarBox, isNotNull);
    expect(databaseService.workoutBox, isNotNull);
    expect(databaseService.exerciseBox, isNotNull);
    expect(databaseService.measurementBox, isNotNull);
    expect(databaseService.settingsBox, isNotNull);
    expect(databaseService.templateBox, isNotNull);
    expect(databaseService.prBox, isNotNull);
    expect(databaseService.sessionBox, isNotNull);
    expect(databaseService.historyBox, isNotNull);
    expect(databaseService.weightBox, isNotNull);
    expect(databaseService.metaBox, isNotNull);
  });

  test('box names are all distinct', () {
    final names = {
      BoxNames.calendar,
      BoxNames.workouts,
      BoxNames.exercises,
      BoxNames.measurements,
      BoxNames.settings,
      BoxNames.templates,
      BoxNames.prs,
      BoxNames.sessions,
      BoxNames.history,
      BoxNames.weight,
      BoxNames.meta,
    };
    expect(names, hasLength(11));
  });

  test('isFirstLaunch is true before the schema version is applied', () {
    expect(databaseService.isFirstLaunch, isTrue);
    expect(databaseService.appliedSchemaVersion, isNull);
  });

  test('markSchemaApplied flips isFirstLaunch to false', () async {
    await databaseService.markSchemaApplied();
    expect(databaseService.isFirstLaunch, isFalse);
    expect(databaseService.appliedSchemaVersion, DatabaseService.schemaVersion);
  });

  test('persists schema version across a fresh instance', () async {
    await databaseService.markSchemaApplied();
    await databaseService.close();

    final reopened =
        await DatabaseService.initialize(directory: tempDir.path);
    expect(reopened.isFirstLaunch, isFalse);
    expect(reopened.appliedSchemaVersion, DatabaseService.schemaVersion);
    await reopened.close();
  });
}
