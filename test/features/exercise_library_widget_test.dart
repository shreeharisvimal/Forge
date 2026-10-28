// Widget tests for the exercise library and split screens.
//
// Boots the real router with temp-dir Hive (mirroring main()) and verifies
// the library renders seeded data, search filters work, and the splits hub
// can be reached from the library app bar. The workouts tab is now a hub, so
// the library is reached through its quick-action tile.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/database_service.dart';
import 'package:forge/database/seeder.dart';
import 'package:forge/main.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/exercise_repository.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
    final seeder = Seeder(
      databaseService: databaseService,
      exerciseRepository: HiveExerciseRepository(databaseService.exerciseBox),
    );
    await seeder.runIfNeeded();
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
        ],
        child: const ForgeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openExerciseLibrary(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise Library'));
    await tester.pumpAndSettle();
  }

  testWidgets('exercise library lists seeded exercises', (tester) async {
    await openExerciseLibrary(tester);

    expect(find.text('Exercise Library'), findsWidgets);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Search exercises'), findsOneWidget);
  });

  testWidgets('exercise library search filters results', (tester) async {
    await openExerciseLibrary(tester);

    await tester.enterText(find.byType(TextField).first, 'squat');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
  });

  testWidgets('exercise detail opens from a card', (tester) async {
    await openExerciseLibrary(tester);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('Instructions'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
  });

  testWidgets('splits hub is reachable from the library', (tester) async {
    await openExerciseLibrary(tester);

    await tester.tap(find.byTooltip('Training splits').last);
    await tester.pumpAndSettle();

    expect(find.text('Training Splits'), findsOneWidget);
    expect(find.text('No training splits yet'), findsOneWidget);
    expect(find.text('New Split'), findsOneWidget);
  });

  testWidgets('workouts hub links to the exercise library', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
