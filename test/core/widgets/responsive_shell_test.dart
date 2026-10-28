// Tests for ForgeShell responsive layout switching.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/design/widgets/glass_navigation_bar.dart';
import 'package:forge/core/design/widgets/glass_navigation_rail.dart';
import 'package:forge/core/widgets/forge_shell.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/database/seeder.dart';
import 'package:forge/main.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/exercise_repository.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_shell_responsive_test');
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

  Future<void> pumpAppAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

  testWidgets('renders GlassNavigationBar when screen width is < 900dp',
      (WidgetTester tester) async {
    await pumpAppAtSize(tester, const Size(800, 1000));

    expect(find.byType(ForgeShell), findsOneWidget);
    expect(find.byType(GlassNavigationBar), findsOneWidget);
    expect(find.byType(GlassNavigationRail), findsNothing);
  });

  testWidgets('renders GlassNavigationRail when screen width is >= 900dp',
      (WidgetTester tester) async {
    await pumpAppAtSize(tester, const Size(1200, 900));

    expect(find.byType(ForgeShell), findsOneWidget);
    expect(find.byType(GlassNavigationRail), findsOneWidget);
    expect(find.byType(GlassNavigationBar), findsNothing);
  });
}
