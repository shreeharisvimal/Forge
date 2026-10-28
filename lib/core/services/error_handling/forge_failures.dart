// Typed failure hierarchy for the Forge application.
//
// Every recoverable operation surfaces failures as a typed [ForgeFailure]
// instead of throwing raw exceptions. Each failure carries a stable machine
// `code`, a human-readable `message` and the optional root `cause`, so UI
// code can branch on the type while logging keeps the original exception.
library;

import 'dart:io' show FileSystemException;

import 'package:flutter/foundation.dart' show FlutterError;

import '../../../database/database_service.dart' show DatabaseException;

/// Base class for every typed failure in Forge.
///
/// Failures are sealed through this base: switch statements over the
/// subclass set are exhaustive and the compiler keeps them up to date.
sealed class ForgeFailure {
  /// Creates a failure.
  const ForgeFailure(this.message, {required this.code, this.cause});

  /// Stable machine-readable code (e.g. `'storage'`, `'backup'`).
  final String code;

  /// Human-readable description safe to show to users.
  final String message;

  /// The original error, when one is available.
  final Object? cause;

  /// Returns the failure as a formatted string.
  @override
  String toString() =>
      cause == null ? '$code: $message' : '$code: $message\n$cause';
}

/// An input failed validation.
class ValidationFailure extends ForgeFailure {
  /// Creates a validation failure.
  const ValidationFailure(super.message, {super.cause})
      : super(code: 'validation');
}

/// Storage initialization or box access failed.
class StorageFailure extends ForgeFailure {
  /// Creates a storage failure.
  const StorageFailure(super.message, {super.cause}) : super(code: 'storage');
}

/// A file-system operation failed.
class FileFailure extends ForgeFailure {
  /// Creates a file failure.
  const FileFailure(super.message, {super.cause}) : super(code: 'file');
}

/// A backup operation failed.
class BackupFailure extends ForgeFailure {
  /// Creates a backup failure.
  const BackupFailure(super.message, {super.cause}) : super(code: 'backup');
}

/// An import operation failed.
class ImportFailure extends ForgeFailure {
  /// Creates an import failure.
  const ImportFailure(super.message, {super.cause}) : super(code: 'import');
}

/// An export operation failed.
class ExportFailure extends ForgeFailure {
  /// Creates an export failure.
  const ExportFailure(super.message, {super.cause}) : super(code: 'export');
}

/// An image-processing operation failed.
class ImageFailure extends ForgeFailure {
  /// Creates an image failure.
  const ImageFailure(super.message, {super.cause}) : super(code: 'image');
}

/// A permission was denied by the user or the OS.
class PermissionDeniedFailure extends ForgeFailure {
  /// Creates a permission-denied failure.
  const PermissionDeniedFailure(super.message, {super.cause})
      : super(code: 'permission_denied');
}

/// The device is offline and the operation requires connectivity.
class ConnectivityFailure extends ForgeFailure {
  /// Creates a connectivity failure.
  const ConnectivityFailure(super.message, {super.cause})
      : super(code: 'connectivity');
}

/// A notification operation failed.
class NotificationFailure extends ForgeFailure {
  /// Creates a notification failure.
  const NotificationFailure(super.message, {super.cause})
      : super(code: 'notification');
}

/// A share operation failed.
class ShareFailure extends ForgeFailure {
  /// Creates a share failure.
  const ShareFailure(super.message, {super.cause}) : super(code: 'share');
}

/// A clipboard operation failed.
class ClipboardFailure extends ForgeFailure {
  /// Creates a clipboard failure.
  const ClipboardFailure(super.message, {super.cause})
      : super(code: 'clipboard');
}

/// A device-information query failed.
class DeviceFailure extends ForgeFailure {
  /// Creates a device failure.
  const DeviceFailure(super.message, {super.cause}) : super(code: 'device');
}

/// An unexpected, unmapped error occurred.
class UnknownFailure extends ForgeFailure {
  /// Creates an unknown failure.
  const UnknownFailure(super.message, {super.cause}) : super(code: 'unknown');
}

/// Maps framework and platform exceptions onto the failure hierarchy.
abstract final class FailureMapper {
  FailureMapper._();

  /// Converts [error] into a [ForgeFailure].
  ///
  /// Known exception types map onto their natural failure; everything else
  /// becomes an [UnknownFailure] carrying the original error as [cause].
  static ForgeFailure toFailure(Object error, {StackTrace? stackTrace}) {
    return switch (error) {
      ForgeFailure() => error,
      FileSystemException() =>
        FileFailure(error.message, cause: error),
      FormatException() =>
        ValidationFailure('Malformed input: ${error.message}', cause: error),
      DatabaseException() => StorageFailure(error.message, cause: error),
      FlutterError() => UnknownFailure(error.message, cause: error),
      _ => UnknownFailure('$error', cause: error),
    };
  }
}
