// Riverpod providers for the Forge application.
//
// Exposes the [DatabaseService] and every repository to the widget tree.
// [databaseServiceProvider] is overridden in `main()` with the instance
// initialized before `runApp`; everything else derives from it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/services/backup/backup_engine.dart';
import '../core/services/data_registry.dart';
import '../core/services/export/export_engine.dart';
import '../core/services/import/import_engine.dart';
import '../database/database_service.dart';
import '../features/body/data/body_goal_repository.dart';
import '../features/prs/data/pr_event_repository.dart';
import '../models/settings_model.dart';
import 'repositories/calendar_repository.dart';
import 'repositories/exercise_history_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/measurement_repository.dart';
import 'repositories/personal_record_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/weight_repository.dart';
import 'repositories/workout_repository.dart';
import 'repositories/workout_session_repository.dart';
import 'repositories/workout_split_repository.dart';
import 'repositories/workout_template_repository.dart';

/// The initialized [DatabaseService]. Overridden in `main()`.
///
/// Reading this provider outside of `main`'s override is a programming error
/// and throws, which surfaces wiring mistakes immediately.
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => throw UnimplementedError(
    'databaseServiceProvider must be overridden in main() before runApp.',
  ),
);

/// Repository for [Workout] plans.
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => HiveWorkoutRepository(ref.watch(databaseServiceProvider).workoutBox),
);

/// Repository for performed [WorkoutSession] records.
final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>(
  (ref) => HiveWorkoutSessionRepository(
    ref.watch(databaseServiceProvider).sessionBox,
  ),
);

/// Repository for the [Exercise] library.
final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => HiveExerciseRepository(
    ref.watch(databaseServiceProvider).exerciseBox,
  ),
);

/// Repository for [ExerciseHistory] aggregates.
final exerciseHistoryRepositoryProvider = Provider<ExerciseHistoryRepository>(
  (ref) => HiveExerciseHistoryRepository(
    ref.watch(databaseServiceProvider).historyBox,
  ),
);

/// Repository for [CalendarDay] rows.
final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => HiveCalendarRepository(
    ref.watch(databaseServiceProvider).calendarBox,
  ),
);

/// Repository for [WeightEntry] weigh-ins.
final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => HiveWeightRepository(ref.watch(databaseServiceProvider).weightBox),
);

/// Repository for [BodyMeasurement] records.
final measurementRepositoryProvider = Provider<MeasurementRepository>(
  (ref) => HiveMeasurementRepository(
    ref.watch(databaseServiceProvider).measurementBox,
  ),
);

/// Repository for [WorkoutTemplate] routines.
final workoutTemplateRepositoryProvider = Provider<WorkoutTemplateRepository>(
  (ref) => HiveWorkoutTemplateRepository(
    ref.watch(databaseServiceProvider).templateBox,
  ),
);

/// Repository for [WorkoutSplit] weekly plans.
final workoutSplitRepositoryProvider = Provider<WorkoutSplitRepository>(
  (ref) => HiveWorkoutSplitRepository(
    ref.watch(databaseServiceProvider).splitBox,
  ),
);

/// Repository for [PersonalRecord] bests.
final personalRecordRepositoryProvider = Provider<PersonalRecordRepository>(
  (ref) => HivePersonalRecordRepository(
    ref.watch(databaseServiceProvider).prBox,
  ),
);

/// Repository for the append-only [PrEvent] timeline.
final prEventRepositoryProvider = Provider<PrEventRepository>(
  (ref) => HivePrEventRepository(
    ref.watch(databaseServiceProvider).prEventsBox,
  ),
);

/// Repository for [BodyGoal] targets.
final bodyGoalRepositoryProvider = Provider<BodyGoalRepository>(
  (ref) => HiveBodyGoalRepository(
    ref.watch(databaseServiceProvider).bodyGoalsBox,
  ),
);

/// Repository for the single [SettingsModel] document.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(
    ref.watch(databaseServiceProvider).settingsBox,
  ),
);

/// Re-emits on every change to the settings box.
///
/// Watched by [settingsProvider] so every feature that reads settings stays
/// live after any save, from any tab.
final settingsBoxChangesProvider = StreamProvider<BoxEvent>(
  (ref) => ref.watch(databaseServiceProvider).settingsBox.watch(),
);

/// The current [SettingsModel], falling back to defaults on a fresh install.
///
/// Reactive: re-reads the settings box whenever it changes so appearance and
/// unit preferences propagate to every feature instantly.
final settingsProvider = Provider<SettingsModel>((ref) {
  ref.watch(settingsBoxChangesProvider);
  return ref.watch(settingsRepositoryProvider).current ?? SettingsModel();
});

/// Reads/writes whole-dataset snapshots against the live Hive boxes.
final dataSnapshotSourceProvider = Provider<DataSnapshotSource>(
  (ref) => HiveDataSnapshotSource(ref.watch(databaseServiceProvider)),
);

/// Exports every boxed collection as a versioned, checksummed bundle.
final exportEngineProvider = Provider<ExportEngine>(
  (ref) => ExportEngine(ref.watch(dataSnapshotSourceProvider)),
);

/// Validates and merges imported bundles into storage.
final importEngineProvider = Provider<ImportEngine>(
  (ref) => ImportEngine(ref.watch(dataSnapshotSourceProvider)),
);

/// Creates, validates and restores whole-dataset backups.
final backupEngineProvider = Provider<BackupEngine>(
  (ref) => BackupEngine(ref.watch(dataSnapshotSourceProvider)),
);
