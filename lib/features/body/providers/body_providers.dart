// Body providers for the Forge application.
//
// Composes the repositories into the read models the Body tab renders.
// Every provider watches the relevant box-change stream so the tab stays
// live after any save, and the snapshot provider rebuilds only when the
// measurements, goals, range or reference clock change.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../core/services/file/file_service.dart';
import '../../../core/services/images/image_service.dart';
import '../../../models/body_measurement.dart';
import '../../../models/settings_model.dart';
import '../../../services/providers.dart';
import '../../progress/domain/analytics_range.dart';
import '../data/body_box_watchers.dart';
import '../data/body_goal_editor.dart';
import '../data/body_measurement_editor.dart';
import '../data/body_photo_service.dart';
import '../domain/body_goals.dart';
import '../domain/body_measurement_calculations.dart';
import '../domain/body_measurement_fields.dart';
import '../domain/body_measurement_models.dart';

/// The Body tab's notion of "now". Overridden in tests to pin a date.
final bodyNowProvider = Provider<DateTime>((_) => DateTime.now());

/// The selected analytics window.
final bodyRangeProvider = legacy.StateProvider<AnalyticsRange>(
  (_) => AnalyticsRange.last90Days,
);

/// The field highlighted in the trend chart.
final bodyChartFieldProvider = legacy.StateProvider<BodyField>(
  (_) => BodyField.waist,
);

/// The current [SettingsModel], reactive to the settings box.
final bodySettingsProvider = Provider<SettingsModel>((ref) {
  ref.watch(bodySettingsBoxChangesProvider);
  return ref.watch(settingsRepositoryProvider).current ?? SettingsModel();
});

/// Every stored measurement, oldest first.
final bodyMeasurementsProvider = Provider<List<BodyMeasurement>>((ref) {
  ref.watch(bodyMeasurementBoxChangesProvider);
  final all = ref.watch(measurementRepositoryProvider).all();
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});

/// Every stored goal, oldest first.
final bodyGoalsProvider = Provider<List<BodyGoal>>((ref) {
  ref.watch(bodyGoalsBoxChangesProvider);
  return ref.watch(bodyGoalRepositoryProvider).allByDate();
});

/// The full analytics snapshot for the selected range.
final bodySnapshotProvider = Provider<BodySnapshot>((ref) {
  return BodyCalculations.compute(
    all: ref.watch(bodyMeasurementsProvider),
    now: ref.watch(bodyNowProvider),
    range: ref.watch(bodyRangeProvider),
    goals: ref.watch(bodyGoalsProvider),
  );
});

/// The trend of the highlighted chart field.
final bodyChartTrendProvider = Provider<BodyFieldTrend?>((ref) {
  final field = ref.watch(bodyChartFieldProvider);
  for (final trend in ref.watch(bodySnapshotProvider).trends) {
    if (trend.field == field) return trend;
  }
  return null;
});

/// Writes whole body-measurement records back to storage.
final bodyMeasurementEditorProvider = Provider<BodyMeasurementEditor>((ref) {
  return BodyMeasurementEditor(
    measurements: ref.watch(measurementRepositoryProvider),
  );
});

/// Writes body-goal targets back to storage.
final bodyGoalEditorProvider = Provider<BodyGoalEditor>((ref) {
  return BodyGoalEditor(repository: ref.watch(bodyGoalRepositoryProvider));
});

/// Picks and stores progress photos for a measurement day.
///
/// Override in tests with a fake; the device-backed implementation resolves
/// the documents directory lazily and needs path_provider.
final bodyPhotoServiceProvider = Provider<BodyPhotoService>((ref) {
  return DeviceBodyPhotoService(
    imageService: ref.watch(imageServiceProvider),
    fileService: FileService(),
  );
});
