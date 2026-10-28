// ExerciseHistory model for the Forge application.
//
// A daily performance snapshot for one exercise, computed from performed
// sessions. Stored so history can be rendered without re-aggregating
// every session each time the app opens.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'exercise_history.g.dart';

/// Daily performance aggregate for a single exercise.
@HiveType(typeId: 5)
class ExerciseHistory extends Equatable implements Identifiable {
  /// Creates an [ExerciseHistory] row.
  ExerciseHistory({
    String? id,
    required this.exerciseId,
    required this.date,
    this.bestWeight = 0,
    this.bestReps = 0,
    this.estimatedOneRM = 0,
    this.totalVolume = 0,
  }) : id = id ?? generateId();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The exercise this history row belongs to.
  @HiveField(1)
  final String exerciseId;

  /// The day the performance was recorded.
  @HiveField(2)
  final DateTime date;

  /// Heaviest weight lifted that day.
  @HiveField(3)
  final double bestWeight;

  /// Most reps achieved that day.
  @HiveField(4)
  final int bestReps;

  /// Estimated one-rep max (Epley formula), stored for charting.
  @HiveField(5)
  final double estimatedOneRM;

  /// Sum of weight x reps across all sets that day.
  @HiveField(6)
  final double totalVolume;

  /// Returns a copy with the given fields replaced.
  ExerciseHistory copyWith({
    String? id,
    String? exerciseId,
    DateTime? date,
    double? bestWeight,
    int? bestReps,
    double? estimatedOneRM,
    double? totalVolume,
  }) {
    return ExerciseHistory(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      date: date ?? this.date,
      bestWeight: bestWeight ?? this.bestWeight,
      bestReps: bestReps ?? this.bestReps,
      estimatedOneRM: estimatedOneRM ?? this.estimatedOneRM,
      totalVolume: totalVolume ?? this.totalVolume,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'date': toIsoString(date),
        'bestWeight': bestWeight,
        'bestReps': bestReps,
        'estimatedOneRM': estimatedOneRM,
        'totalVolume': totalVolume,
      };

  /// Deserializes from a map produced by [toMap].
  factory ExerciseHistory.fromMap(Map<String, dynamic> map) {
    return ExerciseHistory(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String,
      date: parseIsoDate(map['date'] as String),
      bestWeight: (map['bestWeight'] as num?)?.toDouble() ?? 0,
      bestReps: (map['bestReps'] as num?)?.toInt() ?? 0,
      estimatedOneRM: (map['estimatedOneRM'] as num?)?.toDouble() ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory ExerciseHistory.fromJson(Map<String, dynamic> map) =>
      ExerciseHistory.fromMap(map);

  @override
  List<Object?> get props =>
      [id, exerciseId, date, bestWeight, bestReps, estimatedOneRM, totalVolume];
}
