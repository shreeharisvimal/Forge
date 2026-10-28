// Smoke test for the Forge application.
//
// Verifies that the app boots into the router-backed shell and that the
// persistent floating glass navigation shows all six top-level
// destinations. The real storage bootstrap runs first (temp-dir Hive),
// mirroring main(). Deeper widget tests are added per feature as they are
// built.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/database_service.dart';
import 'package:forge/database/seeder.dart';
import 'package:forge/core/design/widgets/glass_navigation_bar.dart';
import 'package:forge/core/design/widgets/glass_navigation_item.dart';
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

  testWidgets('Forge app renders the six-tab glass navigation shell',
      (WidgetTester tester) async {
    // Build the root application widget inside a provider scope.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
        ],
        child: const ForgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The shell must host exactly one floating glass navigation bar.
    expect(find.byType(GlassNavigationBar), findsOneWidget);
    expect(find.byType(GlassNavigationItem), findsNWidgets(6));

    // All six destinations must be present in the navigation bar.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
