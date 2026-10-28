// Golden test for the calendar screen.
//
// Renders the calendar in isolation against seeded February 2026 data and
// compares it to the committed golden. Run with `--update-goldens` to
// regenerate. The pinned clock keeps the grid, today highlight and summary
// card deterministic.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/theme/forge_theme.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/calendar/calendar_screen.dart';
import 'package:forge/features/calendar/providers/calendar_providers.dart';
import 'package:forge/services/providers.dart';

import 'calendar_test_data.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
    await seedCalendarData(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('calendar matches the seeded golden', (tester) async {
    tester.view.physicalSize = const Size(840, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
          calendarNowProvider.overrideWithValue(pinnedCalendarNow),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ForgeTheme.dark(),
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CalendarScreen),
      matchesGoldenFile('goldens/calendar_seeded.png'),
    );
  });
}
