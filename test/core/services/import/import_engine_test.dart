// Tests for the import engine.
//
// Conflict policies and migration are exercised against an in-memory source
// so the merge behavior is fully deterministic.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/data_bundle.dart';
import 'package:forge/core/services/data_registry.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/import/import_engine.dart';
import 'package:forge/database/box_names.dart';

import '../helpers/fake_snapshot_source.dart';

void main() {
  Uint8List bytesOf(ForgeDataBundle bundle) => DataBundleCodec.encode(bundle);

  ForgeDataBundle bundle() => DataBundleCodec.build(
        DataSnapshot(
          createdAt: DateTime(2026, 1, 1),
          boxes: {
            BoxNames.exercises: {
              'ex-1': exerciseRecord(id: 'ex-1', name: 'Squat'),
              'ex-2': exerciseRecord(id: 'ex-2', name: 'Press'),
            },
          },
        ),
      );

  group('validateBytes', () {
    test('reports per-box counts and unknown boxes', () async {
      final engine = ImportEngine(FakeSnapshotSource());
      final valid = DataBundleCodec.build(
        DataSnapshot(
          createdAt: DateTime(2026, 1, 1),
          boxes: {
            BoxNames.exercises: {
              'ex-1': exerciseRecord(),
            },
            'mystery': {'a': {'v': 1}},
          },
        ),
      );

      final result = await engine.validateBytes(bytesOf(valid));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.recordCounts,
          {BoxNames.exercises: 1, 'mystery': 1});
      expect(result.valueOrNull!.unknownBoxes, ['mystery']);
      expect(result.valueOrNull!.totalRecords, 2);
    });

    test('rejects a bundle with a bad checksum', () async {
      final engine = ImportEngine(FakeSnapshotSource());
      final valid = DataBundleCodec.build(
        DataSnapshot(createdAt: DateTime(2026, 1, 1), boxes: const {}),
      );
      final map = valid.toJson();
      map['checksum'] = '0' * 64;

      final result = await engine.validateBytes(
        Uint8List.fromList(utf8.encode(jsonEncode(map))),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ImportFailure>());
    });
  });

  group('importBundle policies', () {
    test('adds records whose ids do not exist yet', () async {
      final source = FakeSnapshotSource();
      final engine = ImportEngine(source);

      final result = await engine.importBundle(bundle());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.added, 2);
      expect(result.valueOrNull!.appliedCount, 2);
      expect(source.data[BoxNames.exercises], hasLength(2));
    });

    test('overwrite policy replaces conflicting records', () async {
      final source = FakeSnapshotSource({
        BoxNames.exercises: {
          'ex-1': exerciseRecord(id: 'ex-1', name: 'Old Name'),
        },
      });
      final engine = ImportEngine(source);

      final result = await engine.importBundle(bundle());

      expect(result.valueOrNull!.overwritten, 1);
      expect(result.valueOrNull!.added, 1);
      expect(
        source.data[BoxNames.exercises]!['ex-1']!['name'],
        'Squat',
      );
    });

    test('skip policy keeps existing records and drops conflicts', () async {
      final source = FakeSnapshotSource({
        BoxNames.exercises: {
          'ex-1': exerciseRecord(id: 'ex-1', name: 'Old Name'),
        },
      });
      final engine = ImportEngine(source);

      final result = await engine.importBundle(
        bundle(),
        policy: ImportConflictPolicy.skip,
      );

      expect(result.valueOrNull!.skipped, 1);
      expect(result.valueOrNull!.added, 1);
      expect(source.data[BoxNames.exercises]!['ex-1']!['name'], 'Old Name');
    });

    test('rename policy stores conflicts under fresh ids', () async {
      final source = FakeSnapshotSource({
        BoxNames.exercises: {
          'ex-1': exerciseRecord(id: 'ex-1', name: 'Old Name'),
        },
      });
      final engine = ImportEngine(source);

      final result = await engine.importBundle(
        bundle(),
        policy: ImportConflictPolicy.rename,
      );

      expect(result.valueOrNull!.renamed, 1);
      expect(result.valueOrNull!.added, 1);
      expect(source.data[BoxNames.exercises], hasLength(3));
      expect(
        source.data[BoxNames.exercises]!.values.where((r) => r['name'] == 'Squat'),
        hasLength(1),
      );
    });
  });

  group('importBytes', () {
    test('validates then applies the decoded bundle', () async {
      final source = FakeSnapshotSource();
      final engine = ImportEngine(source);

      final result = await engine.importBytes(bytesOf(bundle()));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.added, 2);
      expect(source.data[BoxNames.exercises], hasLength(2));
    });

    test('a tampered bundle is rejected without touching storage', () async {
      final source = FakeSnapshotSource();
      final engine = ImportEngine(source);
      final valid = bundle();
      final map = valid.toJson();
      map['data']['boxes'][BoxNames.exercises]['ex-1']['name'] = 'Hacked';

      final result = await engine.importBytes(bytesOf(valid));

      expect(result.isFailure, isTrue);
      expect(source.appliedSnapshots, isEmpty);
    });
  });

  group('migrator', () {
    test('runs the migrator before applying', () async {
      final source = FakeSnapshotSource();
      final engine = ImportEngine(source);
      final migrator = _RenamingMigrator();

      final result = await engine.importBundle(
        bundle(),
        migrator: migrator,
      );

      expect(result.isSuccess, isTrue);
      expect(
        source.data[BoxNames.exercises]!['ex-1']!['name'],
        'Squat (renamed)',
      );
    });
  });

  test('an apply failure becomes an ImportFailure', () async {
    final source = FakeSnapshotSource()..failApply = true;
    final engine = ImportEngine(source);

    final result = await engine.importBundle(bundle());

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ImportFailure>());
  });
}

class _RenamingMigrator implements ImportMigrator {
  @override
  Future<DataSnapshot> migrate(DataSnapshot snapshot) async {
    final boxes = {
      for (final box in snapshot.boxes.entries)
        box.key: {
          for (final record in box.value.entries)
            record.key: {
              ...record.value,
              'name': '${record.value['name']} (renamed)',
            },
        },
    };
    return DataSnapshot(boxes: boxes, createdAt: snapshot.createdAt);
  }
}
