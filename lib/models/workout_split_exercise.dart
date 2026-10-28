// WorkoutSplitExercise model for the Forge application.
//
// One exercise assignment inside a split day, carrying the target sets,
// reps, RPE, rest and tempo pulled from the exercise library at add time.
// Embedded in WorkoutSplitDay (not stored as its own box).
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'workout_split_exercise.g.dart';

/// An exercise assigned to a [WorkoutSplitDay].
@HiveType(typeId: 14)
class WorkoutSplitExercise extends Equatable implements Identifiable {
  /// Creates a [WorkoutSplitExercise].
  WorkoutSplitExercise({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    this.order = 0,
    this.sets = 3,
    this.reps = 10,
    this.rpe,
    this.restSeconds = 90,
    this.tempo = '',
    this.notes = '',
  }) : id = id ?? generateId();

  /// Unique identifier of this assignment.
  @override
  @HiveField(0)
  final String id;

  /// References the exercise in the exercise library.
  @HiveField(1)
  final String exerciseId;

  /// Denormalized name so splits survive exercise library edits.
  @HiveField(2)
  final String exerciseName;

  /// Position within the day (0-based).
  @HiveField(3)
  final int order;

  /// Target working sets.
  @HiveField(4)
  final int sets;

  /// Target reps per set.
  @HiveField(5)
  final int reps;

  /// Target RPE (e.g. 7.0-9.0), null when unset.
  @HiveField(6)
  final double? rpe;

  /// Target rest between sets, in seconds.
  @HiveField(7)
  final int restSeconds;

  /// Recommended tempo, e.g. "2-1-1".
  @HiveField(8)
  final String tempo;

  /// Free-form notes for this assignment.
  @HiveField(9)
  final String notes;

  /// Returns a copy with the given fields replaced.
  WorkoutSplitExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    int? order,
    int? sets,
    int? reps,
    double? Function()? rpe,
    int? restSeconds,
    String? tempo,
    String? notes,
  }) {
    return WorkoutSplitExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rpe: rpe != null ? rpe() : this.rpe,
      restSeconds: restSeconds ?? this.restSeconds,
      tempo: tempo ?? this.tempo,
      notes: notes ?? this.notes,
    );
  }

  /// Serializes to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'order': order,
        'sets': sets,
        'reps': reps,
        'rpe': rpe,
        'restSeconds': restSeconds,
        'tempo': tempo,
        'notes': notes,
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutSplitExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutSplitExercise(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String,
      exerciseName: map['exerciseName'] as String? ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      rpe: (map['rpe'] as num?)?.toDouble(),
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 90,
      tempo: map['tempo'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WorkoutSplitExercise.fromJson(Map<String, dynamic> map) =>
      WorkoutSplitExercise.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        exerciseName,
        order,
        sets,
        reps,
        rpe,
        restSeconds,
        tempo,
        notes,
      ];
}
