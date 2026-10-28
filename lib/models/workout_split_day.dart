// WorkoutSplitDay model for the Forge application.
//
// One training day within a WorkoutSplit, e.g. "Day 1 — Push". Holds an
// ordered list of exercise assignments. Embedded in WorkoutSplit (not stored
// as its own box).
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';
import 'workout_split_exercise.dart';

part 'workout_split_day.g.dart';

/// A training day inside a [WorkoutSplit].
@HiveType(typeId: 13)
class WorkoutSplitDay extends Equatable implements Identifiable {
  /// Creates a [WorkoutSplitDay].
  WorkoutSplitDay({
    String? id,
    required this.name,
    this.focus = '',
    this.isRestDay = false,
    List<WorkoutSplitExercise>? exercises,
  })  : id = id ?? generateId(),
        exercises = exercises ?? [];

  /// Unique identifier of this day.
  @override
  @HiveField(0)
  final String id;

  /// Display name, e.g. "Day 1 — Push".
  @HiveField(1)
  final String name;

  /// Optional focus description, e.g. "Chest / Triceps".
  @HiveField(2)
  final String focus;

  /// Whether this is a rest/recovery day with no exercises.
  @HiveField(3)
  final bool isRestDay;

  /// The assigned exercises, in order.
  @HiveField(4)
  final List<WorkoutSplitExercise> exercises;

  /// Returns a copy with the given fields replaced.
  WorkoutSplitDay copyWith({
    String? id,
    String? name,
    String? focus,
    bool? isRestDay,
    List<WorkoutSplitExercise>? exercises,
  }) {
    return WorkoutSplitDay(
      id: id ?? this.id,
      name: name ?? this.name,
      focus: focus ?? this.focus,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Serializes to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'focus': focus,
        'isRestDay': isRestDay,
        'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutSplitDay.fromMap(Map<String, dynamic> map) {
    return WorkoutSplitDay(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      focus: map['focus'] as String? ?? '',
      isRestDay: map['isRestDay'] as bool? ?? false,
      exercises: (map['exercises'] as List?)
              ?.map((exercise) =>
                  WorkoutSplitExercise.fromMap(exercise as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WorkoutSplitDay.fromJson(Map<String, dynamic> map) =>
      WorkoutSplitDay.fromMap(map);

  @override
  List<Object?> get props => [id, name, focus, isRestDay, exercises];
}
