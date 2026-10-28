// Permission service for the Forge application.
//
// Forge hides the permission_handler plugin behind a thin, mockable
// [PermissionService] so feature code never touches platform APIs directly.
// [PluginPermissionHandler] owns the mapping between [ForgePermission] and the
// plugin's [Permission]; tests inject a fake handler instead. On Android the
// photos/storage permissions map onto the platform's storage/media grants.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../error_handling/forge_failures.dart';

/// A capability the app may request access to.
enum ForgePermission {
  /// Access to the device photo library / media storage.
  photos,

  /// Access to external storage.
  storage,

  /// Permission to post notifications.
  notifications,

  /// Access to the device camera. Future-ready: not exercised until the
  /// camera-backed features exist.
  camera,

  /// Access to Bluetooth. Future-ready: not exercised until the
  /// Bluetooth-backed features exist.
  bluetooth,
}

/// The resolved state of a [ForgePermission].
enum ForgePermissionStatus {
  /// The user granted full access.
  granted,

  /// The user denied access.
  denied,

  /// Access was denied and cannot be re-requested without app settings.
  permanentlyDenied,

  /// The OS restricts access and the user cannot change it.
  restricted,

  /// Access was granted with limits (e.g. a photo-picker subset).
  limited,

  /// The status could not be determined.
  unknown,
}

/// The outcome of a permission check or request.
class PermissionResult {
  /// Creates a permission result.
  const PermissionResult(this.permission, this.status);

  /// The permission that was queried.
  final ForgePermission permission;

  /// The resolved status.
  final ForgePermissionStatus status;

  /// Whether access was granted in full.
  bool get isGranted => status == ForgePermissionStatus.granted;

  /// Whether the user actively denied access.
  bool get isDenied => status == ForgePermissionStatus.denied;

  /// Returns a formatted string for the result.
  @override
  String toString() => 'PermissionResult($permission: $status)';
}

/// Checks and requests permissions for the app.
///
/// Callers should wrap [requestOrFail] in [Result.tryAsync] when a permission
/// is required to proceed. For optional permissions, check
/// [PermissionResult.isDenied] and surface a friendly message; the
/// ForgeOverlay/toast layer can display it.
abstract class PermissionService {
  /// Returns the current status of [permission] without prompting.
  Future<PermissionResult> check(ForgePermission permission);

  /// Prompts the user for [permission] and returns the resolved status.
  Future<PermissionResult> request(ForgePermission permission);

  /// Requests [permission] and throws [PermissionDeniedFailure] when the
  /// result is not fully granted, so callers can use it with [Result.tryAsync].
  Future<PermissionResult> requestOrFail(ForgePermission permission);
}

/// The plugin-facing half of the permission stack, mockable in tests.
abstract class PermissionHandler {
  /// Returns the plugin status of [permission] without prompting.
  Future<PermissionStatus> check(ForgePermission permission);

  /// Prompts for [permission] and returns the plugin status.
  Future<PermissionStatus> request(ForgePermission permission);
}

/// The real [PermissionHandler] backed by permission_handler.
class PluginPermissionHandler implements PermissionHandler {
  /// Creates the plugin-backed handler.
  const PluginPermissionHandler();

  @override
  Future<PermissionStatus> check(ForgePermission permission) =>
      mapPermission(permission).status;

  @override
  Future<PermissionStatus> request(ForgePermission permission) =>
      mapPermission(permission).request();

  /// Maps a plugin [PermissionStatus] onto [ForgePermissionStatus].
  ///
  /// `provisional` (iOS provisional notifications) counts as granted;
  /// anything unmapped becomes [ForgePermissionStatus.unknown].
  static ForgePermissionStatus mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => ForgePermissionStatus.granted,
      PermissionStatus.provisional => ForgePermissionStatus.granted,
      PermissionStatus.denied => ForgePermissionStatus.denied,
      PermissionStatus.permanentlyDenied =>
        ForgePermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => ForgePermissionStatus.restricted,
      PermissionStatus.limited => ForgePermissionStatus.limited,
    };
  }

  /// Maps [ForgePermission] onto the plugin's [Permission].
  static Permission mapPermission(ForgePermission permission) {
    return switch (permission) {
      ForgePermission.photos => Permission.photos,
      ForgePermission.storage => Permission.storage,
      ForgePermission.notifications => Permission.notification,
      ForgePermission.camera => Permission.camera,
      ForgePermission.bluetooth => Permission.bluetooth,
    };
  }
}

/// [PermissionService] that delegates to the permission_handler plugin.
class SystemPermissionService implements PermissionService {
  /// Creates a service backed by [handler] (the plugin by default).
  SystemPermissionService([PermissionHandler? handler])
      : _handler = handler ?? const PluginPermissionHandler();

  final PermissionHandler _handler;

  @override
  Future<PermissionResult> check(ForgePermission permission) async {
    final status = await _handler.check(permission);
    return PermissionResult(permission, PluginPermissionHandler.mapStatus(status));
  }

  @override
  Future<PermissionResult> request(ForgePermission permission) async {
    final status = await _handler.request(permission);
    return PermissionResult(permission, PluginPermissionHandler.mapStatus(status));
  }

  @override
  Future<PermissionResult> requestOrFail(ForgePermission permission) async {
    final result = await request(permission);
    if (!result.isGranted) {
      throw PermissionDeniedFailure(
        '${permission.name} permission was not granted',
      );
    }
    return result;
  }
}

/// Provides the app-wide [PermissionService].
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => SystemPermissionService(),
);
