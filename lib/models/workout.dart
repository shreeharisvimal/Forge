// Workout model for the Forge application.
//
// A Workout is a planned/saved routine that references exercises by id
// (no performed sets). Logged sessions are modeled by WorkoutSession.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'workout.g.dart';

/// A saved workout plan referencing a list of exercises.
@HiveType(typeId: 0)
class Workout extends Equatable implements Identifiable {
  /// Creates a [Workout].
  Workout({
    String? id,
    required this.date,
    this.durationMinutes = 0,
    this.notes = '',
    List<String>? exerciseIds,
    this.completed = false,
    this.volume = 0,
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

  /// When the workout was performed or scheduled.
  @HiveField(1)
  final DateTime date;

  /// Total duration in minutes.
  @HiveField(2)
  final int durationMinutes;

  /// Free-form user notes.
  @HiveField(3)
  final String notes;

  /// Ids of the exercises this workout contains.
  @HiveField(4)
  final List<String> exerciseIds;

  /// Whether the workout has been finished.
  @HiveField(5)
  final bool completed;

  /// Total volume in kg (sum of weight x reps across all sets).
  @HiveField(6)
  final double volume;

  /// Creation timestamp.
  @HiveField(7)
  final DateTime createdAt;

  /// Last modification timestamp.
  @HiveField(8)
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  Workout copyWith({
    String? id,
    DateTime? date,
    int? durationMinutes,
    String? notes,
    List<String>? exerciseIds,
    bool? completed,
    double? volume,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      completed: completed ?? this.completed,
      volume: volume ?? this.volume,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': toIsoString(date),
        'durationMinutes': durationMinutes,
        'notes': notes,
        'exerciseIds': exerciseIds,
        'completed': completed,
        'volume': volume,
        'createdAt': toIsoString(createdAt),
        'updatedAt': toIsoString(updatedAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as String?,
      date: parseIsoDate(map['date'] as String),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      exerciseIds: (map['exerciseIds'] as List?)?.cast<String>() ?? const [],
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
  factory Workout.fromJson(Map<String, dynamic> map) => Workout.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        date,
        durationMinutes,
        notes,
        exerciseIds,
        completed,
        volume,
        createdAt,
        updatedAt,
      ];
}
