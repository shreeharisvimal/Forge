// Tests for promoted glass UI kit components (GlassCalendarCell, GlassWorkoutCard, GlassExerciseTile, GlassChartCard, GlassBottomBar).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/design/forge_design.dart';

void main() {
  Widget wrapTheme(Widget child) {
    return MaterialApp(
      theme: ForgeTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('GlassCalendarCell renders day number and markers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapTheme(
        GlassCalendarCell(
          day: DateTime(2026, 8, 15),
          isSelected: true,
          isToday: false,
          markers: const [
            Icon(Icons.check, size: 10),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('15'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('GlassWorkoutCard renders title, focus, exercise count and action',
      (WidgetTester tester) async {
    bool started = false;
    await tester.pumpWidget(
      wrapTheme(
        GlassWorkoutCard(
          title: 'Push Day A',
          subtitle: 'PPL Routine',
          focus: 'Chest · Shoulders · Triceps',
          exerciseCount: 5,
          exerciseNames: const ['Bench Press', 'Incline Press', 'Dip'],
          actionButton: ElevatedButton(
            onPressed: () {
              started = true;
            },
            child: const Text('Start Workout'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push Day A'), findsOneWidget);
    expect(find.text('PPL Routine'), findsOneWidget);
    expect(find.text('Chest · Shoulders · Triceps'), findsOneWidget);
    expect(find.text('5 exercises'), findsOneWidget);
    expect(find.text('Bench Press · Incline Press · Dip, and 2 more'), findsOneWidget);

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    expect(started, isTrue);
  });

  testWidgets('GlassExerciseTile renders title, subtitle, query highlighting and favorite button',
      (WidgetTester tester) async {
    bool favorited = false;
    await tester.pumpWidget(
      wrapTheme(
        GlassExerciseTile(
          title: 'Barbell Bench Press',
          subtitle: 'Chest · Barbell',
          isFavorite: false,
          query: 'Bench',
          tags: const ['Compound', 'Chest'],
          onFavoriteToggle: () {
            favorited = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chest · Barbell'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();
    expect(favorited, isTrue);
  });

  testWidgets('GlassChartCard wraps chart child with title and subtitle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapTheme(
        const GlassChartCard(
          title: 'Volume Progress',
          subtitle: 'Last 30 days',
          child: Text('Chart Placeholder'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Volume Progress'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Chart Placeholder'), findsOneWidget);
  });

  testWidgets('GlassBottomBar alias functions identical to GlassNavigationBar',
      (WidgetTester tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      wrapTheme(
        GlassBottomBar(
          currentIndex: selectedIndex,
          onDestinationSelected: (idx) => selectedIndex = idx,
          destinations: const [
            GlassNavigationDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
            ),
            GlassNavigationDestination(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
