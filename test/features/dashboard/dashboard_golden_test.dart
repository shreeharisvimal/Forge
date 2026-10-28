// Golden test for the dashboard screen.
//
// Renders the dashboard in isolation (no shell background or navigation so
// the frame is deterministic) against seeded data and compares it to the
// committed golden. Run with `--update-goldens` to regenerate.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/theme/forge_theme.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/dashboard/dashboard_screen.dart';
import 'package:forge/features/dashboard/providers/dashboard_providers.dart';
import 'package:forge/services/providers.dart';

import 'dashboard_test_data.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
    await seedDashboardData(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('dashboard matches the seeded golden', (tester) async {
    tester.view.physicalSize = const Size(840, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
          dashboardNowProvider.overrideWithValue(pinnedDashboardNow),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ForgeTheme.dark(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_seeded.png'),
    );
  });
}
