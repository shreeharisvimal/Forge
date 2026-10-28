// Widget tests for the settings screen.
//
// Renders the screen against a real temp-directory Hive database and
// verifies the sections render, persisted preferences reflect in the UI and
// interacting with a control writes through the controller to storage.
//
// Hive performs real async I/O, which deadlocks inside the fake-async
// testWidgets zone. Writes are therefore drained with an explicit
// `box.flush()` inside `tester.runAsync`, and the platform channel is mocked
// so `HapticHelper` calls (awaited by `GlassSwitch`) complete.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/forge_design.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/settings/settings_screen.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/services/providers.dart';

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

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ForgeTheme.dark(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Dispatches a tap inside the real-async zone so the controller's Hive
  /// write (initiated by the handler) can complete on the real event loop.
  Future<void> tapInRealAsync(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('renders every section header', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Training defaults'), 300);
    expect(find.text('Training defaults'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Units'), 300);
    expect(find.text('Units'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Workout session'), 300);
    expect(find.text('Workout session'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Reminders'), 300);
    expect(find.text('Reminders'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Data'), 300);
    expect(find.text('Data'), findsOneWidget);

    await tester.scrollUntilVisible(find.textContaining('Forge v'), 300);
    expect(find.textContaining('Forge v'), findsOneWidget);
  });

  testWidgets('theme segment reflects the persisted preference', (tester) async {
    await tester.runAsync(() => databaseService.settingsBox.put(
          'prefs',
          SettingsModel(themeMode: 'dark'),
        ));
    await pumpSettings(tester);

    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('toggling haptics persists through the controller',
      (tester) async {
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Haptic feedback'),
      300,
    );
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(GlassListTile, 'Haptic feedback');
    final switchFinder =
        find.descendant(of: tile, matching: find.byType(GlassSwitch));
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tapInRealAsync(tester, switchFinder);

    final stored = databaseService.settingsBox.values.first;
    expect(stored.hapticsEnabled, isFalse);
  });

  testWidgets('appearance controls write to the settings box',
      (tester) async {
    await pumpSettings(tester);

    await tapInRealAsync(tester, find.text('Light'));

    final stored =
        databaseService.settingsBox.values.first as SettingsModel?;
    expect(stored?.themeMode, 'light');
  });
}
