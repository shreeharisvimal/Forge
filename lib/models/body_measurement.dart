// BodyMeasurement model for the Forge application.
//
// A full set of body circumferences and composition taken on a single day.
// All girths are optional so users can log partial measurements.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'body_measurement.g.dart';

/// A day's body measurements.
@HiveType(typeId: 8)
class BodyMeasurement extends Equatable implements Identifiable {
  /// Creates a [BodyMeasurement].
  BodyMeasurement({
    String? id,
    required this.date,
    this.weight,
    this.waist,
    this.neck,
    this.chest,
    this.shoulders,
    this.leftArm,
    this.rightArm,
    this.leftForearm,
    this.rightForearm,
    this.leftThigh,
    this.rightThigh,
    this.leftCalf,
    this.rightCalf,
    this.bodyFat,
    this.hip,
    this.notes = '',
    List<String>? photos,
    List<String>? photoThumbs,
  })  : id = id ?? generateId(),
        photos = photos ?? const [],
        photoThumbs = photoThumbs ?? const [];

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// Measurement date (calendar day precision).
  @HiveField(1)
  final DateTime date;

  /// Body weight (optional — see WeightEntry for dedicated tracking).
  @HiveField(2)
  final double? weight;

  /// Waist circumference.
  @HiveField(3)
  final double? waist;

  /// Neck circumference.
  @HiveField(4)
  final double? neck;

  /// Chest circumference.
  @HiveField(5)
  final double? chest;

  /// Shoulder circumference.
  @HiveField(6)
  final double? shoulders;

  /// Left upper arm circumference.
  @HiveField(7)
  final double? leftArm;

  /// Right upper arm circumference.
  @HiveField(8)
  final double? rightArm;

  /// Left forearm circumference.
  @HiveField(9)
  final double? leftForearm;

  /// Right forearm circumference.
  @HiveField(10)
  final double? rightForearm;

  /// Left thigh circumference.
  @HiveField(11)
  final double? leftThigh;

  /// Right thigh circumference.
  @HiveField(12)
  final double? rightThigh;

  /// Left calf circumference.
  @HiveField(13)
  final double? leftCalf;

  /// Right calf circumference.
  @HiveField(14)
  final double? rightCalf;

  /// Estimated body-fat percentage.
  @HiveField(15)
  final double? bodyFat;

  /// Hip circumference.
  @HiveField(16)
  final double? hip;

  /// Free-form notes for this measurement day.
  @HiveField(17)
  final String notes;

  /// Local file paths of the day's progress photos.
  @HiveField(18)
  final List<String> photos;

  /// Local file paths of the small thumbnails for [photos].
  @HiveField(19)
  final List<String> photoThumbs;

  /// Whether no content is recorded — all fields empty and no photos/notes.
  bool get isEmpty =>
      weight == null &&
      waist == null &&
      neck == null &&
      chest == null &&
      shoulders == null &&
      leftArm == null &&
      rightArm == null &&
      leftForearm == null &&
      rightForearm == null &&
      leftThigh == null &&
      rightThigh == null &&
      leftCalf == null &&
      rightCalf == null &&
      bodyFat == null &&
      hip == null &&
      notes.isEmpty &&
      photos.isEmpty;

  /// Returns a copy with the given fields replaced.
  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    double? Function()? weight,
    double? Function()? waist,
    double? Function()? neck,
    double? Function()? chest,
    double? Function()? shoulders,
    double? Function()? leftArm,
    double? Function()? rightArm,
    double? Function()? leftForearm,
    double? Function()? rightForearm,
    double? Function()? leftThigh,
    double? Function()? rightThigh,
    double? Function()? leftCalf,
    double? Function()? rightCalf,
    double? Function()? bodyFat,
    double? Function()? hip,
    String? notes,
    List<String>? photos,
    List<String>? photoThumbs,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight != null ? weight() : this.weight,
      waist: waist != null ? waist() : this.waist,
      neck: neck != null ? neck() : this.neck,
      chest: chest != null ? chest() : this.chest,
      shoulders: shoulders != null ? shoulders() : this.shoulders,
      leftArm: leftArm != null ? leftArm() : this.leftArm,
      rightArm: rightArm != null ? rightArm() : this.rightArm,
      leftForearm: leftForearm != null ? leftForearm() : this.leftForearm,
      rightForearm: rightForearm != null ? rightForearm() : this.rightForearm,
      leftThigh: leftThigh != null ? leftThigh() : this.leftThigh,
      rightThigh: rightThigh != null ? rightThigh() : this.rightThigh,
      leftCalf: leftCalf != null ? leftCalf() : this.leftCalf,
      rightCalf: rightCalf != null ? rightCalf() : this.rightCalf,
      bodyFat: bodyFat != null ? bodyFat() : this.bodyFat,
      hip: hip != null ? hip() : this.hip,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      photoThumbs: photoThumbs ?? this.photoThumbs,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': toIsoString(date),
        'weight': weight,
        'waist': waist,
        'neck': neck,
        'chest': chest,
        'shoulders': shoulders,
        'leftArm': leftArm,
        'rightArm': rightArm,
        'leftForearm': leftForearm,
        'rightForearm': rightForearm,
        'leftThigh': leftThigh,
        'rightThigh': rightThigh,
        'leftCalf': leftCalf,
        'rightCalf': rightCalf,
        'bodyFat': bodyFat,
        'hip': hip,
        'notes': notes,
        'photos': photos,
        'photoThumbs': photoThumbs,
      };

  /// Deserializes from a map produced by [toMap].
  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as String?,
      date: parseIsoDate(map['date'] as String),
      weight: (map['weight'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      chest: (map['chest'] as num?)?.toDouble(),
      shoulders: (map['shoulders'] as num?)?.toDouble(),
      leftArm: (map['leftArm'] as num?)?.toDouble(),
      rightArm: (map['rightArm'] as num?)?.toDouble(),
      leftForearm: (map['leftForearm'] as num?)?.toDouble(),
      rightForearm: (map['rightForearm'] as num?)?.toDouble(),
      leftThigh: (map['leftThigh'] as num?)?.toDouble(),
      rightThigh: (map['rightThigh'] as num?)?.toDouble(),
      leftCalf: (map['leftCalf'] as num?)?.toDouble(),
      rightCalf: (map['rightCalf'] as num?)?.toDouble(),
      bodyFat: (map['bodyFat'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      notes: map['notes'] as String? ?? '',
      photos: [
        for (final path in (map['photos'] as List? ?? const []))
          path as String,
      ],
      photoThumbs: [
        for (final path in (map['photoThumbs'] as List? ?? const []))
          path as String,
      ],
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory BodyMeasurement.fromJson(Map<String, dynamic> map) =>
      BodyMeasurement.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        date,
        weight,
        waist,
        neck,
        chest,
        shoulders,
        leftArm,
        rightArm,
        leftForearm,
        rightForearm,
        leftThigh,
        rightThigh,
        leftCalf,
        rightCalf,
        bodyFat,
        hip,
        notes,
        photos,
        photoThumbs,
      ];
}
