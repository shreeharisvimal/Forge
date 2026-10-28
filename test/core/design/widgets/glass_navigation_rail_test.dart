// Tests for GlassNavigationRail.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/design/forge_design.dart';

void main() {
  Widget buildTestableRail({
    int currentIndex = 0,
    bool extended = true,
    ValueChanged<int>? onDestinationSelected,
    ValueChanged<bool>? onToggleExtended,
  }) {
    return MaterialApp(
      theme: ForgeTheme.dark(),
      home: Scaffold(
        body: GlassNavigationRail(
          currentIndex: currentIndex,
          extended: extended,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          onToggleExtended: onToggleExtended,
          leading: const Text('Forge Header'),
          destinations: const [
            GlassNavigationDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
            ),
            GlassNavigationDestination(
              label: 'Calendar',
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month_rounded,
              badge: '3',
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('renders destinations and header', (tester) async {
    await tester.pumpWidget(buildTestableRail());
    await tester.pumpAndSettle();

    expect(find.text('Forge Header'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('invokes onDestinationSelected when tapped', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(
      buildTestableRail(
        onDestinationSelected: (index) {
          selectedIndex = index;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(selectedIndex, equals(1));
  });

  testWidgets('shows the selected destination icon indicator',
      (tester) async {
    await tester.pumpWidget(buildTestableRail(currentIndex: 1));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsNothing);
  });

  testWidgets('collapses and expands via toggle button', (tester) async {
    bool? isExtendedState;
    await tester.pumpWidget(
      buildTestableRail(
        extended: true,
        onToggleExtended: (val) {
          isExtendedState = val;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    // Tap toggle button (collapse).
    await tester.tap(find.byTooltip('Collapse rail'));
    await tester.pumpAndSettle();

    expect(isExtendedState, isFalse);
    // Expanded labels are hidden while the rail is collapsed.
    expect(find.text('Home'), findsNothing);
    expect(find.text('Calendar'), findsNothing);

    // Toggle button flips to expand and restores the labels.
    await tester.tap(find.byTooltip('Expand rail'));
    await tester.pumpAndSettle();

    expect(isExtendedState, isTrue);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
  });
}
