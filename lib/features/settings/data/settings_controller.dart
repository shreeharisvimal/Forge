// Settings controller for the Forge application.
//
// The write-path facade for the Settings tab. Every preference change flows
// through here so side effects stay attached to the single place that
// persists them: the Haptics toggle flips the live [HapticsService], and the
// reminder toggles ping the [NotificationService] (a no-op today) before
// saving. Widgets never touch the repository directly.
library;

import '../../../core/services/haptics/haptics_service.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../models/settings_model.dart';
import '../../../services/repositories/settings_repository.dart';
import '../domain/settings_catalog.dart';

/// Writes settings preferences and applies their runtime side effects.
class SettingsController {
  /// Creates a settings controller.
  SettingsController({
    required this.repository,
    required this.haptics,
    required this.notifications,
  });

  /// Persists the single settings document.
  final SettingsRepository repository;

  /// The app-wide haptics service kept in sync with the toggle.
  final HapticsService haptics;

  /// The notification service pinged before reminder settings are saved.
  final NotificationService notifications;

  /// The current settings, or defaults when none are stored yet.
  SettingsModel get current => repository.current ?? SettingsModel();

  /// Saves [transform] applied to the current settings.
  Future<void> update(SettingsModel Function(SettingsModel current) transform) {
    return repository.replace(transform(current).copyWith(updatedAt: DateTime.now()));
  }

  /// Sets the theme mode ('system', 'light' or 'dark').
  Future<void> setThemeMode(SettingsThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode.key));

  /// Sets the accent palette key.
  Future<void> setAccent(String key) =>
      update((s) => s.copyWith(accentColor: key));

  /// Sets whether true-black AMOLED backgrounds are used in dark mode.
  Future<void> setAmoled(bool enabled) =>
      update((s) => s.copyWith(amoledMode: enabled));

  /// Sets whether the palette is derived dynamically from the accent seed.
  Future<void> setDynamicColors(bool enabled) =>
      update((s) => s.copyWith(dynamicColors: enabled));

  /// Sets whether haptic feedback is enabled app-wide.
  ///
  /// Flips the live service first so the very next interaction is already
  /// muted or audible, then persists the preference and confirms with a tap.
  Future<void> setHaptics(bool enabled) async {
    haptics.enabled = enabled;
    await update((s) => s.copyWith(hapticsEnabled: enabled));
    if (enabled) await haptics.tap();
  }

  /// Sets the default rest-timer duration in seconds.
  Future<void> setRestTimer(int seconds) =>
      update((s) => s.copyWith(restTimer: seconds));

  /// Sets whether the rest timer plays an audible countdown.
  Future<void> setCountdownSound(bool enabled) =>
      update((s) => s.copyWith(countdownSound: enabled));

  /// Sets whether the rest timer starts automatically after a set.
  Future<void> setAutoStartRestTimer(bool enabled) =>
      update((s) => s.copyWith(autoStartRestTimer: enabled));

  /// Sets the default number of warm-up sets.
  Future<void> setWarmUpSets(int sets) =>
      update((s) => s.copyWith(warmUpSets: sets));

  /// Sets the warm-up weight percentage of the working weight.
  Future<void> setWarmUpWeightPercent(int percent) =>
      update((s) => s.copyWith(warmUpWeightPercent: percent));

  /// Sets the default plate-increment step.
  Future<void> setWeightIncrement(double increment) =>
      update((s) => s.copyWith(weightIncrement: increment));

  /// Sets the default plate weight in kilograms.
  Future<void> setPlateWeight(double weight) =>
      update((s) => s.copyWith(plateWeight: weight));

  /// Sets the default barbell weight in kilograms.
  Future<void> setBarWeight(double weight) =>
      update((s) => s.copyWith(barWeight: weight));

  /// Sets the measurement system and the derived unit fields together.
  Future<void> setUnitSystem(SettingsUnitSystem system) => update(
        (s) => s.copyWith(
          unitSystem: system.key,
          weightUnit: system.weightUnit,
          lengthUnit: system.lengthUnit,
          waterUnit: system.waterUnit,
        ),
      );

  /// Sets the water-consumption unit.
  Future<void> setWaterUnit(String unit) =>
      update((s) => s.copyWith(waterUnit: unit));

  /// Enables or disables one reminder type.
  Future<void> setReminderEnabled(String key, bool enabled) async {
    // The current service is a no-op; when real scheduling lands, this is
    // where permission is requested before a reminder is saved.
    await notifications.requestPermission();
    switch (key) {
      case 'workout':
        await update((s) => s.copyWith(workoutRemindersEnabled: enabled));
      case 'rest':
        await update((s) => s.copyWith(restRemindersEnabled: enabled));
      case 'daily':
        await update((s) => s.copyWith(dailyReminderEnabled: enabled));
      case 'weekly':
        await update((s) => s.copyWith(weeklySummaryEnabled: enabled));
    }
  }

  /// Restores every preference to its default.
  Future<void> resetAll() async {
    haptics.enabled = true;
    await repository.replace(SettingsModel());
  }
}
