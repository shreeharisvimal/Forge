// Export engine for the Forge application.
//
// Exports every boxed collection (settings, exercises, workouts, calendar,
// measurements, splits, PRs, sessions, history and weight) as a versioned,
// checksummed [ForgeDataBundle]. Callers receive the encoded bytes plus a
// per-box record count so the UI can confirm what was exported.
library;

import 'dart:io';
import 'dart:typed_data';

import '../data_bundle.dart';
import '../data_registry.dart';
import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// The result of an export.
class ForgeExport {
  /// Creates an export result.
  const ForgeExport({
    required this.bundle,
    required this.bytes,
    required this.recordCounts,
  });

  /// The versioned bundle.
  final ForgeDataBundle bundle;

  /// The encoded JSON bytes.
  final Uint8List bytes;

  /// Box name -> number of records exported.
  final Map<String, int> recordCounts;

  /// Total number of records exported.
  int get totalRecords =>
      recordCounts.values.fold(0, (sum, count) => sum + count);
}

/// Exports the whole dataset as a [ForgeDataBundle].
class ExportEngine {
  /// Creates an export engine over [source].
  ExportEngine(this._source, {ForgeLogger? logger}) : _logger = logger;

  final DataSnapshotSource _source;
  final ForgeLogger? _logger;

  /// Captures and encodes every boxed collection.
  Future<Result<ForgeExport>> export() => Result.tryAsync<ForgeExport>(
        () async {
          final snapshot = await _source.capture();
          final bundle = DataBundleCodec.build(snapshot);
          final bytes = DataBundleCodec.encode(bundle);
          return ForgeExport(
            bundle: bundle,
            bytes: bytes,
            recordCounts: {
              for (final entry in snapshot.boxes.entries)
                entry.key: entry.value.length,
            },
          );
        },
        classify: _exportFailure,
      );

  /// Exports and writes the encoded JSON to [file].
  Future<Result<ForgeExport>> exportTo(File file) => Result.tryAsync<ForgeExport>(
        () async {
          final result = await export();
          if (result.isFailure) throw result.failureOrNull!;
          await file.parent.create(recursive: true);
          await file.writeAsBytes(result.valueOrNull!.bytes);
          return result.valueOrNull!;
        },
        classify: _exportFailure,
      );

  ForgeFailure _exportFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Export failed', error, stackTrace);
    return switch (error) {
      ForgeFailure() => ExportFailure(error.message, cause: error),
      FileSystemException() => ExportFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
