// Widget tests for the Forge application shell.
//
// Boots the real router with temp-dir Hive (mirroring main()) and verifies
// the shell renders its ambient background and floating glass navigation,
// and that tapping a destination switches the active tab.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:forge/core/design/tokens/spacing_tokens.dart';
import 'package:forge/core/design/widgets/glass_navigation_bar.dart';
import 'package:forge/core/design/widgets/glass_navigation_item.dart';
import 'package:forge/core/router/app_route_paths.dart';
import 'package:forge/core/widgets/forge_background.dart';
import 'package:forge/core/widgets/forge_shell.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/database/seeder.dart';
import 'package:forge/features/calendar/calendar_screen.dart';
import 'package:forge/features/dashboard/dashboard_screen.dart';
import 'package:forge/features/splits/presentation/split_list_screen.dart';
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

  Future<void> useTallSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shell renders the ambient background and glass navigation',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(ForgeShell), findsOneWidget);
    expect(find.byType(ForgeBackground), findsOneWidget);
    expect(find.byType(GlassNavigationBar), findsOneWidget);
    expect(find.byType(GlassNavigationItem), findsNWidgets(6));
  });

  testWidgets('tapping a destination switches the active tab',
      (WidgetTester tester) async {
    await useTallSurface(tester);
    await pumpApp(tester);

    // The dashboard is active by default.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(GlassNavigationBar),
        matching: find.text('Calendar'),
      ),
    );
    await tester.pumpAndSettle();

    // The calendar becomes the active branch: its screen renders and the
    // nav label reflects the selection.
    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('shell constrains content width on wide screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    // The tab content is centered and capped at the max content width so
    // desktop layouts stay readable rather than stretching edge to edge.
    final width = tester.getSize(find.byType(DashboardScreen)).width;
    expect(width, lessThanOrEqualTo(AppSpacing.maxContentWidth));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == AppSpacing.maxContentWidth,
      ),
      findsWidgets,
    );
  });

  testWidgets('pushed routes use the glass page transition',
      (WidgetTester tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(ForgeShell));
    GoRouter.of(context).go(AppRoutePaths.splits);
    await tester.pumpAndSettle();

    expect(find.byType(SplitListScreen), findsOneWidget);

    // The full-screen split route is pushed over the shell with an explicit
    // glass transition page rather than a default Material page.
    CustomTransitionPage<dynamic>? splitsPage;
    for (final navigator
        in tester.stateList<NavigatorState>(find.byType(Navigator))) {
      for (final page in navigator.widget.pages) {
        if (page is CustomTransitionPage<dynamic> &&
            page.child is SplitListScreen) {
          splitsPage = page;
        }
      }
    }
    expect(splitsPage, isNotNull);
  });
}
