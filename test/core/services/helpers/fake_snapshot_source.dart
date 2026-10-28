// Shared in-memory [DataSnapshotSource] for engine tests.
//
// Mirrors [HiveDataSnapshotSource] semantics: capture reads the current
// map, apply overwrites the boxes present in the snapshot.
library;

import 'package:forge/core/services/data_registry.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';

/// An in-memory snapshot source whose contents tests can inspect directly.
class FakeSnapshotSource implements DataSnapshotSource {
  /// Creates a source seeded with [seed] boxes.
  FakeSnapshotSource([Map<String, Map<String, Map<String, dynamic>>>? seed])
      : data = seed ?? {};

  /// Box name -> record id -> record. Tests read/write this directly.
  Map<String, Map<String, Map<String, dynamic>>> data;

  /// When true, [capture] throws a [StorageFailure].
  bool failCapture = false;

  /// When true, [apply] throws a [StorageFailure].
  bool failApply = false;

  /// Records the snapshots passed to [apply].
  final List<DataSnapshot> appliedSnapshots = [];

  @override
  Future<DataSnapshot> capture() async {
    if (failCapture) {
      throw const StorageFailure('capture failed');
    }
    return DataSnapshot(boxes: _deepCopy(data), createdAt: DateTime(2026, 1, 1));
  }

  @override
  Future<void> apply(DataSnapshot snapshot) async {
    if (failApply) {
      throw const StorageFailure('apply failed');
    }
    appliedSnapshots.add(snapshot);
    for (final entry in snapshot.boxes.entries) {
      final existing = data[entry.key] ?? {};
      data[entry.key] = {
        ...existing,
        for (final record in entry.value.entries)
          record.key: Map<String, dynamic>.from(record.value),
      };
    }
  }

  static Map<String, Map<String, Map<String, dynamic>>> _deepCopy(
    Map<String, Map<String, Map<String, dynamic>>> source,
  ) =>
      {
        for (final entry in source.entries)
          entry.key: {
            for (final record in entry.value.entries)
              record.key: Map<String, dynamic>.from(record.value),
          },
      };
}

/// A single exercise record with a stable shape.
Map<String, dynamic> exerciseRecord({
  String id = 'ex-1',
  String name = 'Squat',
}) =>
    {
      'id': id,
      'name': name,
      'primaryMuscle': 'quads',
      'category': 'barbell',
    };
