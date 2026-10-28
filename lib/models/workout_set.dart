// WorkoutSet model for the Forge application.
//
// A single performed set (weight, reps, intensity metric) within a
// WorkoutExercise. Embedded — not stored in its own box.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'workout_set.g.dart';

/// A single performed set.
@HiveType(typeId: 3)
class WorkoutSet extends Equatable implements Identifiable {
  /// Creates a [WorkoutSet].
  WorkoutSet({
    String? id,
    this.weight = 0,
    this.reps = 0,
    this.rpe,
    this.restSeconds = 0,
    this.completed = false,
    this.isFailure = false,
    this.isWarmup = false,
    this.isDropSet = false,
    this.isSuperSet = false,
    this.tempo,
    this.notes = '',
    DateTime? timestamp,
  })  : id = id ?? generateId(),
        timestamp = timestamp ?? DateTime.now();

  /// Unique identifier of this set.
  @override
  @HiveField(0)
  final String id;

  /// Load used, in the user's weight unit.
  @HiveField(1)
  final double weight;

  /// Number of repetitions completed.
  @HiveField(2)
  final int reps;

  /// Rate of perceived exertion on the 1-10 scale (optional).
  @HiveField(3)
  final double? rpe;

  /// Rest taken after this set, in seconds.
  @HiveField(4)
  final int restSeconds;

  /// Whether the set was performed and recorded.
  @HiveField(5)
  final bool completed;

  /// Whether the set ended in failure (or was an intentional failure set).
  @HiveField(6)
  final bool isFailure;

  /// When the set was performed.
  @HiveField(7)
  final DateTime timestamp;

  /// Whether the set was a warm-up set.
  @HiveField(8)
  final bool isWarmup;

  /// Whether the set was a drop set (reducing load between repetitions).
  @HiveField(9)
  final bool isDropSet;

  /// Whether the set was part of a superset.
  @HiveField(10)
  final bool isSuperSet;

  /// Tempo prescription (e.g. "3010") if the set was performed with a tempo.
  @HiveField(11)
  final String? tempo;

  /// Free-form per-set notes.
  @HiveField(12)
  final String notes;

  /// Returns a copy with the given fields replaced.
  WorkoutSet copyWith({
    String? id,
    double? weight,
    int? reps,
    double? Function()? rpe,
    int? restSeconds,
    bool? completed,
    bool? isFailure,
    bool? isWarmup,
    bool? isDropSet,
    bool? isSuperSet,
    String? Function()? tempo,
    String? notes,
    DateTime? timestamp,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe != null ? rpe() : this.rpe,
      restSeconds: restSeconds ?? this.restSeconds,
      completed: completed ?? this.completed,
      isFailure: isFailure ?? this.isFailure,
      isWarmup: isWarmup ?? this.isWarmup,
      isDropSet: isDropSet ?? this.isDropSet,
      isSuperSet: isSuperSet ?? this.isSuperSet,
      tempo: tempo != null ? tempo() : this.tempo,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'restSeconds': restSeconds,
        'completed': completed,
        'isFailure': isFailure,
        'isWarmup': isWarmup,
        'isDropSet': isDropSet,
        'isSuperSet': isSuperSet,
        'tempo': tempo,
        'notes': notes,
        'timestamp': toIsoString(timestamp),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as String?,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      rpe: (map['rpe'] as num?)?.toDouble(),
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? false,
      isFailure: map['isFailure'] as bool? ?? false,
      isWarmup: map['isWarmup'] as bool? ?? false,
      isDropSet: map['isDropSet'] as bool? ?? false,
      isSuperSet: map['isSuperSet'] as bool? ?? false,
      tempo: map['tempo'] as String?,
      notes: map['notes'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? parseIsoDate(map['timestamp'] as String)
          : null,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WorkoutSet.fromJson(Map<String, dynamic> map) =>
      WorkoutSet.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        weight,
        reps,
        rpe,
        restSeconds,
        completed,
        isFailure,
        isWarmup,
        isDropSet,
        isSuperSet,
        tempo,
        notes,
        timestamp,
      ];
}
