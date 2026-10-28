// Tests for the app lifecycle service.
//
// Lifecycle transitions are driven both directly and through the binding so
// the deduplication and observer wiring are both covered.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/lifecycle/app_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleService', () {
    test('emits resumed on didChangeAppLifecycleState', () async {
      final service = AppLifecycleService();
      final events = <AppLifecycleEvent>[];
      final subscription = service.events.listen(events.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, [AppLifecycleEvent.resumed]);

      await subscription.cancel();
    });

    test('deduplicates identical state transitions', () async {
      final service = AppLifecycleService();
      final events = <AppLifecycleEvent>[];
      final subscription = service.events.listen(events.add);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);

      expect(
        events,
        [AppLifecycleEvent.resumed, AppLifecycleEvent.inactive],
      );

      await subscription.cancel();
    });

    test('tracks state flags and wasPaused', () async {
      final service = AppLifecycleService();
      expect(service.isForeground, isFalse);
      expect(service.isBackground, isFalse);
      expect(service.wasPaused, isFalse);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.state, AppLifecycleState.resumed);
      expect(service.isForeground, isTrue);
      expect(service.isBackground, isFalse);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isForeground, isFalse);
      expect(service.isBackground, isTrue);
      expect(service.wasPaused, isTrue);
    });

    test('convenience streams emit the matching events', () async {
      final service = AppLifecycleService();
      var resumedCount = 0;
      var pausedCount = 0;
      var detachedCount = 0;
      final resumedSub = service.resumed.listen((_) => resumedCount++);
      final pausedSub = service.paused.listen((_) => pausedCount++);
      final detachedSub = service.detached.listen((_) => detachedCount++);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      service.didChangeAppLifecycleState(AppLifecycleState.detached);
      await Future<void>.delayed(Duration.zero);

      expect(resumedCount, 2);
      expect(pausedCount, 1);
      expect(detachedCount, 1);

      await resumedSub.cancel();
      await pausedSub.cancel();
      await detachedSub.cancel();
    });

    test('attached service receives lifecycle changes from the binding',
        () async {
      final service = AppLifecycleService();
      final events = <AppLifecycleEvent>[];
      final subscription = service.events.listen(events.add);

      service.attach();
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      service.detach();

      expect(events, [AppLifecycleEvent.resumed]);

      await subscription.cancel();
    });

    test('attach is idempotent and detach removes the observer', () async {
      final service = AppLifecycleService();
      final events = <AppLifecycleEvent>[];
      final subscription = service.events.listen(events.add);

      service.attach();
      service.attach();
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(events, [AppLifecycleEvent.resumed]);

      service.detach();
      service.detach();
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      expect(events, [AppLifecycleEvent.resumed]);

      await subscription.cancel();
    });
  });

  group('AppLifecycleObserver', () {
    testWidgets('attaches and detaches without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(home: AppLifecycleObserver()),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
