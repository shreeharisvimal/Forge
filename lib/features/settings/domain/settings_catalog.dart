// Settings domain catalog for the Forge application.
//
// The user-facing definitions of every selectable preference: theme modes,
// unit systems, rest-timer presets, warm-up defaults, plate calculator
// inputs and reminder types. Keeping these in the domain layer means the
// widgets render pure options while the model stays storage-agnostic.
library;

import 'package:flutter/material.dart';

/// The selectable app theme modes.
enum SettingsThemeMode {
  /// Follow the operating system appearance.
  system('system', 'System', Icons.brightness_auto_rounded),

  /// Always use the light theme.
  light('light', 'Light', Icons.light_mode_rounded),

  /// Always use the dark theme.
  dark('dark', 'Dark', Icons.dark_mode_rounded);

  const SettingsThemeMode(this.key, this.label, this.icon);

  /// The value persisted in [SettingsModel.themeMode].
  final String key;

  /// Human-readable label.
  final String label;

  /// Accent icon.
  final IconData icon;

  /// The mode for [key], falling back to [system] when unknown.
  static SettingsThemeMode fromKey(String? key) {
    for (final mode in values) {
      if (mode.key == key) return mode;
    }
    return system;
  }
}

/// The selectable measurement systems.
enum SettingsUnitSystem {
  /// Metric: kilograms, centimeters, liters.
  metric('metric', 'Metric', Icons.science_rounded, 'kg', 'cm', 'l'),

  /// Imperial: pounds, inches, fluid ounces.
  imperial('imperial', 'Imperial', Icons.architecture_rounded, 'lb', 'in', 'oz');

  const SettingsUnitSystem(
    this.key,
    this.label,
    this.icon,
    this.weightUnit,
    this.lengthUnit,
    this.waterUnit,
  );

  /// The value persisted in [SettingsModel.unitSystem].
  final String key;

  /// Human-readable label.
  final String label;

  /// Accent icon.
  final IconData icon;

  /// The matching [SettingsModel.weightUnit].
  final String weightUnit;

  /// The matching [SettingsModel.lengthUnit].
  final String lengthUnit;

  /// The matching [SettingsModel.waterUnit].
  final String waterUnit;

  /// The system for [key], falling back to [metric] when unknown.
  static SettingsUnitSystem fromKey(String? key) {
    for (final system in values) {
      if (system.key == key) return system;
    }
    return metric;
  }
}

/// The selectable rest-timer durations in seconds.
enum SettingsRestTimerOption {
  /// One minute.
  oneMinute(60, '1 min'),

  /// Ninety seconds.
  ninetySeconds(90, '1:30'),

  /// Two minutes.
  twoMinutes(120, '2 min'),

  /// Three minutes.
  threeMinutes(180, '3 min');

  const SettingsRestTimerOption(this.seconds, this.label);

  /// The duration in seconds.
  final int seconds;

  /// Human-readable label.
  final String label;

  /// The option closest to [seconds], defaulting to ninety seconds.
  static SettingsRestTimerOption nearest(int seconds) {
    SettingsRestTimerOption best = ninetySeconds;
    var bestDistance = double.infinity;
    for (final option in values) {
      final distance = (option.seconds - seconds).abs().toDouble();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = option;
      }
    }
    return best;
  }
}

/// One selectable option for a numeric settings picker.
class SettingsNumericOption {
  /// Creates an option.
  const SettingsNumericOption(this.value, this.label);

  /// The stored numeric value.
  final double value;

  /// Human-readable label.
  final String label;
}

/// The selectable warm-up set counts.
const List<SettingsNumericOption> kSettingsWarmUpSetOptions = [
  SettingsNumericOption(0, '0'),
  SettingsNumericOption(1, '1'),
  SettingsNumericOption(2, '2'),
  SettingsNumericOption(3, '3'),
  SettingsNumericOption(4, '4'),
];

/// The selectable warm-up weight percentages of the working weight.
const List<SettingsNumericOption> kSettingsWarmUpPercentOptions = [
  SettingsNumericOption(30, '30%'),
  SettingsNumericOption(40, '40%'),
  SettingsNumericOption(50, '50%'),
  SettingsNumericOption(60, '60%'),
  SettingsNumericOption(70, '70%'),
];

/// The selectable plate-increment steps (in the active weight unit).
const List<SettingsNumericOption> kSettingsWeightIncrementOptions = [
  SettingsNumericOption(1.25, '1.25'),
  SettingsNumericOption(2.5, '2.5'),
  SettingsNumericOption(5, '5'),
];

/// The selectable plate weights in kilograms.
const List<SettingsNumericOption> kSettingsPlateWeightOptions = [
  SettingsNumericOption(10, '10 kg'),
  SettingsNumericOption(15, '15 kg'),
  SettingsNumericOption(20, '20 kg'),
  SettingsNumericOption(25, '25 kg'),
];

/// The selectable barbell weights in kilograms.
const List<SettingsNumericOption> kSettingsBarWeightOptions = [
  SettingsNumericOption(5, '5 kg'),
  SettingsNumericOption(10, '10 kg'),
  SettingsNumericOption(15, '15 kg'),
  SettingsNumericOption(20, '20 kg'),
];

/// One selectable reminder type.
class SettingsReminderType {
  /// Creates a reminder definition.
  const SettingsReminderType({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  /// Stable key matching a [SettingsModel] reminder field.
  final String key;

  /// The reminder name.
  final String label;

  /// Supporting description.
  final String subtitle;

  /// Accent icon.
  final IconData icon;
}

/// Every selectable reminder type in display order.
const List<SettingsReminderType> kSettingsReminderTypes = [
  SettingsReminderType(
    key: 'workout',
    label: 'Workout reminders',
    subtitle: 'Remind me on my scheduled training days',
    icon: Icons.fitness_center_rounded,
  ),
  SettingsReminderType(
    key: 'rest',
    label: 'Rest-day reminders',
    subtitle: 'Nudge me to rest and recover on off days',
    icon: Icons.self_improvement_rounded,
  ),
  SettingsReminderType(
    key: 'daily',
    label: 'Daily check-in',
    subtitle: 'A daily prompt to log weight and body stats',
    icon: Icons.event_repeat_rounded,
  ),
  SettingsReminderType(
    key: 'weekly',
    label: 'Weekly summary',
    subtitle: 'A weekly recap of my training and progress',
    icon: Icons.summarize_rounded,
  ),
];

/// Formats a numeric [value] without a trailing `.0` when integral.
String formatSettingNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
