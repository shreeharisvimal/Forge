// Hive box name registry for the Forge application.
//
// Single source of truth for every Hive box name. All storage reads and
// writes reference these constants, so a box is opened and accessed under
// the exact same key everywhere — and renaming a box is a one-line change.
library;

/// Registered Hive box names.
///
/// IMPORTANT: these names are persisted on disk. Changing a value breaks
/// access to previously stored data — treat every constant as immutable.
abstract final class BoxNames {
  BoxNames._();

  /// Stores [CalendarDay] rows, one per training calendar date.
  static const String calendar = 'calendar_box';

  /// Stores [Workout] plans (saved routines referencing exercises).
  static const String workouts = 'workout_box';

  /// Stores [Exercise] library entries (including seeded defaults).
  static const String exercises = 'exercise_box';

  /// Stores [BodyMeasurement] records.
  static const String measurements = 'measurement_box';

  /// Stores the single [SettingsModel] preferences document.
  static const String settings = 'settings_box';

  /// Stores [WorkoutTemplate] routines.
  static const String templates = 'template_box';

  /// Stores [WorkoutSplit] weekly training plans.
  static const String splits = 'split_box';

  /// Stores [PersonalRecord] rows.
  static const String prs = 'pr_box';

  /// Stores [WorkoutSession] records of actually performed workouts.
  static const String sessions = 'session_box';

  /// Stores the single active (in-progress) [WorkoutSession] document.
  static const String activeSession = 'active_session_box';

  /// Stores [ExerciseHistory] aggregates.
  static const String history = 'history_box';

  /// Stores [WeightEntry] daily weigh-ins.
  static const String weight = 'weight_box';

  /// Stores the append-only [PrEvent] timeline.
  static const String prEvents = 'pr_event_box';

  /// Stores [BodyGoal] targets.
  static const String bodyGoals = 'body_goal_box';

  /// Stores internal metadata such as the schema version.
  static const String meta = 'meta_box';
}
