// WeightEntry model for the Forge application.
//
// A single daily weigh-in. Kept separate from BodyMeasurement so weight
// trends can be charted independently of full body measurements.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'weight_entry.g.dart';

/// A recorded body weight for one date.
@HiveType(typeId: 7)
class WeightEntry extends Equatable implements Identifiable {
  /// Creates a [WeightEntry].
  WeightEntry({
    String? id,
    required this.date,
    required this.weight,
  }) : id = id ?? generateId();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The weigh-in date (calendar day precision).
  @HiveField(1)
  final DateTime date;

  /// Body weight in the user's weight unit.
  @HiveField(2)
  final double weight;

  /// Returns a copy with the given fields replaced.
  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weight,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': toIsoString(date),
        'weight': weight,
      };

  /// Deserializes from a map produced by [toMap].
  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String?,
      date: parseIsoDate(map['date'] as String),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory WeightEntry.fromJson(Map<String, dynamic> map) =>
      WeightEntry.fromMap(map);

  @override
  List<Object?> get props => [id, date, weight];
}
