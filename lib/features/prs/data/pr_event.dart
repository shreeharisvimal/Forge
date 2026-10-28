// PrEvent model for the Forge application.
//
// One row per personal record achieved: a timestamped, immutable event that
// carries the exercise, the record type, the new value, the value it beat
// and the workout that produced it. Events are append-only, which is what
// preserves the full PR history timeline across sessions.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../../core/utils/ids.dart';
import '../../../models/identifiable.dart';
import '../domain/one_rep_max.dart';
import '../domain/pr_types.dart';

part 'pr_event.g.dart';

/// A single personal record event.
@HiveType(typeId: 15)
class PrEvent extends Equatable implements Identifiable {
  /// Creates a [PrEvent].
  PrEvent({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.value,
    this.previousValue = 0,
    DateTime? date,
    this.workoutId,
    this.notes = '',
    this.formula = 'epley',
    this.calculatedOneRM = 0,
  })  : id = id ?? generateId(),
        date = date ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The exercise the record belongs to.
  @HiveField(1)
  final String exerciseId;

  /// Denormalized name so records survive exercise library edits.
  @HiveField(2)
  final String exerciseName;

  /// The record type, stored as [PrType.name].
  @HiveField(3)
  final String type;

  /// The new record value.
  @HiveField(4)
  final double value;

  /// The value this record beat (0 for a first-ever record).
  @HiveField(5)
  final double previousValue;

  /// When the record was set.
  @HiveField(6)
  final DateTime date;

  /// The workout that produced the record, if known.
  @HiveField(7)
  final String? workoutId;

  /// Free-form notes attached to the effort.
  @HiveField(8)
  final String notes;

  /// The one-rep-max formula used, stored as [OneRepMaxFormula.storageKey].
  @HiveField(9)
  final String formula;

  /// The estimated one-rep max of the effort (0 for non-lift records).
  @HiveField(10)
  final double calculatedOneRM;

  /// The parsed [PrType].
  PrType get prType =>
      PrType.values.asNameMap()[type] ?? PrType.heaviestWeight;

  /// The parsed [OneRepMaxFormula].
  OneRepMaxFormula get oneRepMaxFormula => OneRepMaxFormula.fromStorageKey(formula);

  /// Signed improvement over [previousValue].
  double get difference => value - previousValue;

  /// Returns a copy with the given fields replaced.
  PrEvent copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    String? type,
    double? value,
    double? previousValue,
    DateTime? date,
    String? Function()? workoutId,
    String? notes,
    String? formula,
    double? calculatedOneRM,
  }) {
    return PrEvent(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      type: type ?? this.type,
      value: value ?? this.value,
      previousValue: previousValue ?? this.previousValue,
      date: date ?? this.date,
      workoutId: workoutId != null ? workoutId() : this.workoutId,
      notes: notes ?? this.notes,
      formula: formula ?? this.formula,
      calculatedOneRM: calculatedOneRM ?? this.calculatedOneRM,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'type': type,
        'value': value,
        'previousValue': previousValue,
        'date': toIsoString(date),
        'workoutId': workoutId,
        'notes': notes,
        'formula': formula,
        'calculatedOneRM': calculatedOneRM,
      };

  /// Deserializes from a map produced by [toMap].
  factory PrEvent.fromMap(Map<String, dynamic> map) {
    return PrEvent(
      id: map['id'] as String?,
      exerciseId: map['exerciseId'] as String,
      exerciseName: map['exerciseName'] as String? ?? '',
      type: map['type'] as String? ?? PrType.heaviestWeight.name,
      value: (map['value'] as num?)?.toDouble() ?? 0,
      previousValue: (map['previousValue'] as num?)?.toDouble() ?? 0,
      date: map['date'] != null ? parseIsoDate(map['date'] as String) : null,
      workoutId: map['workoutId'] as String?,
      notes: map['notes'] as String? ?? '',
      formula: map['formula'] as String? ?? OneRepMaxFormula.epley.storageKey,
      calculatedOneRM: (map['calculatedOneRM'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory PrEvent.fromJson(Map<String, dynamic> map) => PrEvent.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        exerciseName,
        type,
        value,
        previousValue,
        date,
        workoutId,
        notes,
        formula,
        calculatedOneRM,
      ];
}
