// DatabaseService for the Forge application.
//
// Owns the entire Hive bootstrap: initialization, adapter registration,
// eager box opening and the schema-version bookkeeping used by the seeder.
// The app must call [initialize] once before `runApp` — boxes are opened
// eagerly so feature code never hits a lazy-open race.
//
// NOTE ON HIVE SCHEMA: @HiveField indexes are persisted. Never renumber or
// remove an existing index; append new fields at the end with the next index.
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../features/body/domain/body_goals.dart';
import '../features/body/domain/body_measurement_fields.dart';
import '../features/prs/data/pr_event.dart';
import '../models/body_measurement.dart';
import '../models/calendar_day.dart';
import '../models/exercise.dart';
import '../models/exercise_history.dart';
import '../models/personal_record.dart';
import '../models/settings_model.dart';
import '../models/weight_entry.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../models/workout_split.dart';
import '../models/workout_split_day.dart';
import '../models/workout_split_exercise.dart';
import '../models/workout_template.dart';
import 'box_names.dart';

/// Thrown when Hive cannot be initialized or a box cannot be opened.
class DatabaseException implements Exception {
  /// Creates a [DatabaseException] with a message.
  const DatabaseException(this.message);

  /// Human-readable description of the failure.
  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}

/// Owns the Hive lifecycle and exposes every box used by the app.
class DatabaseService {
  DatabaseService._();

  /// The current storage schema version. Bump when a migration is required.
  static const int schemaVersion = 1;

  /// Key in [metaBox] that stores the applied schema version.
  static const String _schemaVersionKey = 'schema_version';

  /// Initializes Hive, registers adapters and opens every box eagerly.
  ///
  /// [directory] overrides the storage location — used by tests to point
  /// Hive at a temporary folder instead of the path_provider directory.
  /// On any failure the partially opened boxes are closed before the error
  /// is rethrown as a [DatabaseException].
  static Future<DatabaseService> initialize({String? directory}) async {
    final service = DatabaseService._();
    try {
      await service._bootstrap(directory);
    } catch (error, stackTrace) {
      try {
        await service.close();
      } catch (_) {
        // Best-effort cleanup; the original error is the one that matters.
      }
      throw DatabaseException('Failed to initialize storage: $error\n$stackTrace');
    }
    return service;
  }

  Future<void> _bootstrap(String? directory) async {
    if (directory == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(directory);
    }

    // --- Adapter registration ------------------------------------------
    // Order is irrelevant; the typeId written into each record is what
    // matters and it must never collide between models. Registration is
    // guarded so re-initializing in the same isolate (e.g. test files) is
    // safe.
    _registerAdapter(WorkoutAdapter());
    _registerAdapter(WorkoutSessionAdapter());
    _registerAdapter(WorkoutSetAdapter());
    _registerAdapter(WorkoutExerciseAdapter());
    _registerAdapter(ExerciseAdapter());
    _registerAdapter(ExerciseHistoryAdapter());
    _registerAdapter(CalendarDayAdapter());
    _registerAdapter(WeightEntryAdapter());
    _registerAdapter(BodyMeasurementAdapter());
    _registerAdapter(WorkoutTemplateAdapter());
    _registerAdapter(PersonalRecordAdapter());
    _registerAdapter(SettingsModelAdapter());
    _registerAdapter(WorkoutSplitAdapter());
    _registerAdapter(WorkoutSplitDayAdapter());
    _registerAdapter(WorkoutSplitExerciseAdapter());
    _registerAdapter(PrEventAdapter());
    _registerAdapter(BodyGoalAdapter());
    _registerAdapter(BodyFieldAdapter());

    // --- Eager box opening ---------------------------------------------
    // Every box the app uses is opened now so later access is synchronous.
    await Future.wait([
      Hive.openBox<CalendarDay>(BoxNames.calendar),
      Hive.openBox<Workout>(BoxNames.workouts),
      Hive.openBox<Exercise>(BoxNames.exercises),
      Hive.openBox<BodyMeasurement>(BoxNames.measurements),
      Hive.openBox<SettingsModel>(BoxNames.settings),
      Hive.openBox<WorkoutTemplate>(BoxNames.templates),
      Hive.openBox<WorkoutSplit>(BoxNames.splits),
      Hive.openBox<PersonalRecord>(BoxNames.prs),
      Hive.openBox<WorkoutSession>(BoxNames.sessions),
      Hive.openBox<WorkoutSession>(BoxNames.activeSession),
      Hive.openBox<ExerciseHistory>(BoxNames.history),
      Hive.openBox<WeightEntry>(BoxNames.weight),
      Hive.openBox<PrEvent>(BoxNames.prEvents),
      Hive.openBox<BodyGoal>(BoxNames.bodyGoals),
      Hive.openBox<dynamic>(BoxNames.meta),
    ]);
  }

  /// Registers [adapter] unless a typeId adapter is already registered.
  ///
  /// Keeps repeated [initialize] calls idempotent within an isolate.
  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // --- Box accessors ----------------------------------------------------

  /// Box of [CalendarDay] rows, one per training calendar date.
  Box<CalendarDay> get calendarBox => Hive.box<CalendarDay>(BoxNames.calendar);

  /// Box of [Workout] plans.
  Box<Workout> get workoutBox => Hive.box<Workout>(BoxNames.workouts);

  /// Box of [Exercise] library entries.
  Box<Exercise> get exerciseBox => Hive.box<Exercise>(BoxNames.exercises);

  /// Box of [BodyMeasurement] records.
  Box<BodyMeasurement> get measurementBox =>
      Hive.box<BodyMeasurement>(BoxNames.measurements);

  /// Box holding the single [SettingsModel] document.
  Box<SettingsModel> get settingsBox =>
      Hive.box<SettingsModel>(BoxNames.settings);

  /// Box of [WorkoutTemplate] routines.
  Box<WorkoutTemplate> get templateBox =>
      Hive.box<WorkoutTemplate>(BoxNames.templates);

  /// Box of [WorkoutSplit] weekly training plans.
  Box<WorkoutSplit> get splitBox => Hive.box<WorkoutSplit>(BoxNames.splits);

  /// Box of [PersonalRecord] rows.
  Box<PersonalRecord> get prBox => Hive.box<PersonalRecord>(BoxNames.prs);

  /// Box of [WorkoutSession] performed-workout records.
  Box<WorkoutSession> get sessionBox =>
      Hive.box<WorkoutSession>(BoxNames.sessions);

  /// Box holding the single active (in-progress) [WorkoutSession].
  ///
  /// At most one record lives here at a time; it is the durable anchor for a
  /// session that survives app restarts mid-workout.
  Box<WorkoutSession> get activeSessionBox =>
      Hive.box<WorkoutSession>(BoxNames.activeSession);

  /// Box of [ExerciseHistory] aggregates.
  Box<ExerciseHistory> get historyBox =>
      Hive.box<ExerciseHistory>(BoxNames.history);

  /// Box of [WeightEntry] daily weigh-ins.
  Box<WeightEntry> get weightBox => Hive.box<WeightEntry>(BoxNames.weight);

  /// Box of the append-only [PrEvent] timeline.
  Box<PrEvent> get prEventsBox => Hive.box<PrEvent>(BoxNames.prEvents);

  /// Box of [BodyGoal] targets.
  Box<BodyGoal> get bodyGoalsBox => Hive.box<BodyGoal>(BoxNames.bodyGoals);

  /// Box of internal metadata such as the schema version.
  Box<dynamic> get metaBox => Hive.box<dynamic>(BoxNames.meta);

  // --- Schema bookkeeping -------------------------------------------------

  /// The schema version currently applied on disk, if any.
  int? get appliedSchemaVersion => metaBox.get(_schemaVersionKey) as int?;

  /// Whether the storage has not been initialized yet (fresh install).
  bool get isFirstLaunch => !metaBox.containsKey(_schemaVersionKey);

  /// Persists the current schema version after seeding completes.
  Future<void> markSchemaApplied() => metaBox.put(_schemaVersionKey, schemaVersion);

  // --- Lifecycle -----------------------------------------------------------

  /// Closes every open box and shuts Hive down.
  Future<void> close() async {
    await Hive.close();
  }
}
