// Backup engine for the Forge application.
//
// Writes the whole dataset to a timestamped file in a backups directory and
// restores it. Backups reuse the [ForgeDataBundle] envelope; the payload is
// optionally gzip-compressed and the manifest carries a checksum so a
// corrupt or foreign file is refused before anything is overwritten.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../data_bundle.dart';
import '../data_registry.dart';
import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// Describes a backup file that has passed validation.
class BackupManifest {
  /// Creates a manifest.
  const BackupManifest({
    required this.bundle,
    required this.compressed,
    required this.recordCount,
  });

  /// The validated bundle.
  final ForgeDataBundle bundle;

  /// Whether the on-disk payload is gzip-compressed.
  final bool compressed;

  /// Number of records in the backup.
  final int recordCount;

  /// The checksum recorded in the bundle.
  String get checksum => bundle.checksum;

  /// The file format name.
  String get format => bundle.format;

  /// The payload format version.
  int get formatVersion => bundle.formatVersion;

  /// When the backup was created.
  DateTime get createdAt => bundle.createdAt;
}

/// The result of creating a backup.
class BackupResult {
  /// Creates a result.
  const BackupResult({required this.file, required this.manifest});

  /// Where the backup was written.
  final File file;

  /// Metadata for the written backup.
  final BackupManifest manifest;
}

/// The result of restoring a backup.
class RestoreReport {
  /// Creates a report.
  const RestoreReport({required this.recordCount, required this.restoredAt});

  /// Number of records restored.
  final int recordCount;

  /// When the restore finished.
  final DateTime restoredAt;
}

/// Creates, validates and restores whole-dataset backups.
class BackupEngine {
  /// Creates a backup engine over [source].
  ///
  /// [directory] is the backups folder; when null, the app documents
  /// directory's `backups` subfolder is used.
  BackupEngine(this._source, {Directory? directory, ForgeLogger? logger})
      : _directory = directory,
        _logger = logger;

  final DataSnapshotSource _source;
  final Directory? _directory;
  final ForgeLogger? _logger;

  /// Extension for uncompressed backups.
  static const String jsonExtension = 'forgebak';

  /// Extension for gzip-compressed backups.
  static const String gzipExtension = 'forgebak.gz';

  /// Captures the dataset and writes it to a fresh backup file.
  Future<Result<BackupResult>> create({bool compress = false}) =>
      Result.tryAsync<BackupResult>(
        () async {
          final snapshot = await _source.capture();
          final bundle = DataBundleCodec.build(snapshot);
          var bytes = DataBundleCodec.encode(bundle);
          if (compress) bytes = DataBundleCodec.compress(bytes);

          final directory = _directory ?? await _defaultBackupDirectory();
          await directory.create(recursive: true);
          final file = File(
            '${directory.path}${Platform.pathSeparator}'
            '${_fileName(bundle.createdAt, compressed: compress)}',
          );
          await file.writeAsBytes(bytes);

          return BackupResult(
            file: file,
            manifest: BackupManifest(
              bundle: bundle,
              compressed: compress,
              recordCount: _recordCount(snapshot),
            ),
          );
        },
        classify: _backupFailure,
      );

  /// Reads [file] and verifies format, version and checksum.
  Future<Result<BackupManifest>> validate(File file) =>
      Result.tryAsync<BackupManifest>(
        () async {
          final bytes = await file.readAsBytes();
          return _decodeOrThrow(bytes);
        },
        classify: _backupFailure,
      );

  /// Validates [file] and, when valid, overwrites storage with its contents.
  Future<Result<RestoreReport>> restore(File file) =>
      Result.tryAsync<RestoreReport>(
        () async {
          final manifest = await validate(file);
          if (manifest.isFailure) throw manifest.failureOrNull!;
          final snapshot = manifest.valueOrNull!.bundle.snapshot;
          await _source.apply(snapshot);
          return RestoreReport(
            recordCount: manifest.valueOrNull!.recordCount,
            restoredAt: DateTime.now(),
          );
        },
        classify: _backupFailure,
      );

  BackupManifest _decodeOrThrow(Uint8List bytes) {
    final raw = DataBundleCodec.isGzip(bytes) ? _decompressOrThrow(bytes) : bytes;
    final decoded = DataBundleCodec.decode(raw);
    if (decoded.isFailure) throw decoded.failureOrNull!;
    final bundle = decoded.valueOrNull!;
    return BackupManifest(
      bundle: bundle,
      compressed: DataBundleCodec.isGzip(bytes),
      recordCount: _recordCount(bundle.snapshot),
    );
  }

  Uint8List _decompressOrThrow(Uint8List bytes) {
    final result = DataBundleCodec.decompress(bytes);
    if (result.isFailure) throw result.failureOrNull!;
    return result.valueOrNull!;
  }

  int _recordCount(DataSnapshot snapshot) => snapshot.boxes.values
      .fold(0, (sum, records) => sum + records.length);

  String _fileName(DateTime createdAt, {required bool compressed}) {
    final stamp = createdAt.toLocal().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return 'forge_backup_$stamp.${compressed ? gzipExtension : jsonExtension}';
  }

  Future<Directory> _defaultBackupDirectory() async {
    final documents = await _documentsDirectory();
    return Directory('${documents.path}${Platform.pathSeparator}backups');
  }

  Future<Directory> _documentsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(documents.path);
  }

  ForgeFailure _backupFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Backup operation failed', error, stackTrace);
    return switch (error) {
      ForgeFailure() => BackupFailure(error.message, cause: error),
      FileSystemException() => BackupFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
