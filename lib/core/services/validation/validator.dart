// Central validation facade for the Forge application.
//
// Validator is a single injectable entry point for every input check used by
// forms and repositories. It delegates the shared rules to the top-level
// helpers in core/utils/validation.dart so there is exactly one source of
// truth, and layers a few service-specific rules (measurements, file names,
// durations) on top.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/validation.dart' as validation;

/// Facade exposing every input validator used by the app.
///
/// Methods are pure: they return an error message when [value] is invalid and
/// null when it is acceptable, so form fields can render the message
/// directly. Const-constructible so it can be supplied as a static
/// dependency and injected anywhere.
class Validator {
  /// Creates a validator.
  const Validator();

  /// Maximum accepted file name length.
  static const int _maxFileNameLength = 120;

  /// Shortest accepted duration in minutes.
  static const int _minDurationMinutes = 1;

  /// Longest accepted duration in minutes (24 hours).
  static const int _maxDurationMinutes = 1440;

  /// Message for a missing measurement.
  static const String _measurementRequired = 'Measurement is required.';

  /// Message for a non-positive measurement.
  static const String _measurementPositive =
      'Measurement must be greater than zero.';

  /// Message for a missing date.
  static const String _dateRequired = 'Date is required.';

  /// Message for a missing duration.
  static const String _durationRequired = 'Duration is required.';

  /// Message for an out-of-range duration.
  static const String _durationRange =
      'Duration must be between 1 and 1440 minutes.';

  /// Message for a missing file name.
  static const String _fileNameRequired = 'File name is required.';

  /// Message for a file name with illegal characters.
  static const String _fileNameChars =
      'File name must not contain /, \\ or NUL characters.';

  /// Message for an over-long file name.
  static const String _fileNameLength =
      'File name must be 120 characters or fewer.';

  /// Message for a missing file path.
  static const String _pathRequired = 'File path is required.';

  /// Message for a path without an extension.
  static const String _extensionMissing =
      'File path must include a file extension.';

  /// Validates an exercise or template name.
  String? name(String? value) => validation.validateName(value);

  /// Validates a workout name (workouts share the name rule).
  String? workoutName(String? value) => validation.validateName(value);

  /// Validates an exercise name (exercises share the name rule).
  String? exerciseName(String? value) => validation.validateName(value);

  /// Validates a weight value (must be greater than zero).
  String? weight(double? value) => validation.validateWeight(value);

  /// Validates a rep count (1-1000).
  String? reps(int? value) => validation.validateReps(value);

  /// Validates a rest timer duration in seconds (0-3600).
  String? restTimer(int? value) => validation.validateRestTimer(value);

  /// Validates an optional weekday (null is allowed, otherwise 1-7).
  String? weekday(int? value) => validation.validateWeekday(value);

  /// Validates a body measurement (must be a positive number).
  ///
  /// Shares the weight rule but reports its own message.
  String? measurement(double? value) {
    if (value == null) return _measurementRequired;
    if (value <= 0) return _measurementPositive;
    return null;
  }

  /// Validates a required date (null is rejected).
  String? date(DateTime? value) => value == null ? _dateRequired : null;

  /// Validates an optional date (null or any [DateTime] is accepted).
  String? optionalDate(DateTime? value) => null;

  /// Validates a duration in minutes (1-1440).
  String? durationMinutes(int? value) {
    if (value == null) return _durationRequired;
    if (value < _minDurationMinutes || value > _maxDurationMinutes) {
      return _durationRange;
    }
    return null;
  }

  /// Validates a file name (non-empty, no `/`, `\` or NUL, at most 120 chars).
  String? fileName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return _fileNameRequired;
    if (name.contains('/') || name.contains('\\') || name.contains('\u0000')) {
      return _fileNameChars;
    }
    if (name.length > _maxFileNameLength) return _fileNameLength;
    return null;
  }

  /// Validates that [path] has a non-empty file extension.
  String? fileExtension(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return _pathRequired;
    final dot = value.lastIndexOf('.');
    if (dot < 0 || dot == value.length - 1) return _extensionMissing;
    return null;
  }

  /// Whether [unit] is a known weight unit.
  bool isValidWeightUnit(String unit) => validation.isValidWeightUnit(unit);

  /// Whether [unit] is a known length unit.
  bool isValidLengthUnit(String unit) => validation.isValidLengthUnit(unit);

  /// Whether [mode] is a known theme mode.
  bool isValidThemeMode(String mode) => validation.isValidThemeMode(mode);

  /// Whether [value] parses as a number.
  bool isNumeric(String value) => double.tryParse(value.trim()) != null;
}

/// Provides the shared [Validator] instance.
final validatorProvider = Provider<Validator>((ref) => const Validator());
