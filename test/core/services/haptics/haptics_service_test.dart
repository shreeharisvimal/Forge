// Tests for the haptics service.
//
// A fake delegate records every call so the service can be verified without
// platform channels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/design/utilities/haptic_helper.dart';
import 'package:forge/core/services/haptics/haptics_service.dart';

void main() {
  group('HapticsService', () {
    test('fire delegates to the injected delegate', () async {
      final calls = <HapticType>[];
      final service = HapticsService(
        delegate: (type) async => calls.add(type),
      );

      await service.fire(HapticType.medium);

      expect(calls, [HapticType.medium]);
    });

    test('enabled=false turns every call into a no-op', () async {
      final calls = <HapticType>[];
      final service = HapticsService(
        delegate: (type) async => calls.add(type),
      );

      service.enabled = false;
      await service.fire(HapticType.heavy);
      await service.tap();
      await service.select();
      await service.success();
      await service.warning();
      await service.heavy();
      await service.medium();

      expect(calls, isEmpty);
    });

    test('tap() fires the light type', () async {
      final calls = <HapticType>[];
      final service = HapticsService(
        delegate: (type) async => calls.add(type),
      );

      await service.tap();

      expect(calls, [HapticType.light]);
    });

    test('shorthand methods fire their mapped types', () async {
      final calls = <HapticType>[];
      final service = HapticsService(
        delegate: (type) async => calls.add(type),
      );

      await service.select();
      await service.success();
      await service.warning();
      await service.heavy();
      await service.medium();

      expect(calls, [
        HapticType.selection,
        HapticType.success,
        HapticType.warning,
        HapticType.heavy,
        HapticType.medium,
      ]);
    });

    test('fire swallows delegate errors so fire-and-forget is safe', () async {
      final service = HapticsService(
        delegate: (type) async => throw Exception('boom'),
      );

      await expectLater(service.fire(HapticType.light), completes);
    });
  });
}
