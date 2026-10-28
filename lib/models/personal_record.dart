// PersonalRecord model for the Forge application.
//
// One row per exercise holding the user's lifetime bests. Values are
// updated transactionally whenever a session is saved or deleted.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'personal_record.g.dart';

/// Lifetime personal bests for one exercise.
@HiveType(typeId: 10)
class PersonalRecord extends Equatable implements Identifiable {
  /// Creates a [PersonalRecord].
  PersonalRecord({
    String? id,
    required this.exerciseId,
    this.highestWeight = 0,
    this.bestReps = 0,
    this.estimatedOneRM = 0,
    this.bestVolume = 0,
    DateTime? lastUpdated,
  })  : id = id ?? generateId(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The exercise these records belong to.
  @HiveField(1)
  final String exerciseId;

  /// Heaviest single working weight ever lifted.
  @HiveField(2)
  final double highestWeight;

  /// Most reps achieved in a single set.
  @HiveField(3)
  final int bestReps;

  /// Highest estimated one-rep max.
  @HiveField(4)
  final double estimatedOneRM;

  /// Highest total volume (weight x reps) in a single session.
  @HiveField(5)
  final double bestVolume;

  /// When these records were last updated.
  @HiveField(6)
  final DateTime lastUpdated;

  /// Returns a copy with the given fields replaced.
  PersonalRecord copyWith({
    String? id,
    String? exerciseId,
    double? highestWeight,
    int? bestReps,
    double? estimatedOneRM,
    double? bestVolume,
    DateTime? lastUpdated,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      highestWeight: highestWeight ?? this.highestWeight,
      bestReps: bestReps ?? this.bestReps,
      estimatedOneRM: estimatedOneRM ?? this.estimatedOneRM,
      bestVolume: bestVolume ?? this.bestVolume,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'highestWeight': highestWeight,
        'bestReps': bestReps,
        'estimatedOneRM': estimatedOneRM,
        'bestVolume': bestVolume,
        'lastUpdated': toIsoString(lastUpdated),
      };

  /// Deserializes from a map produced by [toMap].
  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String,
      highestWeight: (map['highestWeight'] as num?)?.toDouble() ?? 0,
      bestReps: (map['bestReps'] as num?)?.toInt() ?? 0,
      estimatedOneRM: (map['estimatedOneRM'] as num?)?.toDouble() ?? 0,
      bestVolume: (map['bestVolume'] as num?)?.toDouble() ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? parseIsoDate(map['lastUpdated'] as String)
          : null,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory PersonalRecord.fromJson(Map<String, dynamic> map) =>
      PersonalRecord.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        highestWeight,
        bestReps,
        estimatedOneRM,
        bestVolume,
        lastUpdated,
      ];
}
