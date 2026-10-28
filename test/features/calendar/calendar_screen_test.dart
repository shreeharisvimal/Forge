// Widget tests for the calendar screen.
//
// Pumps the real [CalendarScreen] against a temp-dir Hive store with a pinned
// clock and verifies the grid renders, seeded days surface in the summary
// card, day taps open the detail sheet, and the format switch collapses the
// grid to the current week.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/forge_design.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/calendar/calendar_screen.dart';
import 'package:forge/features/calendar/providers/calendar_providers.dart';
import 'package:forge/features/calendar/widgets/calendar_marker_badges.dart';
import 'package:forge/models/calendar_day.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';

void main() {
  late Directory tempDir;
  late DatabaseService databaseService;

  final pinnedNow = DateTime(2026, 2, 4, 9);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forge_test');
    databaseService = await DatabaseService.initialize(directory: tempDir.path);
  });

  tearDown(() async {
    await databaseService.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpCalendar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(databaseService),
          calendarNowProvider.overrideWithValue(pinnedNow),
        ],
        child: MaterialApp(
          theme: ForgeTheme.dark(),
          home: const CalendarScreen(),
        ),
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

  testWidgets('renders the grid, header and format control', (tester) async {
    await useTallSurface(tester);
    await pumpCalendar(tester);

    expect(find.text('February 2026'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('2 weeks'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);

    final todayCell = find.text('4');
    expect(todayCell, findsWidgets);
  });

  testWidgets('shows the empty-state summary for the selected day',
      (tester) async {
    await useTallSurface(tester);
    await pumpCalendar(tester);

    expect(find.text('Wed, Feb 4'), findsOneWidget);
    expect(
      find.text('Nothing logged yet — tap to add weight, sleep, water or notes.'),
      findsOneWidget,
    );
  });

  testWidgets('seeded day surfaces stats and markers in the summary card',
      (tester) async {
    await useTallSurface(tester);

    await tester.runAsync(() async {
      final calendar = HiveCalendarRepository(databaseService.calendarBox);
      await calendar.save(CalendarDay(
        date: DateTime(2026, 2, 4),
        weight: 82,
        sleepHours: 7.5,
        mood: 4,
      ));
      final weights = HiveWeightRepository(databaseService.weightBox);
      await weights.save(WeightEntry(date: DateTime(2026, 2, 3), weight: 81.5));
    });

    await pumpCalendar(tester);

    expect(find.text('82.0 kg'), findsOneWidget);
    expect(find.text('7.5 h'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.byType(CalendarMarkerBadges), findsWidgets);
  });

  testWidgets('tapping a day opens the detail sheet', (tester) async {
    await useTallSurface(tester);
    await pumpCalendar(tester);

    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();

    expect(find.text('Saturday, February 14, 2026'), findsOneWidget);
    expect(find.text('Progress photos'), findsOneWidget);
    expect(find.text('Everything saves automatically'), findsOneWidget);
  });

  testWidgets('switching to the week format collapses the grid', (tester) async {
    await useTallSurface(tester);
    await pumpCalendar(tester);

    expect(find.text('28'), findsWidgets, reason: 'Jan 28 and Feb 28 are visible');

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('28'), findsNothing, reason: 'week view only spans Feb 2-8');
    expect(find.text('4'), findsWidgets);
  });
}
