// WorkoutTemplate model for the Forge application.
//
// A reusable list of exercises that a user can start a Workout from.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'workout_template.g.dart';

/// A reusable workout template.
@HiveType(typeId: 9)
class WorkoutTemplate extends Equatable implements Identifiable {
  /// Creates a [WorkoutTemplate].
  WorkoutTemplate({
    String? id,
    required this.name,
    this.weekday,
    List<String>? exerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        exerciseIds = exerciseIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// Display name of the template.
  @HiveField(1)
  final String name;

  /// Optional 1-7 weekday this template is intended for (Monday=1).
  @HiveField(2)
  final int? weekday;

  /// Ordered exercise ids this template contains.
  @HiveField(3)
  final List<String> exerciseIds;

  /// Creation timestamp.
  @HiveField(4)
  final DateTime createdAt;

  /// Last modification timestamp.
  @HiveField(5)
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  WorkoutTemplate copyWith({
    String? id,
    String? name,
    int? Function()? weekday,
    List<String>? exerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      weekday: weekday != null ? weekday() : this.weekday,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weekday': weekday,
        'exerciseIds': exerciseIds,
        'createdAt': toIsoString(createdAt),
        'updatedAt': toIsoString(updatedAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] as String?,
      name: map['name'] as String,
      weekday: (map['weekday'] as num?)?.toInt(),
      exerciseIds: (map['exerciseIds'] as List?)?.cast<String>() ?? const [],
      createdAt: map['createdAt'] != null
          ? parseIsoDate(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? parseIsoDate(map['updatedAt'] as String)
          : null,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WorkoutTemplate.fromJson(Map<String, dynamic> map) =>
      WorkoutTemplate.fromMap(map);

  @override
  List<Object?> get props =>
      [id, name, weekday, exerciseIds, createdAt, updatedAt];
}
