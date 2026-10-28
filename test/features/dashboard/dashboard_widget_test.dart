// Widget tests for the dashboard screen.
//
// Boots the real router with temp-dir Hive (mirroring main()), pins the
// dashboard clock and verifies the panels render seeded data, the empty
// state prompts render on a fresh install, and quick actions work.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/database_service.dart';
import 'package:forge/features/dashboard/providers/dashboard_providers.dart';
import 'package:forge/main.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/features/dashboard/widgets/recovery_panel.dart';
import 'package:forge/features/dashboard/widgets/weight_panel.dart';

import 'dashboard_test_data.dart';

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

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
          dashboardNowProvider.overrideWithValue(pinnedDashboardNow),
        ],
        child: const ForgeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> useTallSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('dashboard renders seeded panels', (tester) async {
    await useTallSurface(tester);
    await tester.runAsync(() => seedDashboardData(databaseService));
    await pumpDashboard(tester);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('February 4, 2026'), findsOneWidget);

    expect(find.text('Pull'), findsOneWidget);
    expect(find.text('Start another workout'), findsOneWidget);

    expect(find.text('82.0 kg'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(WeightPanel),
        matching: find.text('82.0 kg'),
      ),
      findsOneWidget,
    );
    expect(find.text('Goal 80.0 kg'), findsOneWidget);

    expect(find.text('Recovery'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RecoveryPanel),
        matching: find.text('Back'),
      ),
      findsOneWidget,
    );
    expect(find.text('2%'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);

    expect(find.text('Personal records'), findsOneWidget);
    expect(find.text('+10.0'), findsOneWidget);

    expect(find.text('Quick actions'), findsOneWidget);

    expect(find.text('Quote of the day'), findsOneWidget);

    expect(find.text('Completed 2 exercises'), findsOneWidget);
    expect(find.text('45 minutes'), findsOneWidget);
  });

  testWidgets('dashboard renders helpful empty states on a fresh install',
      (tester) async {
    await useTallSurface(tester);
    await pumpDashboard(tester);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Set up a split'), findsOneWidget);
    expect(find.text('No weigh-ins yet'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.textContaining('No sessions this week'), findsOneWidget);
    expect(find.text('No personal records yet'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('quick action logs a weigh-in through the sheet', (tester) async {
    await useTallSurface(tester);
    await tester.runAsync(() => seedDashboardData(databaseService));
    await pumpDashboard(tester);

    await tester.runAsync(() async {
      await tester.tap(find.text('Log weight'));
      await tester.pumpAndSettle();

      expect(find.text('Log your weight'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '83.5');
      await tester.tap(find.text('Save'));
      await tester.pump();

      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    await tester.pumpAndSettle();

    final weightRepository = HiveWeightRepository(databaseService.weightBox);
    expect(weightRepository.latest()?.weight, 83.5);
  });
}
