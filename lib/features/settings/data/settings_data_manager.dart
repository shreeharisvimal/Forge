// Settings data manager for the Forge application.
//
// The single orchestration point for the Data section of Settings. It wires
// the export, import and backup engines to the file system and the share
// service, so the screen only decides *what* to do while this layer decides
// *how* (file naming, directories, gzip handling and clipboard sharing).
// Every operation returns a typed [Result].
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/services/backup/backup_engine.dart';
import '../../../core/services/data_bundle.dart';
import '../../../core/services/error_handling/forge_failures.dart';
import '../../../core/services/error_handling/result.dart';
import '../../../core/services/export/export_engine.dart';
import '../../../core/services/file/file_service.dart';
import '../../../core/services/import/import_engine.dart';
import '../../../core/services/share/share_service.dart';

/// The outcome of exporting the dataset.
class SettingsExportSummary {
  /// Creates an export summary.
  const SettingsExportSummary({
    required this.export,
    required this.relativePath,
    required this.copiedToClipboard,
  });

  /// The produced export.
  final ForgeExport export;

  /// The path of the written file, relative to the app documents directory.
  final String relativePath;

  /// Whether the JSON payload was also copied to the clipboard.
  final bool copiedToClipboard;

  /// Total number of records exported.
  int get totalRecords => export.totalRecords;
}

/// Orchestrates export, import, backup and restore for the Settings tab.
class SettingsDataManager {
  /// Creates a data manager.
  SettingsDataManager({
    required this.exportEngine,
    required this.importEngine,
    required this.backupEngine,
    required this.fileService,
    required this.shareService,
  });

  /// Captures and encodes the dataset.
  final ExportEngine exportEngine;

  /// Validates and merges imported bundles.
  final ImportEngine importEngine;

  /// Creates and restores whole-dataset backups.
  final BackupEngine backupEngine;

  /// File-system access rooted at the app documents directory.
  final FileService fileService;

  /// Shares exported payloads (clipboard-backed today).
  final ShareService shareService;

  /// Exports the whole dataset and writes it to `exports/`.
  Future<Result<SettingsExportSummary>> exportData() => Result.tryAsync(
        () async {
          final exportResult = await exportEngine.export();
          if (exportResult.isFailure) throw exportResult.failureOrNull!;
          final export = exportResult.valueOrNull!;

          final fileName =
              'forge_export_${DateTime.now().microsecondsSinceEpoch}.json';
          final relative = 'exports/$fileName';
          final writeResult = await fileService.writeBytes(relative, export.bytes);
          if (writeResult.isFailure) throw writeResult.failureOrNull!;

          final shareResult = await shareService.share(
            ForgeSharePayload(
              title: 'Forge export',
              text: utf8.decode(export.bytes),
            ),
          );

          return SettingsExportSummary(
            export: export,
            relativePath: relative,
            copiedToClipboard: shareResult.isSuccess,
          );
        },
        classify: _dataFailure,
      );

  /// Creates a gzip-compressed backup in the backups directory.
  Future<Result<BackupResult>> createBackup() =>
      backupEngine.create(compress: true);

  /// The stored backups, newest first.
  Future<Result<List<File>>> listBackups() async {
    final result = await _list('backups');
    if (result.isFailure) return Result.failure(result.failureOrNull!);
    final files = [...result.valueOrNull!]
      ..sort((a, b) => b.path.compareTo(a.path));
    return Result.success(files);
  }

  /// Every importable bundle (backups plus exports), newest first.
  Future<Result<List<File>>> listImportCandidates() async {
    final backups = await listBackups();
    if (backups.isFailure) return Result.failure(backups.failureOrNull!);
    final exports = await _list('exports');
    if (exports.isFailure) return Result.failure(exports.failureOrNull!);
    final all = [...backups.valueOrNull!, ...exports.valueOrNull!]
      ..sort((a, b) => b.path.compareTo(a.path));
    return Result.success(all);
  }

  /// Restores [file] (a validated backup) over the current dataset.
  Future<Result<RestoreReport>> restore(File file) =>
      backupEngine.restore(file);

  /// Validates [file] as a bundle without writing anything.
  Future<Result<ImportValidation>> validateFile(File file) => Result.tryAsync(
        () async {
          final result =
              await importEngine.validateBytes(await _readBundleBytes(file));
          if (result.isFailure) throw result.failureOrNull!;
          return result.valueOrNull!;
        },
        classify: _dataFailure,
      );

  /// Validates and imports [file] with [policy].
  Future<Result<ImportReport>> importFile(
    File file, {
    ImportConflictPolicy policy = ImportConflictPolicy.overwrite,
  }) =>
      Result.tryAsync(
        () async {
          final result = await importEngine.importBytes(
            await _readBundleBytes(file),
            policy: policy,
          );
          if (result.isFailure) throw result.failureOrNull!;
          return result.valueOrNull!;
        },
        classify: _dataFailure,
      );

  Future<Uint8List> _readBundleBytes(File file) async {
    final bytes = await file.readAsBytes();
    if (!DataBundleCodec.isGzip(bytes)) return bytes;
    final decompressed = DataBundleCodec.decompress(bytes);
    if (decompressed.isFailure) throw decompressed.failureOrNull!;
    return decompressed.valueOrNull!;
  }

  Future<Result<List<File>>> _list(String relative) async {
    final base = await fileService.safePath(relative);
    if (base.isFailure) return Result.failure(base.failureOrNull!);
    final directory = Directory(base.valueOrNull!);
    if (!directory.existsSync()) return Result.success(const []);
    return fileService.list(directory);
  }

  ForgeFailure _dataFailure(Object error, StackTrace stackTrace) {
    return switch (error) {
      ForgeFailure() => error,
      FileSystemException() => FileFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
