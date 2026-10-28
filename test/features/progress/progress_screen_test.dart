// Widget tests for the progress screen.
//
// Renders the analytics tab directly against temp-dir Hive with the pinned
// clock, verifies every section appears from seeded data, the empty state
// renders on a fresh install, and the range selector rescopes the window.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/theme/forge_theme.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/prs/providers/pr_providers.dart';
import 'package:forge/features/progress/progress_screen.dart';
import 'package:forge/features/progress/providers/progress_providers.dart';
import 'package:forge/services/providers.dart';

import 'progress_test_data.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> useSurface(WidgetTester tester, double height) async {
    tester.view.physicalSize = Size(800, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpProgress(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
          progressNowProvider.overrideWithValue(pinnedProgressNow),
          prNowProvider.overrideWithValue(pinnedProgressNow),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ForgeTheme.dark(),
          home: const ProgressScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every analytics section from seeded data',
      (tester) async {
    await useSurface(tester, 12000);
    await tester.runAsync(() => seedProgressData(databaseService));
    await pumpProgress(tester);

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Estimated 1RM'), findsOneWidget);
    expect(find.text('Volume'), findsWidgets);
    expect(find.text('Frequency'), findsWidgets);
    expect(find.text('Body weight'), findsOneWidget);
    expect(find.text('Top exercises'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Records'), findsWidgets);

    expect(find.text('Last 90 days'), findsWidgets);
    expect(find.text('Bench Press'), findsWidgets);
    expect(find.text('Goal 80.0 kg'), findsOneWidget);

    expect(find.text('First workout'), findsOneWidget);
    expect(find.text('Unlocked'), findsWidgets);
  });

  testWidgets('renders the empty state on a fresh install', (tester) async {
    await useSurface(tester, 3000);
    await pumpProgress(tester);

    expect(find.text('Your progress starts here'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
  });

  testWidgets('range selector rescopes the window', (tester) async {
    await useSurface(tester, 3000);
    await tester.runAsync(() => seedProgressData(databaseService));
    await pumpProgress(tester);

    await tester.tap(find.text('7D'));
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsWidgets);
  });
}
