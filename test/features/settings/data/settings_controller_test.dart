// Tests for the settings controller write path.
//
// Uses the real Hive-backed repository and an injected haptics service so
// the side-effect contract (live service flip + confirmation tap) can be
// verified without platform channels.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/design/utilities/haptic_helper.dart';
import 'package:forge/core/services/haptics/haptics_service.dart';
import 'package:forge/core/services/notifications/notification_service.dart';
import 'package:forge/features/settings/data/settings_controller.dart';
import 'package:forge/features/settings/domain/settings_catalog.dart';
import 'package:forge/services/repositories/settings_repository.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late HiveSettingsRepository repository;
  late HapticsService haptics;
  late List<HapticType> hapticCalls;
  late SettingsController controller;

  setUp(() async {
    env = await HiveTestEnv.create();
    repository = HiveSettingsRepository(env.databaseService.settingsBox);
    hapticCalls = <HapticType>[];
    haptics = HapticsService(delegate: (type) async => hapticCalls.add(type));
    controller = SettingsController(
      repository: repository,
      haptics: haptics,
      notifications: const NoOpNotificationService(),
    );
  });

  tearDown(() => env.dispose());

  test('current falls back to defaults on a fresh install', () {
    expect(controller.current.themeMode, 'system');
    expect(controller.current.restTimer, 90);
  });

  test('update stamps updatedAt', () async {
    final before = controller.current.updatedAt;
    await controller.update((s) => s.copyWith(restTimer: 60));
    expect(controller.current.updatedAt.isAfter(before), isTrue);
  });

  test('setThemeMode persists the key', () async {
    await controller.setThemeMode(SettingsThemeMode.dark);
    expect(controller.current.themeMode, 'dark');
    expect(repository.current?.themeMode, 'dark');
  });

  test('setAccent persists the palette key', () async {
    await controller.setAccent('cyan');
    expect(controller.current.accentColor, 'cyan');
  });

  test('setAmoled and setDynamicColors persist booleans', () async {
    await controller.setAmoled(false);
    await controller.setDynamicColors(true);
    expect(controller.current.amoledMode, isFalse);
    expect(controller.current.dynamicColors, isTrue);
  });

  test('setHaptics flips the live service, persists, then confirms', () async {
    haptics.enabled = false;
    await controller.setHaptics(true);
    expect(haptics.enabled, isTrue);
    expect(controller.current.hapticsEnabled, isTrue);
    expect(hapticCalls, [HapticType.light]);
  });

  test('setHaptics(false) mutes without a confirmation tap', () async {
    hapticCalls.clear();
    await controller.setHaptics(false);
    expect(haptics.enabled, isFalse);
    expect(controller.current.hapticsEnabled, isFalse);
    expect(hapticCalls, isEmpty);
  });

  test('training defaults persist', () async {
    await controller.setRestTimer(180);
    await controller.setWarmUpSets(3);
    await controller.setWarmUpWeightPercent(40);
    await controller.setWeightIncrement(1.25);
    await controller.setPlateWeight(25);
    await controller.setBarWeight(15);

    final settings = controller.current;
    expect(settings.restTimer, 180);
    expect(settings.warmUpSets, 3);
    expect(settings.warmUpWeightPercent, 40);
    expect(settings.weightIncrement, 1.25);
    expect(settings.plateWeight, 25);
    expect(settings.barWeight, 15);
  });

  test('setCountdownSound and setAutoStartRestTimer persist', () async {
    await controller.setCountdownSound(false);
    await controller.setAutoStartRestTimer(true);
    expect(controller.current.countdownSound, isFalse);
    expect(controller.current.autoStartRestTimer, isTrue);
  });

  test('setUnitSystem persists the system and derived units', () async {
    await controller.setUnitSystem(SettingsUnitSystem.imperial);
    final settings = controller.current;
    expect(settings.unitSystem, 'imperial');
    expect(settings.weightUnit, 'lb');
    expect(settings.lengthUnit, 'in');
    expect(settings.waterUnit, 'oz');
  });

  test('setWaterUnit persists independently', () async {
    await controller.setWaterUnit('oz');
    expect(controller.current.waterUnit, 'oz');
  });

  test('setReminderEnabled toggles each reminder field', () async {
    await controller.setReminderEnabled('workout', true);
    await controller.setReminderEnabled('rest', true);
    await controller.setReminderEnabled('daily', true);
    await controller.setReminderEnabled('weekly', true);

    final settings = controller.current;
    expect(settings.workoutRemindersEnabled, isTrue);
    expect(settings.restRemindersEnabled, isTrue);
    expect(settings.dailyReminderEnabled, isTrue);
    expect(settings.weeklySummaryEnabled, isTrue);
  });

  test('resetAll restores defaults and re-enables haptics', () async {
    await controller.setThemeMode(SettingsThemeMode.dark);
    await controller.setHaptics(false);
    haptics.enabled = false;

    await controller.resetAll();

    expect(controller.current.themeMode, 'system');
    expect(controller.current.amoledMode, isTrue);
    expect(controller.current.hapticsEnabled, isTrue);
    expect(haptics.enabled, isTrue);
  });

  test('repository keeps exactly one settings row', () async {
    await controller.setThemeMode(SettingsThemeMode.light);
    await controller.setAccent('blue');
    await controller.setRestTimer(120);
    expect(repository.count, 1);
  });
}
