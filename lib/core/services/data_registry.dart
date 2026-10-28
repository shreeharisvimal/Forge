// Data registry and snapshot layer for the Forge application.
//
// Import, export and backup all move the same set of model collections
// between Hive and JSON. This file is the single source of truth for that
// mapping: every boxed model type is listed once, together with its
// JSON-safe encoder/decoder, so the three engines cannot drift apart.
//
// An exported/backed-up bundle is a [DataSnapshot]: a map of box name to
// a map of record id to JSON object. [HiveDataSnapshotSource] reads and
// writes that shape against [DatabaseService].
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../database/box_names.dart';
import '../../database/database_service.dart';
import '../../models/body_measurement.dart';
import '../../models/calendar_day.dart';
import '../../models/exercise.dart';
import '../../models/exercise_history.dart';
import '../../models/personal_record.dart';
import '../../models/settings_model.dart';
import '../../models/weight_entry.dart';
import '../../models/workout.dart';
import '../../models/workout_session.dart';
import '../../models/workout_split.dart';
import '../../models/workout_template.dart';
import '../utils/ids.dart';

/// Identifies the payload shape in an export/backup file.
abstract final class ForgeDataFormat {
  ForgeDataFormat._();

  /// The format name for Forge data bundles.
  static const String name = 'forge-data';

  /// The current bundle format version. Bump when the shape changes.
  static const int version = 1;
}

/// Describes how one boxed model collection is encoded and decoded.
class DataTypeDescriptor {
  /// Creates a descriptor.
  const DataTypeDescriptor({
    required this.boxName,
    required this.encode,
    required this.decode,
  });

  /// The Hive box name holding these records.
  final String boxName;

  /// Encodes a model into a JSON-safe map.
  final Map<String, dynamic> Function(Object model) encode;

  /// Decodes a JSON-safe map back into a model.
  final Object Function(Map<String, dynamic> map) decode;
}

/// The registry of every boxed model type in Forge.
abstract final class ForgeDataRegistry {
  ForgeDataRegistry._();

  /// Every boxed model type, keyed by box name.
  static final Map<String, DataTypeDescriptor> _descriptors = {
    for (final descriptor in _all) descriptor.boxName: descriptor,
  };

  /// The full, ordered list of supported boxed types.
  static final List<DataTypeDescriptor> _all = [
    DataTypeDescriptor(
      boxName: BoxNames.settings,
      encode: (model) => (model as SettingsModel).toMap(),
      decode: (map) => SettingsModel.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.exercises,
      encode: (model) => (model as Exercise).toMap(),
      decode: (map) => Exercise.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.workouts,
      encode: (model) => (model as Workout).toMap(),
      decode: (map) => Workout.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.sessions,
      encode: (model) => (model as WorkoutSession).toMap(),
      decode: (map) => WorkoutSession.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.calendar,
      encode: (model) => (model as CalendarDay).toMap(),
      decode: (map) => CalendarDay.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.measurements,
      encode: (model) => (model as BodyMeasurement).toMap(),
      decode: (map) => BodyMeasurement.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.weight,
      encode: (model) => (model as WeightEntry).toMap(),
      decode: (map) => WeightEntry.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.templates,
      encode: (model) => (model as WorkoutTemplate).toMap(),
      decode: (map) => WorkoutTemplate.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.splits,
      encode: (model) => (model as WorkoutSplit).toMap(),
      decode: (map) => WorkoutSplit.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.prs,
      encode: (model) => (model as PersonalRecord).toMap(),
      decode: (map) => PersonalRecord.fromMap(map),
    ),
    DataTypeDescriptor(
      boxName: BoxNames.history,
      encode: (model) => (model as ExerciseHistory).toMap(),
      decode: (map) => ExerciseHistory.fromMap(map),
    ),
  ];

  /// Every registered boxed type, in stable order.
  static List<DataTypeDescriptor> get all => List.unmodifiable(_all);

  /// The descriptor for [boxName], or null when the box is not registered.
  static DataTypeDescriptor? descriptorFor(String boxName) =>
      _descriptors[boxName];
}

/// A JSON-safe snapshot of every boxed collection.
class DataSnapshot {
  /// Creates a snapshot.
  DataSnapshot({required this.boxes, required this.createdAt});

  /// Box name -> record id -> JSON-safe record map.
  final Map<String, Map<String, Map<String, dynamic>>> boxes;

  /// When the snapshot was captured.
  final DateTime createdAt;

  /// Serializes to a JSON-safe map.
  Map<String, dynamic> toJson() => {
        'createdAt': toIsoString(createdAt),
        'boxes': boxes,
      };

  /// Deserializes from a map produced by [toJson].
  factory DataSnapshot.fromJson(Map<String, dynamic> json) {
    return DataSnapshot(
      createdAt: json['createdAt'] != null
          ? parseIsoDate(json['createdAt'] as String)
          : DateTime.now(),
      boxes: (json['boxes'] as Map<String, dynamic>? ?? const {}).map(
        (boxName, records) => MapEntry(
          boxName,
          (records as Map<String, dynamic>).map(
            (id, record) => MapEntry(id, (record as Map).cast<String, dynamic>()),
          ),
        ),
      ),
    );
  }
}

/// Reads and writes [DataSnapshot]s against a storage backend.
abstract class DataSnapshotSource {
  /// Captures every boxed collection into a snapshot.
  Future<DataSnapshot> capture();

  /// Overwrites the boxed collections with the records in [snapshot].
  Future<void> apply(DataSnapshot snapshot);
}

/// Reads and writes [DataSnapshot]s against the Hive-backed [DatabaseService].
class HiveDataSnapshotSource implements DataSnapshotSource {
  /// Creates a snapshot source.
  HiveDataSnapshotSource(this._databaseService);

  final DatabaseService _databaseService;

  /// Captures every boxed collection into a snapshot.
  @override
  Future<DataSnapshot> capture() async {
    final boxes = <String, Map<String, Map<String, dynamic>>>{};
    for (final descriptor in ForgeDataRegistry.all) {
      final box = _box(descriptor.boxName);
      boxes[descriptor.boxName] = {
        for (final id in box.keys)
          id: descriptor.encode(box.get(id) as Object),
      };
    }
    return DataSnapshot(boxes: boxes, createdAt: DateTime.now());
  }

  /// Overwrites the boxed collections with the records in [snapshot].
  ///
  /// Only boxes present in the snapshot are touched; boxes omitted from the
  /// snapshot are left as-is.
  @override
  Future<void> apply(DataSnapshot snapshot) async {
    for (final descriptor in ForgeDataRegistry.all) {
      final records = snapshot.boxes[descriptor.boxName];
      if (records == null || records.isEmpty) continue;
      final box = _box(descriptor.boxName);
      // Decoded values are written one at a time with a dynamic value so a
      // typed box's `Map<dynamic, V> putAll` cast never rejects them.
      for (final entry in records.entries) {
        await box.put(entry.key, descriptor.decode(entry.value) as dynamic);
      }
    }
  }

  Box<Object?> _box(String boxName) {
    final service = _databaseService;
    return switch (boxName) {
      BoxNames.settings => service.settingsBox,
      BoxNames.exercises => service.exerciseBox,
      BoxNames.workouts => service.workoutBox,
      BoxNames.sessions => service.sessionBox,
      BoxNames.calendar => service.calendarBox,
      BoxNames.measurements => service.measurementBox,
      BoxNames.weight => service.weightBox,
      BoxNames.templates => service.templateBox,
      BoxNames.splits => service.splitBox,
      BoxNames.prs => service.prBox,
      BoxNames.history => service.historyBox,
      _ => throw StateError('Unregistered box: $boxName'),
    };
  }
}
