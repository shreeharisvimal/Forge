// BodyGoal model for the Forge application.
//
// An optional target for a single body measurement field, e.g. "reduce waist
// to 85 cm" or "grow arms to 40 cm". Goals are directional: the engine infers
// whether the target requires a reduction or an increase from the field's
// natural direction (see [BodyField.prefersReduction]).
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../../core/utils/ids.dart';
import '../../../models/identifiable.dart';
import 'body_measurement_fields.dart';

part 'body_goals.g.dart';

/// A target value for one [BodyField].
@HiveType(typeId: 16)
class BodyGoal extends Equatable implements Identifiable {
  /// Creates a body goal.
  BodyGoal({
    String? id,
    required this.field,
    required this.target,
    required this.createdAt,
  }) : id = id ?? generateId();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The measurement the goal applies to.
  @HiveField(1)
  final BodyField field;

  /// The target value in the user's selected unit.
  @HiveField(2)
  final double target;

  /// When the goal was created.
  @HiveField(3)
  final DateTime createdAt;

  /// Returns a copy with the given fields replaced.
  BodyGoal copyWith({
    String? id,
    BodyField? field,
    double? target,
    DateTime? createdAt,
  }) {
    return BodyGoal(
      id: id ?? this.id,
      field: field ?? this.field,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'field': field.name,
        'target': target,
        'createdAt': toIsoString(createdAt),
      };

  /// Deserializes from a map produced by [toMap].
  factory BodyGoal.fromMap(Map<String, dynamic> map) {
    return BodyGoal(
      id: map['id'] as String?,
      field: BodyField.values.byName(map['field'] as String),
      target: (map['target'] as num).toDouble(),
      createdAt: parseIsoDate(map['createdAt'] as String),
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory BodyGoal.fromJson(Map<String, dynamic> map) =>
      BodyGoal.fromMap(map);

  @override
  List<Object?> get props => [id, field, target, createdAt];
}
