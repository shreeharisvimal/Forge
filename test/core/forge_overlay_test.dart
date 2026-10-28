// Widget tests for the Forge overlay system.
//
// Exercises the global overlay layer through a minimal harness: a
// MaterialApp with the ForgeOverlayHost in its builder, so toasts, loading
// and progress entries render above content exactly as they do in the real
// app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/theme/forge_theme.dart';
import 'package:forge/core/design/widgets/glass_progress_bar.dart';
import 'package:forge/core/overlays/forge_overlay_controller.dart';
import 'package:forge/core/overlays/forge_overlay_extensions.dart';
import 'package:forge/core/overlays/forge_overlay_host.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required VoidCallback onPressed,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ForgeTheme.dark(),
          builder: (context, child) =>
              ForgeOverlayHost(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: onPressed,
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('toast appears and auto-dismisses', (WidgetTester tester) async {
    await pumpHarness(tester, onPressed: () {
      // ignore: use_build_context_synchronously
      tester.element(find.text('Trigger')).showToast('Saved!');
    });

    await tester.tap(find.text('Trigger'));
    await tester.pump();

    expect(find.text('Saved!'), findsOneWidget);

    // Auto-dismiss is a couple of seconds; advance past it.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Saved!'), findsNothing);
  });

  testWidgets('loading overlay future completes on dismissal',
      (WidgetTester tester) async {
    Future<void>? completed;
    await pumpHarness(tester, onPressed: () {
      final context = tester.element(find.text('Trigger'));
      // ignore: use_build_context_synchronously
      completed = context.showLoading('Syncing…');
    });

    await tester.tap(find.text('Trigger'));
    await tester.pump();

    expect(find.text('Syncing…'), findsOneWidget);
    expect(completed, isNotNull);

    // Loading overlays persist until explicitly dismissed.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Syncing…'), findsOneWidget);

    final controller = ProviderScope.containerOf(
      tester.element(find.text('Trigger')),
    ).read(forgeOverlayControllerProvider);
    controller.dismissAll();

    await tester.pump();
    await completed;
    expect(find.text('Syncing…'), findsNothing);
  });

  testWidgets('progress overlay updates and dismisses',
      (WidgetTester tester) async {
    int id = -1;
    await pumpHarness(tester, onPressed: () {
      final context = tester.element(find.text('Trigger'));
      // ignore: use_build_context_synchronously
      id = context.showProgress(title: 'Uploading', value: 0.0);
    });

    await tester.tap(find.text('Trigger'));
    await tester.pump();

    expect(find.text('Uploading'), findsOneWidget);
    expect(find.byType(GlassProgressBar), findsOneWidget);

    final context = tester.element(find.text('Trigger'));
    context.updateProgress(id, value: 0.5);
    await tester.pump();
    expect(find.text('Uploading'), findsOneWidget);

    context.dismissOverlay(id);
    await tester.pump();
    expect(find.text('Uploading'), findsNothing);
  });
}
