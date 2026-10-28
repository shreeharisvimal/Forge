// Widget tests for the Forge global dialog system.
//
// Verifies the typed dialogs (confirm, delete, info, input, selection and
// progress) present glass content and resolve with the expected values.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/dialogs/forge_dialogs.dart';
import 'package:forge/core/design/theme/forge_theme.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required Future<void> Function(BuildContext context) onPressed,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ForgeTheme.dark(),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => onPressed(context),
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('confirm dialog resolves true when confirmed',
      (WidgetTester tester) async {
    bool? result;
    await pumpHarness(tester, onPressed: (context) async {
      result = await showForgeConfirmDialog(
        context,
        title: 'Are you sure?',
        confirmLabel: 'Yes',
      );
    });

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('confirm dialog resolves null when cancelled',
      (WidgetTester tester) async {
    bool? result = true;
    await pumpHarness(tester, onPressed: (context) async {
      result = await showForgeConfirmDialog(
        context,
        title: 'Are you sure?',
      );
    });

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // A dismissed dialog resolves with `null` (not confirmed).
    expect(result, isNull);
  });

  testWidgets('input dialog resolves the entered value',
      (WidgetTester tester) async {
    String? result;
    await pumpHarness(tester, onPressed: (context) async {
      result = await showForgeInputDialog(
        context,
        title: 'New name',
        hintText: 'Enter a name',
      );
    });

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Leg Day');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, 'Leg Day');
  });

  testWidgets('selection dialog resolves the chosen option',
      (WidgetTester tester) async {
    String? result;
    await pumpHarness(tester, onPressed: (context) async {
      result = await showForgeSelectionDialog<String>(
        context,
        title: 'Choose unit',
        options: const [
          ForgeSelectionOption<String>(label: 'Kilograms', value: 'kg'),
          ForgeSelectionOption<String>(label: 'Pounds', value: 'lb'),
        ],
      );
    });

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Choose unit'), findsOneWidget);
    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();

    expect(result, 'lb');
  });

  testWidgets('delete dialog shows destructive confirm',
      (WidgetTester tester) async {
    bool? result;
    await pumpHarness(tester, onPressed: (context) async {
      result = await showForgeDeleteDialog(
        context,
        title: 'Delete workout?',
        message: 'This cannot be undone.',
      );
    });

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Delete workout?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('progress dialog can be updated and dismissed',
      (WidgetTester tester) async {
    ForgeProgressDialogController? controller;
    await pumpHarness(tester, onPressed: (context) async {
      controller = await showForgeProgressDialog(context, message: 'Working…');
    });

    await tester.tap(find.text('Trigger'));
    await tester.pump();
    // The dialog hosts an infinitely repeating spinner, so pumpAndSettle
    // never settles; advance the entrance transition explicitly.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Working…'), findsOneWidget);

    controller?.update(message: 'Almost done', progress: 0.8);
    await tester.pump();
    expect(find.text('Almost done'), findsOneWidget);

    controller?.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Almost done'), findsNothing);
  });
}
