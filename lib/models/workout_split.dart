// WorkoutSplit model for the Forge application.
//
// A weekly training plan composed of named days (Push, Pull, Legs, Rest...),
// each carrying an ordered list of exercise assignments. Exactly one split
// can be active at a time and is used by the dashboard and calendar.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';
import 'workout_split_day.dart';

part 'workout_split.g.dart';

/// A complete weekly workout split.
@HiveType(typeId: 12)
class WorkoutSplit extends Equatable implements Identifiable {
  /// Creates a [WorkoutSplit].
  WorkoutSplit({
    String? id,
    required this.name,
    this.description = '',
    this.color = 0xFF7C4DFF,
    this.iconCodePoint = 0xe306,
    this.isActive = false,
    List<WorkoutSplitDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        days = days ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// Display name, e.g. "Push / Pull / Legs".
  @HiveField(1)
  final String name;

  /// Free-form description of the split.
  @HiveField(2)
  final String description;

  /// Accent color as an ARGB int, used for cards and the active badge.
  @HiveField(3)
  final int color;

  /// Icon codepoint used for the split card.
  @HiveField(4)
  final int iconCodePoint;

  /// Whether this is the split currently driving the schedule.
  @HiveField(5)
  final bool isActive;

  /// The training days, in weekly order.
  @HiveField(6)
  final List<WorkoutSplitDay> days;

  /// Creation timestamp.
  @HiveField(7)
  final DateTime createdAt;

  /// Last modification timestamp.
  @HiveField(8)
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  WorkoutSplit copyWith({
    String? id,
    String? name,
    String? description,
    int? color,
    int? iconCodePoint,
    bool? isActive,
    List<WorkoutSplitDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutSplit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isActive: isActive ?? this.isActive,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'color': color,
        'iconCodePoint': iconCodePoint,
        'isActive': isActive,
        'days': days.map((day) => day.toMap()).toList(),
        'createdAt': toIsoString(createdAt),
        'updatedAt': toIsoString(updatedAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory WorkoutSplit.fromMap(Map<String, dynamic> map) {
    return WorkoutSplit(
      id: map['id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFF7C4DFF,
      iconCodePoint: (map['iconCodePoint'] as num?)?.toInt() ?? 0xe306,
      isActive: map['isActive'] as bool? ?? false,
      days: (map['days'] as List?)
              ?.map(
                (day) => WorkoutSplitDay.fromMap(day as Map<String, dynamic>),
              )
              .toList() ??
          const [],
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
  factory WorkoutSplit.fromJson(Map<String, dynamic> map) =>
      WorkoutSplit.fromMap(map);

  /// Total number of exercise assignments across all days.
  int get exerciseCount =>
      days.fold(0, (sum, day) => sum + day.exercises.length);

  /// Number of training (non-rest) days.
  int get trainingDayCount =>
      days.where((day) => !day.isRestDay).length;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        iconCodePoint,
        isActive,
        days,
        createdAt,
        updatedAt,
      ];
}
