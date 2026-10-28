// Tests for the settings data manager.
//
// Drives the real export/import/backup engines against a temp documents
// directory and a fake share service so the Data-section orchestration
// (naming, gzip handling, candidates and validation) is covered end to end
// without plugins or platform channels.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/backup/backup_engine.dart';
import 'package:forge/core/services/data_bundle.dart';
import 'package:forge/core/services/data_registry.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/error_handling/result.dart';
import 'package:forge/core/services/export/export_engine.dart';
import 'package:forge/core/services/file/file_service.dart';
import 'package:forge/core/services/import/import_engine.dart';
import 'package:forge/core/services/share/share_service.dart';
import 'package:forge/features/settings/data/settings_data_manager.dart';
import 'package:forge/models/workout.dart';

import '../../../helpers/hive_test_env.dart';

class _RecordingShareService implements ShareService {
  final payloads = <ForgeSharePayload>[];
  bool succeed = true;

  @override
  Future<Result<void>> share(ForgeSharePayload payload) async {
    payloads.add(payload);
    if (!succeed) return Result.failure(const ShareFailure('share refused'));
    return Result.success(null);
  }
}

void main() {
  late HiveTestEnv env;
  late Directory dataDir;
  late HiveDataSnapshotSource source;
  late _RecordingShareService shareService;
  late SettingsDataManager manager;

  setUp(() async {
    env = await HiveTestEnv.create();
    dataDir = await Directory.systemTemp.createTemp('forge_data_test');
    source = HiveDataSnapshotSource(env.databaseService);
    shareService = _RecordingShareService();
    manager = SettingsDataManager(
      exportEngine: ExportEngine(source),
      importEngine: ImportEngine(source),
      backupEngine: BackupEngine(
        source,
        directory: Directory('${dataDir.path}${Platform.pathSeparator}backups'),
      ),
      fileService: FileService(baseDirectory: dataDir),
      shareService: shareService,
    );
  });

  tearDown(() async {
    await env.dispose();
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  test('exportData writes the bundle under exports and shares it', () async {
    final result = await manager.exportData();

    expect(result.isSuccess, isTrue);
    final summary = result.valueOrNull!;
    expect(summary.relativePath, startsWith('exports/forge_export_'));
    expect(summary.totalRecords, greaterThanOrEqualTo(0));
    expect(summary.copiedToClipboard, isTrue);
    expect(
      File('${dataDir.path}${Platform.pathSeparator}${summary.relativePath}')
          .existsSync(),
      isTrue,
    );
    expect(shareService.payloads.single.title, 'Forge export');
  });

  test('exportData reports the clipboard outcome when sharing fails', () async {
    shareService.succeed = false;

    final result = await manager.exportData();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.copiedToClipboard, isFalse);
  });

  test('createBackup writes a gzip-compressed backup file', () async {
    final result = await manager.createBackup();

    expect(result.isSuccess, isTrue);
    final backup = result.valueOrNull!;
    expect(backup.file.existsSync(), isTrue);
    expect(backup.file.path, endsWith('.gz'));
    final bytes = backup.file.readAsBytesSync();
    expect(DataBundleCodec.isGzip(Uint8List.fromList(bytes)), isTrue);
  });

  test('listBackups returns the created backup', () async {
    await manager.createBackup();

    final result = await manager.listBackups();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNotEmpty);
  });

  test('listImportCandidates includes both backups and exports', () async {
    await manager.createBackup();
    await manager.exportData();

    final result = await manager.listImportCandidates();
    expect(result.isSuccess, isTrue);
    final candidates = result.valueOrNull!;
    final paths = candidates.map((file) => file.path).toList();
    expect(paths.any((path) => path.contains('backup')), isTrue);
    expect(paths.any((path) => path.contains('export')), isTrue);
  });

  test('validateFile rejects a non-bundle file', () async {
    final bogus = File('${dataDir.path}${Platform.pathSeparator}notes.txt');
    await bogus.writeAsString('not a bundle');

    final result = await manager.validateFile(bogus);
    expect(result.isFailure, isTrue);
  });

  test('importFile merges a previously exported bundle', () async {
    await env.databaseService.workoutBox.put(
      'w1',
      Workout(id: 'w1', date: DateTime(2026, 8, 4)),
    );

    final export = await manager.exportData();
    final exportFile = File(
      '${dataDir.path}${Platform.pathSeparator}'
      '${export.valueOrNull!.relativePath}',
    );
    expect(exportFile.existsSync(), isTrue);

    await env.databaseService.workoutBox.clear();

    final result = await manager.importFile(exportFile);
    expect(result.isSuccess, isTrue);
    expect(env.databaseService.workoutBox.get('w1'), isNotNull);
  });

  test('restore recovers the dataset from a backup', () async {
    await env.databaseService.workoutBox.put(
      'w1',
      Workout(id: 'w1', date: DateTime(2026, 8, 4)),
    );
    final backup = (await manager.createBackup()).valueOrNull!;

    await env.databaseService.workoutBox.clear();
    expect(env.databaseService.workoutBox.length, 0);

    final result = await manager.restore(backup.file);
    expect(result.isSuccess, isTrue);
    expect(env.databaseService.workoutBox.get('w1'), isNotNull);
  });
}
