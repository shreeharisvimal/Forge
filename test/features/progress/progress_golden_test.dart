// Golden tests for the progress screen.
//
// Renders the analytics tab in isolation against seeded data and on a fresh
// install, then compares each frame to the committed golden. Run with
// `--update-goldens` to regenerate.
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

  Future<void> pumpProgress(WidgetTester tester) async {
    tester.view.physicalSize = const Size(820, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

  testWidgets('progress matches the seeded golden', (tester) async {
    await tester.runAsync(() => seedProgressData(databaseService));
    await pumpProgress(tester);

    await expectLater(
      find.byType(ProgressScreen),
      matchesGoldenFile('goldens/progress_seeded.png'),
    );
  });

  testWidgets('progress matches the empty golden', (tester) async {
    await pumpProgress(tester);

    await expectLater(
      find.byType(ProgressScreen),
      matchesGoldenFile('goldens/progress_empty.png'),
    );
  });
}
