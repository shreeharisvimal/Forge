// SettingsModel for the Forge application.
//
// User preferences persisted in the settings box. Defaults are conservative
// (light theme, metric units) and can be changed from the Settings tab.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../core/utils/ids.dart';
import 'identifiable.dart';

part 'settings_model.g.dart';

/// App-wide user settings.
@HiveType(typeId: 11)
class SettingsModel extends Equatable implements Identifiable {
  /// Creates a [SettingsModel].
  SettingsModel({
    String? id,
    this.themeMode = 'system',
    this.accentColor = 'violet',
    this.weightUnit = 'kg',
    this.lengthUnit = 'cm',
    this.restTimer = 90,
    this.goalWeight,
    this.oneRepMaxFormula = 'epley',
    this.amoledMode = true,
    this.dynamicColors = false,
    this.language = 'en',
    this.hapticsEnabled = true,
    this.countdownSound = true,
    this.autoStartRestTimer = false,
    this.warmUpSets = 2,
    this.warmUpWeightPercent = 50,
    this.weightIncrement = 2.5,
    this.plateWeight = 20.0,
    this.barWeight = 20.0,
    this.unitSystem = 'metric',
    this.waterUnit = 'l',
    this.workoutRemindersEnabled = false,
    this.restRemindersEnabled = false,
    this.dailyReminderEnabled = false,
    this.weeklySummaryEnabled = false,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier (also the Hive box key).
  @override
  @HiveField(0)
  final String id;

  /// Theme: 'system', 'light', or 'dark'.
  @HiveField(1)
  final String themeMode;

  /// Accent color key, e.g. 'violet', 'blue', 'cyan'.
  @HiveField(2)
  final String accentColor;

  /// Weight unit: 'kg' or 'lb'.
  @HiveField(3)
  final String weightUnit;

  /// Length unit: 'cm' or 'in'.
  @HiveField(4)
  final String lengthUnit;

  /// Default rest timer duration in seconds.
  @HiveField(5)
  final int restTimer;

  /// Optional target body weight the user is working toward.
  @HiveField(7)
  final double? goalWeight;

  /// One-rep-max formula key, stored as [OneRepMaxFormula.storageKey] and
  /// defaulting to Epley. Changeable from settings later.
  @HiveField(8)
  final String oneRepMaxFormula;

  /// Last modification timestamp.
  @HiveField(6)
  final DateTime updatedAt;

  /// Whether the true-black (AMOLED) background is used in dark mode.
  @HiveField(9)
  final bool amoledMode;

  /// Whether the theme derives its palette from the accent seed.
  @HiveField(10)
  final bool dynamicColors;

  /// App language key (future-ready; 'en' is the only shipped locale).
  @HiveField(11)
  final String language;

  /// Whether haptic feedback is enabled app-wide.
  @HiveField(12)
  final bool hapticsEnabled;

  /// Whether the rest-timer countdown plays an audible beep.
  @HiveField(13)
  final bool countdownSound;

  /// Whether the rest timer starts automatically after a set is logged.
  @HiveField(14)
  final bool autoStartRestTimer;

  /// Default number of warm-up sets for an exercise.
  @HiveField(15)
  final int warmUpSets;

  /// Warm-up sets expressed as a percentage of the working weight.
  @HiveField(16)
  final int warmUpWeightPercent;

  /// Default plate-increment step in the active weight unit.
  @HiveField(17)
  final double weightIncrement;

  /// Default plate weight in kilograms (plate-calculator input).
  @HiveField(18)
  final double plateWeight;

  /// Default barbell weight in kilograms (plate-calculator input).
  @HiveField(19)
  final double barWeight;

  /// Unit system: 'metric' or 'imperial'.
  @HiveField(20)
  final String unitSystem;

  /// Water unit: 'l' or 'oz'.
  @HiveField(21)
  final String waterUnit;

  /// Whether workout reminders are scheduled.
  @HiveField(22)
  final bool workoutRemindersEnabled;

  /// Whether rest-time reminders are scheduled.
  @HiveField(23)
  final bool restRemindersEnabled;

  /// Whether a daily training reminder is scheduled.
  @HiveField(24)
  final bool dailyReminderEnabled;

  /// Whether a weekly summary reminder is scheduled.
  @HiveField(25)
  final bool weeklySummaryEnabled;

  /// Returns a copy with the given fields replaced.
  SettingsModel copyWith({
    String? id,
    String? themeMode,
    String? accentColor,
    String? weightUnit,
    String? lengthUnit,
    int? restTimer,
    double? Function()? goalWeight,
    String? oneRepMaxFormula,
    bool? amoledMode,
    bool? dynamicColors,
    String? language,
    bool? hapticsEnabled,
    bool? countdownSound,
    bool? autoStartRestTimer,
    int? warmUpSets,
    int? warmUpWeightPercent,
    double? weightIncrement,
    double? plateWeight,
    double? barWeight,
    String? unitSystem,
    String? waterUnit,
    bool? workoutRemindersEnabled,
    bool? restRemindersEnabled,
    bool? dailyReminderEnabled,
    bool? weeklySummaryEnabled,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      weightUnit: weightUnit ?? this.weightUnit,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      restTimer: restTimer ?? this.restTimer,
      goalWeight: goalWeight != null ? goalWeight() : this.goalWeight,
      oneRepMaxFormula: oneRepMaxFormula ?? this.oneRepMaxFormula,
      amoledMode: amoledMode ?? this.amoledMode,
      dynamicColors: dynamicColors ?? this.dynamicColors,
      language: language ?? this.language,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      countdownSound: countdownSound ?? this.countdownSound,
      autoStartRestTimer: autoStartRestTimer ?? this.autoStartRestTimer,
      warmUpSets: warmUpSets ?? this.warmUpSets,
      warmUpWeightPercent:
          warmUpWeightPercent ?? this.warmUpWeightPercent,
      weightIncrement: weightIncrement ?? this.weightIncrement,
      plateWeight: plateWeight ?? this.plateWeight,
      barWeight: barWeight ?? this.barWeight,
      unitSystem: unitSystem ?? this.unitSystem,
      waterUnit: waterUnit ?? this.waterUnit,
      workoutRemindersEnabled:
          workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      restRemindersEnabled: restRemindersEnabled ?? this.restRemindersEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes to a JSON-safe map (ISO-8601 dates).
  Map<String, dynamic> toMap() => {
        'id': id,
        'themeMode': themeMode,
        'accentColor': accentColor,
        'weightUnit': weightUnit,
        'lengthUnit': lengthUnit,
        'restTimer': restTimer,
        'goalWeight': goalWeight,
        'oneRepMaxFormula': oneRepMaxFormula,
        'updatedAt': toIsoString(updatedAt),
        'amoledMode': amoledMode,
        'dynamicColors': dynamicColors,
        'language': language,
        'hapticsEnabled': hapticsEnabled,
        'countdownSound': countdownSound,
        'autoStartRestTimer': autoStartRestTimer,
        'warmUpSets': warmUpSets,
        'warmUpWeightPercent': warmUpWeightPercent,
        'weightIncrement': weightIncrement,
        'plateWeight': plateWeight,
        'barWeight': barWeight,
        'unitSystem': unitSystem,
        'waterUnit': waterUnit,
        'workoutRemindersEnabled': workoutRemindersEnabled,
        'restRemindersEnabled': restRemindersEnabled,
        'dailyReminderEnabled': dailyReminderEnabled,
        'weeklySummaryEnabled': weeklySummaryEnabled,
      };

  /// Deserializes from a map produced by [toMap].
  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as String?,
      themeMode: map['themeMode'] as String? ?? 'system',
      accentColor: map['accentColor'] as String? ?? 'violet',
      weightUnit: map['weightUnit'] as String? ?? 'kg',
      lengthUnit: map['lengthUnit'] as String? ?? 'cm',
      restTimer: (map['restTimer'] as num?)?.toInt() ?? 90,
      goalWeight: (map['goalWeight'] as num?)?.toDouble(),
      oneRepMaxFormula: map['oneRepMaxFormula'] as String? ?? 'epley',
      amoledMode: map['amoledMode'] as bool? ?? true,
      dynamicColors: map['dynamicColors'] as bool? ?? false,
      language: map['language'] as String? ?? 'en',
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      countdownSound: map['countdownSound'] as bool? ?? true,
      autoStartRestTimer: map['autoStartRestTimer'] as bool? ?? false,
      warmUpSets: (map['warmUpSets'] as num?)?.toInt() ?? 2,
      warmUpWeightPercent: (map['warmUpWeightPercent'] as num?)?.toInt() ?? 50,
      weightIncrement: (map['weightIncrement'] as num?)?.toDouble() ?? 2.5,
      plateWeight: (map['plateWeight'] as num?)?.toDouble() ?? 20.0,
      barWeight: (map['barWeight'] as num?)?.toDouble() ?? 20.0,
      unitSystem: map['unitSystem'] as String? ?? 'metric',
      waterUnit: map['waterUnit'] as String? ?? 'l',
      workoutRemindersEnabled: map['workoutRemindersEnabled'] as bool? ?? false,
      restRemindersEnabled: map['restRemindersEnabled'] as bool? ?? false,
      dailyReminderEnabled: map['dailyReminderEnabled'] as bool? ?? false,
      weeklySummaryEnabled: map['weeklySummaryEnabled'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? parseIsoDate(map['updatedAt'] as String)
          : null,
    );
  }

  /// Alias of [toMap] for a JSON-friendly API.
  Map<String, dynamic> toJson() => toMap();

  /// Alias of [fromMap] for a JSON-friendly API.
  factory SettingsModel.fromJson(Map<String, dynamic> map) =>
      SettingsModel.fromMap(map);

  @override
  List<Object?> get props => [
        id,
        themeMode,
        accentColor,
        weightUnit,
        lengthUnit,
        restTimer,
        goalWeight,
        oneRepMaxFormula,
        amoledMode,
        dynamicColors,
        language,
        hapticsEnabled,
        countdownSound,
        autoStartRestTimer,
        warmUpSets,
        warmUpWeightPercent,
        weightIncrement,
        plateWeight,
        barWeight,
        unitSystem,
        waterUnit,
        workoutRemindersEnabled,
        restRemindersEnabled,
        dailyReminderEnabled,
        weeklySummaryEnabled,
        updatedAt,
      ];
}
