// Tests for the export engine.
//
// A fake snapshot source feeds realistic data so counts and encoding are
// verified without touching Hive.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/data_bundle.dart';
import 'package:forge/core/services/data_registry.dart';
import 'package:forge/database/box_names.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/export/export_engine.dart';

import '../helpers/fake_snapshot_source.dart';

void main() {
  FakeSnapshotSource source() => FakeSnapshotSource({
        BoxNames.settings: {'settings-1': {'weightUnit': 'kg'}},
        BoxNames.exercises: {
          'ex-1': exerciseRecord(id: 'ex-1', name: 'Squat'),
          'ex-2': exerciseRecord(id: 'ex-2', name: 'Deadlift'),
        },
      });

  test('export encodes every box with per-box record counts', () async {
    final engine = ExportEngine(source());

    final result = await engine.export();

    expect(result.isSuccess, isTrue);
    final export = result.valueOrNull!;
    expect(export.recordCounts, {
      BoxNames.settings: 1,
      BoxNames.exercises: 2,
    });
    expect(export.totalRecords, 3);
    expect(export.bundle.format, ForgeDataFormat.name);

    final decoded = DataBundleCodec.decode(export.bytes);
    expect(decoded.isSuccess, isTrue);
    expect(decoded.valueOrNull!.snapshot.boxes[BoxNames.exercises], hasLength(2));
  });

  test('exportTo writes the encoded bytes to the given file', () async {
    final engine = ExportEngine(source());
    final directory = await Directory.systemTemp.createTemp('forge_export_');
    final file = File('${directory.path}${Platform.pathSeparator}data.json');

    final result = await engine.exportTo(file);

    expect(result.isSuccess, isTrue);
    final onDisk = jsonDecode(await file.readAsString());
    expect(onDisk['format'], ForgeDataFormat.name);
    expect(onDisk['data']['boxes'][BoxNames.exercises], hasLength(2));

    await directory.delete(recursive: true);
  });

  test('a capture failure becomes an ExportFailure', () async {
    final failing = source()..failCapture = true;
    final engine = ExportEngine(failing);

    final result = await engine.export();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ExportFailure>());
  });
}
