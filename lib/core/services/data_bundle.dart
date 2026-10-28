// Data bundle codec for the Forge application.
//
// Export, import and backup all speak one file format: a versioned JSON
// envelope carrying a [DataSnapshot], an app version, creation time and a
// checksum over the payload. [DataBundleCodec] encodes/decodes that
// envelope, computes and verifies checksums, and (de)compresses with gzip
// for compact backup files.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import '../utils/ids.dart';
import 'data_registry.dart';
import 'error_handling/forge_failures.dart';
import 'error_handling/result.dart';

/// Runtime metadata about the Forge application.
abstract final class ForgeAppInfo {
  ForgeAppInfo._();

  /// The app version string written into bundles (matches pubspec).
  static const String version = '1.0.0';
}

/// A versioned envelope around a [DataSnapshot].
class ForgeDataBundle {
  /// Creates a bundle.
  const ForgeDataBundle({
    required this.format,
    required this.formatVersion,
    required this.appVersion,
    required this.createdAt,
    required this.checksum,
    required this.snapshot,
  });

  /// The format name (see [ForgeDataFormat.name]).
  final String format;

  /// The payload format version.
  final int formatVersion;

  /// The app version that produced the payload.
  final String appVersion;

  /// When the payload was created.
  final DateTime createdAt;

  /// SHA-256 hex digest of the canonical snapshot JSON.
  final String checksum;

  /// The payload itself.
  final DataSnapshot snapshot;

  /// Serializes to a JSON-safe map.
  Map<String, dynamic> toJson() => {
        'format': format,
        'formatVersion': formatVersion,
        'appVersion': appVersion,
        'createdAt': toIsoString(createdAt),
        'checksum': checksum,
        'data': snapshot.toJson(),
      };

  /// Deserializes from a map produced by [toJson].
  factory ForgeDataBundle.fromJson(Map<String, dynamic> json) {
    return ForgeDataBundle(
      format: json['format'] as String? ?? ForgeDataFormat.name,
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 0,
      appVersion: json['appVersion'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? parseIsoDate(json['createdAt'] as String)
          : DateTime.now(),
      checksum: json['checksum'] as String? ?? '',
      snapshot: DataSnapshot.fromJson(
        (json['data'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}

/// Encodes, validates and compresses [ForgeDataBundle]s.
abstract final class DataBundleCodec {
  DataBundleCodec._();

  /// Canonical JSON bytes for [snapshot] (the checksummed payload).
  static Uint8List snapshotBytes(DataSnapshot snapshot) => Uint8List.fromList(
        utf8.encode(jsonEncode(snapshot.toJson())),
      );

  /// SHA-256 hex digest of the canonical snapshot JSON.
  static String checksumOf(DataSnapshot snapshot) =>
      sha256.convert(snapshotBytes(snapshot)).toString();

  /// Builds a bundle for [snapshot] with its checksum filled in.
  static ForgeDataBundle build(DataSnapshot snapshot) {
    return ForgeDataBundle(
      format: ForgeDataFormat.name,
      formatVersion: ForgeDataFormat.version,
      appVersion: ForgeAppInfo.version,
      createdAt: snapshot.createdAt,
      checksum: checksumOf(snapshot),
      snapshot: snapshot,
    );
  }

  /// Encodes [bundle] into UTF-8 JSON bytes.
  static Uint8List encode(ForgeDataBundle bundle) =>
      Uint8List.fromList(utf8.encode(jsonEncode(bundle.toJson())));

  /// Decodes [bytes] into a bundle, validating structure and checksum.
  ///
  /// Returns a [ValidationFailure] when the envelope is malformed, the
  /// format is unknown or the checksum does not match the payload.
  static Result<ForgeDataBundle> decode(Uint8List bytes) =>
      Result.trySync<ForgeDataBundle>(() {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Bundle root must be a JSON object');
        }
        final bundle = ForgeDataBundle.fromJson(decoded);

        if (bundle.format != ForgeDataFormat.name) {
          throw ValidationFailure('Unsupported data format: ${bundle.format}');
        }
        if (bundle.formatVersion > ForgeDataFormat.version) {
          throw ValidationFailure(
            'Bundle version ${bundle.formatVersion} is newer than supported '
            '${ForgeDataFormat.version}.',
          );
        }
        if (bundle.checksum != checksumOf(bundle.snapshot)) {
          throw ValidationFailure('Bundle checksum mismatch; data may be corrupt.');
        }
        return bundle;
      });

  /// Compresses [bytes] with gzip.
  static Uint8List compress(Uint8List bytes) => Uint8List.fromList(
        gzip.encode(bytes),
      );

  /// Whether [bytes] carry a gzip stream (magic bytes `1F 8B`).
  static bool isGzip(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B;

  /// Decompresses gzip [bytes]; raw (uncompressed) input passes through.
  static Result<Uint8List> decompress(Uint8List bytes) => Result.trySync(
        () => Uint8List.fromList(gzip.decode(bytes)),
      );
}
