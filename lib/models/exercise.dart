// Exercise model for the Forge application.
//
// An entry in the exercise library. Muscle group and equipment are stored
// as human-readable strings (not enums) so new categories never require a
// schema migration.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'exercise.g.dart';

/// Origin of an [Exercise]: part of the bundled catalog or user-created.
abstract final class ExerciseSource {
  ExerciseSource._();

  /// Exercise shipped with the app's default catalog.
  static const String seed = 'seed';

  /// Exercise created by the user.
  static const String user = 'user';
}

/// A cataloged exercise in the library.
@HiveType(typeId: 4)
class Exercise extends Equatable implements Identifiable {
  /// Creates an [Exercise].
  Exercise({
    String? id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.isCompound = false,
    this.notes = '',
    this.instructions = '',
    this.defaultRestSeconds = 90,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultRpe,
    this.tempo = '',
    List<String>? tags,
    List<String>? secondaryMuscles,
    this.favorite = false,
    this.source = ExerciseSource.user,
    this.archived = false,
    this.usageCount = 0,
    this.lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        tags = tags ?? const [],
        secondaryMuscles = secondaryMuscles ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// Display name, unique within the library.
  @HiveField(1)
  final String name;

  /// Primary muscle group, e.g. "Chest" or "Back".
  @HiveField(2)
  final String muscleGroup;

  /// Equipment required, e.g. "Barbell", "Cable", "Bodyweight".
  @HiveField(3)
  final String equipment;

  /// Whether the exercise is a multi-joint compound movement.
  @HiveField(4)
  final bool isCompound;

  /// Free-form notes / coaching cues.
  @HiveField(5)
  final String notes;

  /// Creation timestamp.
  @HiveField(6)
  final DateTime createdAt;

  /// Last modification timestamp.
  @HiveField(7)
  final DateTime updatedAt;

  /// Step-by-step execution instructions.
  @HiveField(8)
  final String instructions;

  /// Default rest between sets, in seconds.
  @HiveField(9)
  final int defaultRestSeconds;

  /// Default number of working sets.
  @HiveField(10)
  final int defaultSets;

  /// Default target reps per set.
  @HiveField(11)
  final int defaultReps;

  /// Default target RPE (e.g. 7.0-9.0), null when unset.
  @HiveField(12)
  final double? defaultRpe;

  /// Recommended tempo, e.g. "2-1-1".
  @HiveField(13)
  final String tempo;

  /// Free-form tags for grouping and searching.
  @HiveField(14)
  final List<String> tags;

  /// Secondary muscle groups engaged by the movement.
  @HiveField(15)
  final List<String> secondaryMuscles;

  /// Whether the user has starred the exercise.
  @HiveField(16)
  final bool favorite;

  /// Origin: [ExerciseSource.seed] or [ExerciseSource.user].
  @HiveField(17)
  final String source;

  /// Soft-delete flag; archived exercises are hidden but recoverable.
  @HiveField(18)
  final bool archived;

  /// How many times the exercise has been used in workouts.
  @HiveField(19)
  final int usageCount;

  /// When the exercise was last used in a workout.
  @HiveField(20)
  final DateTime? lastUsedAt;

  /// Returns a copy with the given fields replaced.
  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    String? equipment,
    bool? isCompound,
    String? notes,
    String? instructions,
    int? defaultRestSeconds,
    int? defaultSets,
    int? defaultReps,
    double? Function()? defaultRpe,
    String? tempo,
    List<String>? tags,
    List<String>? secondaryMuscles,
    bool? favorite,
    String? source,
    bool? archived,
    int? usageCount,
    DateTime? Function()? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      isCompound: isCompound ?? this.isCompound,
      notes: notes ?? this.notes,
      instructions: instructions ?? this.instructions,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRpe: defaultRpe != null ? defaultRpe() : this.defaultRpe,
      tempo: tempo ?? this.tempo,
      tags: tags ?? this.tags,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      favorite: favorite ?? this.favorite,
      source: source ?? this.source,
      archived: archived ?? this.archived,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt != null ? lastUsedAt() : this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'isCompound': isCompound,
        'notes': notes,
        'instructions': instructions,
        'defaultRestSeconds': defaultRestSeconds,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultRpe': defaultRpe,
        'tempo': tempo,
        'tags': tags,
        'secondaryMuscles': secondaryMuscles,
        'favorite': favorite,
        'source': source,
        'archived': archived,
        'usageCount': usageCount,
        'lastUsedAt': lastUsedAt != null ? toIsoString(lastUsedAt!) : null,
        'createdAt': toIsoString(createdAt),
        'updatedAt': toIsoString(updatedAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String?,
      name: map['name'] as String,
      muscleGroup: map['muscleGroup'] as String? ?? '',
      equipment: map['equipment'] as String? ?? '',
      isCompound: map['isCompound'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      defaultRestSeconds: (map['defaultRestSeconds'] as num?)?.toInt() ?? 90,
      defaultSets: (map['defaultSets'] as num?)?.toInt() ?? 3,
      defaultReps: (map['defaultReps'] as num?)?.toInt() ?? 10,
      defaultRpe: (map['defaultRpe'] as num?)?.toDouble(),
      tempo: map['tempo'] as String? ?? '',
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      secondaryMuscles:
          (map['secondaryMuscles'] as List?)?.cast<String>() ?? const [],
      favorite: map['favorite'] as bool? ?? false,
      source: map['source'] as String? ?? ExerciseSource.user,
      archived: map['archived'] as bool? ?? false,
      usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
      lastUsedAt: map['lastUsedAt'] != null
          ? parseIsoDate(map['lastUsedAt'] as String)
          : null,
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
  factory Exercise.fromJson(Map<String, dynamic> map) => Exercise.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        name,
        muscleGroup,
        equipment,
        isCompound,
        notes,
        instructions,
        defaultRestSeconds,
        defaultSets,
        defaultReps,
        defaultRpe,
        tempo,
        tags,
        secondaryMuscles,
        favorite,
        source,
        archived,
        usageCount,
        lastUsedAt,
        createdAt,
        updatedAt,
      ];
}
