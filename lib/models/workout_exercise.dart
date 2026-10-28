// WorkoutExercise model for the Forge application.
//
// One exercise instance inside a workout session, carrying its performed
// sets. Embedded in WorkoutSession (not stored as its own box).
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';
import 'workout_set.dart';

part 'workout_exercise.g.dart';

/// A performed exercise within a [WorkoutSession].
@HiveType(typeId: 2)
class WorkoutExercise extends Equatable implements Identifiable {
  /// Creates a [WorkoutExercise].
  WorkoutExercise({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    this.order = 0,
    this.notes = '',
    List<WorkoutSet>? sets,
  })  : id = id ?? generateId(),
        sets = sets ?? [];

  /// Unique identifier of this exercise instance.
  @override
  @HiveField(0)
  final String id;

  /// References the exercise in the exercise library.
  @HiveField(1)
  final String exerciseId;

  /// Denormalized name so sessions survive exercise library edits.
  @HiveField(2)
  final String exerciseName;

  /// Position within the workout (0-based).
  @HiveField(3)
  final int order;

  /// Free-form notes for this exercise instance.
  @HiveField(4)
  final String notes;

  /// The performed sets, in order.
  @HiveField(5)
  final List<WorkoutSet> sets;

  /// Returns a copy with the given fields replaced.
  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    int? order,
    String? notes,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'order': order,
        'notes': notes,
        'sets': sets.map((set) => set.toMap()).toList(),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String,
      exerciseName: map['exerciseName'] as String? ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      sets: (map['sets'] as List?)
              ?.map((set) =>
                  WorkoutSet.fromMap(set as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WorkoutExercise.fromJson(Map<String, dynamic> map) =>
      WorkoutExercise.fromMap(map);

  @override
  List<Object?> get props =>
      [id, exerciseId, exerciseName, order, notes, sets];
}
