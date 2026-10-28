// Body measurement fields for the Forge application.
//
// The complete vocabulary of trackable metrics on a [BodyMeasurement],
// shared by the measurement form, the history list, the comparison section
// and the charts. Values are extracted straight from the model so every
// layer reads from a single switch. The enum is Hive-typed so [BodyGoal]
// records can persist the field they target.
library;

import 'package:hive/hive.dart';

import '../../../models/body_measurement.dart';

part 'body_measurement_fields.g.dart';

/// A trackable body measurement.
@HiveType(typeId: 17)
enum BodyField {
  /// Body weight.
  @HiveField(0)
  weight,

  /// Waist circumference.
  @HiveField(1)
  waist,

  /// Hip circumference.
  @HiveField(2)
  hip,

  /// Chest circumference.
  @HiveField(3)
  chest,

  /// Neck circumference.
  @HiveField(4)
  neck,

  /// Shoulder circumference.
  @HiveField(5)
  shoulders,

  /// Left upper arm circumference.
  @HiveField(6)
  leftArm,

  /// Right upper arm circumference.
  @HiveField(7)
  rightArm,

  /// Left forearm circumference.
  @HiveField(8)
  leftForearm,

  /// Right forearm circumference.
  @HiveField(9)
  rightForearm,

  /// Left thigh circumference.
  @HiveField(10)
  leftThigh,

  /// Right thigh circumference.
  @HiveField(11)
  rightThigh,

  /// Left calf circumference.
  @HiveField(12)
  leftCalf,

  /// Right calf circumference.
  @HiveField(13)
  rightCalf,

  /// Estimated body-fat percentage.
  @HiveField(14)
  bodyFat;

  /// The human-readable field name, e.g. "Waist".
  String get label => switch (this) {
        BodyField.weight => 'Weight',
        BodyField.waist => 'Waist',
        BodyField.hip => 'Hip',
        BodyField.chest => 'Chest',
        BodyField.neck => 'Neck',
        BodyField.shoulders => 'Shoulders',
        BodyField.leftArm => 'Left arm',
        BodyField.rightArm => 'Right arm',
        BodyField.leftForearm => 'Left forearm',
        BodyField.rightForearm => 'Right forearm',
        BodyField.leftThigh => 'Left thigh',
        BodyField.rightThigh => 'Right thigh',
        BodyField.leftCalf => 'Left calf',
        BodyField.rightCalf => 'Right calf',
        BodyField.bodyFat => 'Body fat',
      };

  /// Icon key resolved by the presentation layer.
  String get iconName => switch (this) {
        BodyField.weight => 'monitor_weight',
        BodyField.bodyFat => 'percent',
        _ => 'straighten',
      };

  /// Whether the field is stored as a body-fat percentage.
  bool get isPercent => this == BodyField.bodyFat;

  /// Whether the field is body weight.
  bool get isWeight => this == BodyField.weight;

  /// Whether the field is a length circumference.
  bool get isLength => !isPercent && !isWeight;

  /// Whether a lower value is generally the desirable direction (reduction).
  bool get prefersReduction =>
      this == BodyField.waist ||
      this == BodyField.hip ||
      this == BodyField.neck ||
      this == BodyField.bodyFat ||
      this == BodyField.weight;

  /// The value of this field on [measurement], or null when unlogged.
  double? valueOf(BodyMeasurement measurement) => switch (this) {
        BodyField.weight => measurement.weight,
        BodyField.waist => measurement.waist,
        BodyField.hip => measurement.hip,
        BodyField.chest => measurement.chest,
        BodyField.neck => measurement.neck,
        BodyField.shoulders => measurement.shoulders,
        BodyField.leftArm => measurement.leftArm,
        BodyField.rightArm => measurement.rightArm,
        BodyField.leftForearm => measurement.leftForearm,
        BodyField.rightForearm => measurement.rightForearm,
        BodyField.leftThigh => measurement.leftThigh,
        BodyField.rightThigh => measurement.rightThigh,
        BodyField.leftCalf => measurement.leftCalf,
        BodyField.rightCalf => measurement.rightCalf,
        BodyField.bodyFat => measurement.bodyFat,
      };

  /// Every trackable field in display order.
  static const List<BodyField> all = [
    BodyField.weight,
    BodyField.waist,
    BodyField.hip,
    BodyField.chest,
    BodyField.neck,
    BodyField.shoulders,
    BodyField.leftArm,
    BodyField.rightArm,
    BodyField.leftForearm,
    BodyField.rightForearm,
    BodyField.leftThigh,
    BodyField.rightThigh,
    BodyField.leftCalf,
    BodyField.rightCalf,
    BodyField.bodyFat,
  ];

  /// The fields surfaced as the headline dashboard cards.
  static const List<BodyField> headlineFields = [
    BodyField.weight,
    BodyField.waist,
    BodyField.hip,
    BodyField.bodyFat,
  ];

  /// The fields available in the trend chart, oldest first.
  static const List<BodyField> chartableFields = [
    BodyField.weight,
    BodyField.waist,
    BodyField.hip,
    BodyField.chest,
    BodyField.neck,
    BodyField.shoulders,
    BodyField.leftArm,
    BodyField.rightArm,
    BodyField.leftForearm,
    BodyField.rightForearm,
    BodyField.leftThigh,
    BodyField.rightThigh,
    BodyField.leftCalf,
    BodyField.rightCalf,
    BodyField.bodyFat,
  ];
}
