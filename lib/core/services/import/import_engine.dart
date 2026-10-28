// Import engine for the Forge application.
//
// Validates a [ForgeDataBundle] (format, version, checksum, structure),
// optionally runs a migration hook, then merges its records into storage.
// Conflict handling is policy-driven: skip existing ids, overwrite them, or
// import them under fresh ids so nothing is lost.
library;

import 'dart:typed_data';

import '../data_bundle.dart';
import '../data_registry.dart';
import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';
import '../../utils/ids.dart';

/// How records whose ids already exist in storage are handled.
enum ImportConflictPolicy {
  /// Existing records are kept; conflicting imports are dropped.
  skip,

  /// Existing records are replaced by the imported values.
  overwrite,

  /// Conflicting imports are stored under freshly generated ids.
  rename,
}

/// Rewrites an imported snapshot before it is stored (e.g. format upgrades).
abstract class ImportMigrator {
  /// Returns [snapshot], possibly transformed.
  Future<DataSnapshot> migrate(DataSnapshot snapshot);
}

/// An [ImportMigrator] that leaves the snapshot unchanged.
class NoOpImportMigrator implements ImportMigrator {
  /// Creates a no-op migrator.
  const NoOpImportMigrator();

  @override
  Future<DataSnapshot> migrate(DataSnapshot snapshot) async => snapshot;
}

/// The outcome of validating a bundle without importing it.
class ImportValidation {
  /// Creates a validation result.
  const ImportValidation({
    required this.bundle,
    required this.recordCounts,
    required this.unknownBoxes,
  });

  /// The decoded bundle.
  final ForgeDataBundle bundle;

  /// Box name -> number of records in the bundle.
  final Map<String, int> recordCounts;

  /// Box names in the bundle that Forge does not recognize.
  final List<String> unknownBoxes;

  /// Total number of records in the bundle.
  int get totalRecords =>
      recordCounts.values.fold(0, (sum, count) => sum + count);
}

/// The result of applying a bundle to storage.
class ImportReport {
  /// Creates a report.
  ImportReport({
    this.added = 0,
    this.overwritten = 0,
    this.renamed = 0,
    this.skipped = 0,
    this.warnings = const [],
  });

  /// Records stored under ids that did not previously exist.
  int added;

  /// Existing records replaced.
  int overwritten;

  /// Conflicts stored under new ids.
  int renamed;

  /// Conflicting records dropped (skip policy).
  int skipped;

  /// Non-fatal problems found while importing.
  List<String> warnings;

  /// Records actually written to storage.
  int get appliedCount => added + overwritten + renamed;
}

/// Validates and merges [ForgeDataBundle]s into a [DataSnapshotSource].
class ImportEngine {
  /// Creates an import engine over [source].
  ImportEngine(this._source, {ForgeLogger? logger}) : _logger = logger;

  final DataSnapshotSource _source;
  final ForgeLogger? _logger;

  /// Decodes and structurally validates [bytes] without writing anything.
  Future<Result<ImportValidation>> validateBytes(Uint8List bytes) =>
      Result.tryAsync<ImportValidation>(
        () async {
          final bundle = _decodeOrThrow(bytes);
          final unknownBoxes = bundle.snapshot.boxes.keys
              .where((boxName) => ForgeDataRegistry.descriptorFor(boxName) == null)
              .toList();
          return ImportValidation(
            bundle: bundle,
            recordCounts: {
              for (final entry in bundle.snapshot.boxes.entries)
                entry.key: entry.value.length,
            },
            unknownBoxes: unknownBoxes,
          );
        },
        classify: _importFailure,
      );

  /// Validates [bytes] then imports them with [policy] and [migrator].
  Future<Result<ImportReport>> importBytes(
    Uint8List bytes, {
    ImportConflictPolicy policy = ImportConflictPolicy.overwrite,
    ImportMigrator migrator = const NoOpImportMigrator(),
  }) =>
      Result.tryAsync<ImportReport>(
        () async {
          final bundle = _decodeOrThrow(bytes);
          return _apply(bundle, policy: policy, migrator: migrator);
        },
        classify: _importFailure,
      );

  /// Imports an already-decoded [bundle] with [policy] and [migrator].
  Future<Result<ImportReport>> importBundle(
    ForgeDataBundle bundle, {
    ImportConflictPolicy policy = ImportConflictPolicy.overwrite,
    ImportMigrator migrator = const NoOpImportMigrator(),
  }) =>
      Result.tryAsync<ImportReport>(
        () => _apply(bundle, policy: policy, migrator: migrator),
        classify: _importFailure,
      );

  ForgeDataBundle _decodeOrThrow(Uint8List bytes) {
    final decoded = DataBundleCodec.decode(bytes);
    if (decoded.isFailure) throw decoded.failureOrNull!;
    return decoded.valueOrNull!;
  }

  Future<ImportReport> _apply(
    ForgeDataBundle bundle, {
    required ImportConflictPolicy policy,
    required ImportMigrator migrator,
  }) async {
    final migrated = await migrator.migrate(bundle.snapshot);
    final current = await _source.capture();
    final report = ImportReport();
    final applied = <String, Map<String, Map<String, dynamic>>>{};

    for (final boxEntry in migrated.boxes.entries) {
      final existing = current.boxes[boxEntry.key] ?? const {};
      final out = <String, Map<String, dynamic>>{};
      for (final record in boxEntry.value.entries) {
        if (existing.containsKey(record.key)) {
          switch (policy) {
            case ImportConflictPolicy.skip:
              report.skipped += 1;
              continue;
            case ImportConflictPolicy.rename:
              out[generateId()] = record.value;
              report.renamed += 1;
              continue;
            case ImportConflictPolicy.overwrite:
              report.overwritten += 1;
              break;
          }
        } else {
          report.added += 1;
        }
        out[record.key] = record.value;
      }
      if (out.isNotEmpty) applied[boxEntry.key] = out;
    }

    for (final boxName in migrated.boxes.keys) {
      if (ForgeDataRegistry.descriptorFor(boxName) == null) {
        report.warnings.add('Ignoring unknown box: $boxName');
      }
    }

    if (applied.isNotEmpty) {
      await _source.apply(DataSnapshot(boxes: applied, createdAt: DateTime.now()));
    }
    return report;
  }

  ForgeFailure _importFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Import failed', error, stackTrace);
    return switch (error) {
      ForgeFailure() => ImportFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
