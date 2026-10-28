// CalendarDay model for the Forge application.
//
// One row per calendar date holding daily lifestyle/wellness markers and
// the optional daily weigh-in. Powers the calendar tab without scanning
// the session box.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'calendar_day.g.dart';

/// A single day on the training calendar.
@HiveType(typeId: 6)
class CalendarDay extends Equatable implements Identifiable {
  /// Creates a [CalendarDay].
  CalendarDay({
    String? id,
    required this.date,
    this.weight,
    this.workoutCompleted = false,
    this.sleepHours,
    this.waterLitres,
    this.mood,
    this.notes = '',
    this.durationMinutes = 0,
    List<String>? photos,
    List<String>? photoThumbs,
  })  : id = id ?? generateId(),
        photos = photos ?? const [],
        photoThumbs = photoThumbs ?? const [];

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// The calendar date (calendar day precision).
  @HiveField(1)
  final DateTime date;

  /// Optional daily weigh-in.
  @HiveField(2)
  final double? weight;

  /// Whether a workout was logged that day.
  @HiveField(3)
  final bool workoutCompleted;

  /// Hours slept (optional).
  @HiveField(4)
  final double? sleepHours;

  /// Litres of water consumed (optional).
  @HiveField(5)
  final double? waterLitres;

  /// Subjective mood rating, e.g. 1-5 (optional).
  @HiveField(6)
  final int? mood;

  /// Free-form daily notes.
  @HiveField(7)
  final String notes;

  /// Minutes trained that day.
  @HiveField(8)
  final int durationMinutes;

  /// Local file paths of the day's progress photos.
  @HiveField(9)
  final List<String> photos;

  /// Local file paths of the small thumbnails for [photos].
  @HiveField(10)
  final List<String> photoThumbs;

  /// Returns a copy with the given fields replaced.
  CalendarDay copyWith({
    String? id,
    DateTime? date,
    double? Function()? weight,
    bool? workoutCompleted,
    double? Function()? sleepHours,
    double? Function()? waterLitres,
    int? Function()? mood,
    String? notes,
    int? durationMinutes,
    List<String>? photos,
    List<String>? photoThumbs,
  }) {
    return CalendarDay(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight != null ? weight() : this.weight,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      sleepHours: sleepHours != null ? sleepHours() : this.sleepHours,
      waterLitres: waterLitres != null ? waterLitres() : this.waterLitres,
      mood: mood != null ? mood() : this.mood,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      photos: photos ?? this.photos,
      photoThumbs: photoThumbs ?? this.photoThumbs,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': toIsoString(date),
        'weight': weight,
        'workoutCompleted': workoutCompleted,
        'sleepHours': sleepHours,
        'waterLitres': waterLitres,
        'mood': mood,
        'notes': notes,
        'durationMinutes': durationMinutes,
        'photos': photos,
        'photoThumbs': photoThumbs,
      };

  /// Deserializes from a map produced by [toMap].
  factory CalendarDay.fromMap(Map<String, dynamic> map) {
    return CalendarDay(
      id: map['id'] as String?,
      date: parseIsoDate(map['date'] as String),
      weight: (map['weight'] as num?)?.toDouble(),
      workoutCompleted: map['workoutCompleted'] as bool? ?? false,
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      waterLitres: (map['waterLitres'] as num?)?.toDouble(),
      mood: (map['mood'] as num?)?.toInt(),
      notes: map['notes'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
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
  factory CalendarDay.fromJson(Map<String, dynamic> map) =>
      CalendarDay.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        date,
        weight,
        workoutCompleted,
        sleepHours,
        waterLitres,
        mood,
        notes,
        durationMinutes,
        photos,
        photoThumbs,
      ];
}
