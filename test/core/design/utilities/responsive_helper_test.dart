// Tests for the Forge responsive design helpers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/utilities/responsive_helper.dart';

void main() {
  Future<BuildContext> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('classifies compact layouts under 600dp', (tester) async {
    final context = await pumpAtSize(tester, const Size(400, 800));

    expect(Responsive.breakpointOf(context), ForgeBreakpoint.compact);
    expect(Responsive.isCompact(context), isTrue);
    expect(Responsive.isMedium(context), isFalse);
    expect(Responsive.isExpanded(context), isFalse);
    expect(Responsive.shouldShowNavRail(context), isFalse);
  });

  testWidgets('classifies medium layouts from 600dp up to 840dp',
      (tester) async {
    final context = await pumpAtSize(tester, const Size(700, 900));

    expect(Responsive.breakpointOf(context), ForgeBreakpoint.medium);
    expect(Responsive.isCompact(context), isFalse);
    expect(Responsive.isMedium(context), isTrue);
    expect(Responsive.isExpanded(context), isFalse);
    expect(Responsive.shouldShowNavRail(context), isFalse);
  });

  testWidgets('classifies expanded layouts above 840dp and shows the nav rail',
      (tester) async {
    final context = await pumpAtSize(tester, const Size(1200, 900));

    expect(Responsive.breakpointOf(context), ForgeBreakpoint.expanded);
    expect(Responsive.isCompact(context), isFalse);
    expect(Responsive.isMedium(context), isFalse);
    expect(Responsive.isExpanded(context), isTrue);
    expect(Responsive.shouldShowNavRail(context), isTrue);
    expect(Responsive.isNavRail(context), isTrue);
  });

  testWidgets('shows the nav rail only at or above the 900dp threshold',
      (tester) async {
    var context = await pumpAtSize(tester, const Size(899, 1000));
    expect(Responsive.shouldShowNavRail(context), isFalse);

    context = await pumpAtSize(tester, const Size(900, 1000));
    expect(Responsive.shouldShowNavRail(context), isTrue);
  });

  testWidgets('spacingScale scales up on larger breakpoints', (tester) async {
    var context = await pumpAtSize(tester, const Size(400, 800));
    expect(Responsive.spacingScale(context), 1);
    expect(
      Responsive.spacingScale(context, compact: 0.5, medium: 1, expanded: 2),
      0.5,
    );

    context = await pumpAtSize(tester, const Size(700, 900));
    expect(Responsive.spacingScale(context), 1.25);
    expect(
      Responsive.spacingScale(context, compact: 0.5, medium: 1, expanded: 2),
      1,
    );

    context = await pumpAtSize(tester, const Size(1200, 900));
    expect(Responsive.spacingScale(context), 1.5);
    expect(
      Responsive.spacingScale(context, compact: 0.5, medium: 1, expanded: 2),
      2,
    );
  });

  testWidgets('columns adapts the layout grid to the breakpoint',
      (tester) async {
    var context = await pumpAtSize(tester, const Size(400, 800));
    expect(Responsive.columns(context), 1);
    expect(Responsive.columns(context, compact: 2, medium: 3, expanded: 4), 2);

    context = await pumpAtSize(tester, const Size(700, 900));
    expect(Responsive.columns(context), 2);
    expect(Responsive.columns(context, compact: 2, medium: 3, expanded: 4), 3);

    context = await pumpAtSize(tester, const Size(1200, 900));
    expect(Responsive.columns(context), 3);
    expect(Responsive.columns(context, compact: 2, medium: 3, expanded: 4), 4);
  });
}
