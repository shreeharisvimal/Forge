// Human-friendly number and duration formatting for the workout session.
//
// Pure functions only — no Flutter imports. All strings are plain text; the
// UI renders them through its own typography.
library;

import '../../../models/settings_model.dart';

/// Weight unit handling ('kg' / 'lb').
enum SessionWeightUnit {
  /// Metric kilograms.
  kg,

  /// Imperial pounds.
  lb;

  /// Parses a [SettingsModel.weightUnit] string.
  static SessionWeightUnit fromSettings(String? unit) =>
      unit == 'lb' ? SessionWeightUnit.lb : SessionWeightUnit.kg;

  /// Pounds per kilogram conversion factor.
  static const double poundsPerKg = 2.2046226218;
}

/// Plain-text formatting helpers for session numbers.
abstract final class SessionFormatters {
  SessionFormatters._();

  /// Formats a weight in the given unit, trimming trailing zeros.
  ///
  /// Values below the whole-unit precision keep one decimal.
  static String weight(double kilograms, SessionWeightUnit unit) {
    final value =
        unit == SessionWeightUnit.kg ? kilograms : kilograms * SessionWeightUnit.poundsPerKg;
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  /// Formats a weight including the unit label, e.g. "80 kg" or "176.4 lb".
  static String weightWithUnit(double kilograms, SessionWeightUnit unit) =>
      '${weight(kilograms, unit)} ${unit == SessionWeightUnit.kg ? 'kg' : 'lb'}';

  /// Formats an estimated one-rep max.
  static String oneRepMax(double kilograms, SessionWeightUnit unit) =>
      weight(kilograms, unit);

  /// Formats a rep count, e.g. "12".
  static String reps(int count) => count.toString();

  /// Formats volume in the user's unit, e.g. "1,250 kg".
  static String volume(double kilograms, SessionWeightUnit unit) {
    final value =
        unit == SessionWeightUnit.kg ? kilograms : kilograms * SessionWeightUnit.poundsPerKg;
    final rounded = value.round();
    return '${_groupThousands(rounded)} ${unit == SessionWeightUnit.kg ? 'kg' : 'lb'}';
  }

  /// Formats a short duration such as "45s", "4m 20s", "1h 05m".
  static String shortDuration(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 1 << 30);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    if (minutes > 0) return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
    return '${secs}s';
  }

  /// Formats a clock count-up such as "04:12" or "1:04:12".
  static String clock(int totalSeconds) {
    final seconds = totalSeconds.clamp(0, 1 << 30);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Formats a long duration such as "1h 23m" or "34m".
  static String longDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  static String _groupThousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}
