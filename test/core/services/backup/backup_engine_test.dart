// Tests for the backup engine.
//
// Backups are created into a temp directory so file naming, compression and
// restore are exercised against the real filesystem.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/backup/backup_engine.dart';
import 'package:forge/core/services/data_registry.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';

import '../helpers/fake_snapshot_source.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('forge_backup_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  FakeSnapshotSource source() => FakeSnapshotSource({
        'settings': {'settings-1': {'weightUnit': 'kg'}},
        'exercises': {
          'ex-1': exerciseRecord(id: 'ex-1', name: 'Squat'),
          'ex-2': exerciseRecord(id: 'ex-2', name: 'Deadlift'),
        },
      });

  BackupEngine engine([FakeSnapshotSource? src]) =>
      BackupEngine(src ?? source(), directory: directory);

  test('create writes a timestamped JSON backup and reports a manifest',
      () async {
    final result = await engine().create();

    expect(result.isSuccess, isTrue);
    final backup = result.valueOrNull!;
    expect(backup.file.path, startsWith(directory.path));
    expect(backup.file.path, endsWith('.${BackupEngine.jsonExtension}'));
    expect(backup.manifest.recordCount, 3);
    expect(backup.manifest.compressed, isFalse);
    expect(backup.manifest.format, ForgeDataFormat.name);
    expect(await backup.file.exists(), isTrue);
  });

  test('create with compress produces a gzip file', () async {
    final result = await engine().create(compress: true);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.manifest.compressed, isTrue);
    expect(
      result.valueOrNull!.file.path,
      endsWith('.${BackupEngine.gzipExtension}'),
    );
  });

  test('validate accepts an uncompressed backup', () async {
    final created = await engine().create();
    final result = await engine().validate(created.valueOrNull!.file);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.recordCount, 3);
    expect(result.valueOrNull!.compressed, isFalse);
  });

  test('validate accepts a compressed backup', () async {
    final created = await engine().create(compress: true);
    final result = await engine().validate(created.valueOrNull!.file);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.compressed, isTrue);
  });

  test('validate rejects a corrupt backup file', () async {
    final file = File('${directory.path}${Platform.pathSeparator}broken.forgebak');
    await file.writeAsBytes(const [1, 2, 3, 4]);

    final result = await engine().validate(file);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<BackupFailure>());
  });

  test('restore applies the snapshot to storage', () async {
    final created = await engine().create();
    final target = FakeSnapshotSource();
    final restoreEngine = BackupEngine(target, directory: directory);

    final result = await restoreEngine.restore(created.valueOrNull!.file);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.recordCount, 3);
    expect(target.data['exercises'], hasLength(2));
    expect(target.data['settings'], hasLength(1));
  });

  test('restore refuses a corrupt file and leaves storage untouched',
      () async {
    final target = FakeSnapshotSource({
      'exercises': {'keep': exerciseRecord(id: 'keep', name: 'Keep')},
    });
    final restoreEngine = BackupEngine(target, directory: directory);
    final file = File('${directory.path}${Platform.pathSeparator}broken.forgebak');
    await file.writeAsBytes(const [1, 2, 3, 4]);

    final result = await restoreEngine.restore(file);

    expect(result.isFailure, isTrue);
    expect(target.appliedSnapshots, isEmpty);
    expect(target.data['exercises'], hasLength(1));
  });

  test('a capture failure surfaces as a BackupFailure', () async {
    final failing = source()..failCapture = true;
    final result = await BackupEngine(failing, directory: directory).create();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<BackupFailure>());
  });
}
