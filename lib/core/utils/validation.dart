// Input validation helpers for the Forge application.
//
// Every validator returns an error message when the input is invalid and
// null when it is acceptable, so form fields can render it directly.
library;

/// Allowed weight unit keys.
const Set<String> weightUnits = {'kg', 'lb'};

/// Allowed length unit keys.
const Set<String> lengthUnits = {'cm', 'in'};

/// Allowed theme mode keys.
const Set<String> themeModes = {'system', 'light', 'dark'};

/// Validates an exercise or template name.
String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Name is required.';
  if (name.length > 60) return 'Name must be 60 characters or fewer.';
  return null;
}

/// Validates a weight value (must be greater than zero).
String? validateWeight(double? value) {
  if (value == null) return 'Weight is required.';
  if (value <= 0) return 'Weight must be greater than zero.';
  return null;
}

/// Validates a rep count (1-1000).
String? validateReps(int? value) {
  if (value == null) return 'Reps are required.';
  if (value < 1 || value > 1000) return 'Reps must be between 1 and 1000.';
  return null;
}

/// Validates a rest timer duration in seconds (0-3600).
String? validateRestTimer(int? value) {
  if (value == null) return 'Rest timer is required.';
  if (value < 0 || value > 3600) {
    return 'Rest timer must be between 0 and 3600 seconds.';
  }
  return null;
}

/// Validates an optional weekday (null is allowed, otherwise 1-7).
String? validateWeekday(int? value) {
  if (value == null) return null;
  if (value < 1 || value > 7) return 'Weekday must be between 1 (Mon) and 7 (Sun).';
  return null;
}

/// Whether [unit] is a known weight unit.
bool isValidWeightUnit(String unit) => weightUnits.contains(unit);

/// Whether [unit] is a known length unit.
bool isValidLengthUnit(String unit) => lengthUnits.contains(unit);

/// Whether [mode] is a known theme mode.
bool isValidThemeMode(String mode) => themeModes.contains(mode);
