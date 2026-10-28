// Tests for the permission service.
//
// The permission_handler plugin is never invoked here: [FakePermissionHandler]
// stands in for it, and [PluginPermissionHandler.mapStatus] is exercised
// directly against the plugin's [PermissionStatus] enum.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/permissions/permission_service.dart';

/// [PermissionHandler] stub returning a canned status per permission.
class FakePermissionHandler implements PermissionHandler {
  FakePermissionHandler(
    [Map<ForgePermission, PermissionStatus>? statusByPermission]
  ) : statusByPermission = statusByPermission ?? const {};

  final Map<ForgePermission, PermissionStatus> statusByPermission;

  /// The permissions passed to [check], in order.
  final List<ForgePermission> checked = [];

  /// The permissions passed to [request], in order.
  final List<ForgePermission> requested = [];

  @override
  Future<PermissionStatus> check(ForgePermission permission) async {
    checked.add(permission);
    return statusByPermission[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> request(ForgePermission permission) async {
    requested.add(permission);
    return statusByPermission[permission] ?? PermissionStatus.denied;
  }
}

void main() {
  group('PluginPermissionHandler.mapStatus', () {
    const mappings = <PermissionStatus, ForgePermissionStatus>{
      PermissionStatus.granted: ForgePermissionStatus.granted,
      PermissionStatus.provisional: ForgePermissionStatus.granted,
      PermissionStatus.denied: ForgePermissionStatus.denied,
      PermissionStatus.permanentlyDenied:
        ForgePermissionStatus.permanentlyDenied,
      PermissionStatus.restricted: ForgePermissionStatus.restricted,
      PermissionStatus.limited: ForgePermissionStatus.limited,
    };

    test('maps every plugin status onto the forge enum', () {
      for (final entry in mappings.entries) {
        expect(PluginPermissionHandler.mapStatus(entry.key), entry.value);
      }
    });
  });

  group('SystemPermissionService', () {
    test('check returns the resolved status without requesting', () async {
      final fake = FakePermissionHandler({
        ForgePermission.photos: PermissionStatus.granted,
      });
      final service = SystemPermissionService(fake);

      final result = await service.check(ForgePermission.photos);

      expect(fake.checked, [ForgePermission.photos]);
      expect(fake.requested, isEmpty);
      expect(result.permission, ForgePermission.photos);
      expect(result.status, ForgePermissionStatus.granted);
      expect(result.isGranted, isTrue);
      expect(result.isDenied, isFalse);
    });

    test('request returns the resolved status and records the permission',
        () async {
      final fake = FakePermissionHandler({
        ForgePermission.notifications: PermissionStatus.permanentlyDenied,
      });
      final service = SystemPermissionService(fake);

      final result = await service.request(ForgePermission.notifications);

      expect(fake.requested, [ForgePermission.notifications]);
      expect(result.status, ForgePermissionStatus.permanentlyDenied);
      expect(result.isGranted, isFalse);
      expect(result.isDenied, isFalse);
    });

    test('requestOrFail returns the result when granted', () async {
      final fake = FakePermissionHandler({
        ForgePermission.camera: PermissionStatus.granted,
      });
      final service = SystemPermissionService(fake);

      final result = await service.requestOrFail(ForgePermission.camera);

      expect(result.permission, ForgePermission.camera);
      expect(result.isGranted, isTrue);
    });

    test('requestOrFail throws PermissionDeniedFailure when denied', () async {
      final fake = FakePermissionHandler({
        ForgePermission.storage: PermissionStatus.denied,
      });
      final service = SystemPermissionService(fake);

      await expectLater(
        service.requestOrFail(ForgePermission.storage),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    });
  });
}
