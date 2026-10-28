// WorkoutSession model for the Forge application.
//
// A WorkoutSession records a training session that was actually performed,
// including every exercise instance and set. It may reference the Workout
// plan it originated from.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';
import 'workout_exercise.dart';

part 'workout_session.g.dart';

/// A performed workout session with full exercise and set detail.
@HiveType(typeId: 1)
class WorkoutSession extends Equatable implements Identifiable {
  /// Creates a [WorkoutSession].
  WorkoutSession({
    String? id,
    this.workoutId,
    required this.date,
    this.name = '',
    this.startedAt,
    this.durationMinutes = 0,
    this.notes = '',
    List<WorkoutExercise>? exercises,
    this.completed = false,
    this.volume = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        exercises = exercises ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// References the originating [Workout] plan, if any.
  @HiveField(1)
  final String? workoutId;

  /// When the session was performed.
  @HiveField(2)
  final DateTime date;

  /// Total duration in minutes.
  @HiveField(3)
  final int durationMinutes;

  /// Display name of the session (split/template name or free-form).
  @HiveField(10)
  final String name;

  /// When the training was actually started (preparation finished).
  @HiveField(11)
  final DateTime? startedAt;

  /// Free-form user notes.
  @HiveField(4)
  final String notes;

  /// The performed exercises with their sets.
  @HiveField(5)
  final List<WorkoutExercise> exercises;

  /// Whether the session is finished.
  @HiveField(6)
  final bool completed;

  /// Total volume in kg (sum of weight x reps across all sets).
  @HiveField(7)
  final double volume;

  /// Creation timestamp.
  @HiveField(8)
  final DateTime createdAt;

  /// Last modification timestamp.
  @HiveField(9)
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  WorkoutSession copyWith({
    String? id,
    String? Function()? workoutId,
    DateTime? date,
    String? name,
    DateTime? Function()? startedAt,
    int? durationMinutes,
    String? notes,
    List<WorkoutExercise>? exercises,
    bool? completed,
    double? volume,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutId: workoutId != null ? workoutId() : this.workoutId,
      date: date ?? this.date,
      name: name ?? this.name,
      startedAt: startedAt != null ? startedAt() : this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      completed: completed ?? this.completed,
      volume: volume ?? this.volume,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'workoutId': workoutId,
        'date': toIsoString(date),
        'name': name,
        'startedAt': startedAt != null ? toIsoString(startedAt!) : null,
        'durationMinutes': durationMinutes,
        'notes': notes,
        'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
        'completed': completed,
        'volume': volume,
        'createdAt': toIsoString(createdAt),
        'updatedAt': toIsoString(updatedAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String?,
      workoutId: map['workoutId'] as String?,
      date: parseIsoDate(map['date'] as String),
      name: map['name'] as String? ?? '',
      startedAt: map['startedAt'] != null
          ? parseIsoDate(map['startedAt'] as String)
          : null,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      exercises: (map['exercises'] as List?)
              ?.map((exercise) => WorkoutExercise.fromMap(
                  exercise as Map<String, dynamic>))
              .toList() ??
          const [],
      completed: map['completed'] as bool? ?? false,
      volume: (map['volume'] as num?)?.toDouble() ?? 0,
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
  factory WorkoutSession.fromJson(Map<String, dynamic> map) =>
      WorkoutSession.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        workoutId,
        date,
        name,
        startedAt,
        durationMinutes,
        notes,
        exercises,
        completed,
        volume,
        createdAt,
        updatedAt,
      ];
}
