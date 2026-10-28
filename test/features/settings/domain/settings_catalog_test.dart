// Tests for the settings domain catalog.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/features/settings/domain/settings_catalog.dart';

void main() {
  group('SettingsThemeMode', () {
    test('fromKey maps known keys', () {
      expect(SettingsThemeMode.fromKey('system'), SettingsThemeMode.system);
      expect(SettingsThemeMode.fromKey('light'), SettingsThemeMode.light);
      expect(SettingsThemeMode.fromKey('dark'), SettingsThemeMode.dark);
    });

    test('fromKey falls back to system for unknown keys', () {
      expect(SettingsThemeMode.fromKey('midnight'), SettingsThemeMode.system);
      expect(SettingsThemeMode.fromKey(null), SettingsThemeMode.system);
    });

    test('every mode exposes a key, label and icon', () {
      for (final mode in SettingsThemeMode.values) {
        expect(mode.key, isNotEmpty);
        expect(mode.label, isNotEmpty);
        expect(mode.icon, isNotNull);
      }
    });
  });

  group('SettingsUnitSystem', () {
    test('fromKey maps known keys and falls back to metric', () {
      expect(
        SettingsUnitSystem.fromKey('imperial'),
        SettingsUnitSystem.imperial,
      );
      expect(SettingsUnitSystem.fromKey('parsec'), SettingsUnitSystem.metric);
      expect(SettingsUnitSystem.fromKey(null), SettingsUnitSystem.metric);
    });

    test('metric derives kg, cm and liters', () {
      expect(SettingsUnitSystem.metric.weightUnit, 'kg');
      expect(SettingsUnitSystem.metric.lengthUnit, 'cm');
      expect(SettingsUnitSystem.metric.waterUnit, 'l');
    });

    test('imperial derives lb, inches and fluid ounces', () {
      expect(SettingsUnitSystem.imperial.weightUnit, 'lb');
      expect(SettingsUnitSystem.imperial.lengthUnit, 'in');
      expect(SettingsUnitSystem.imperial.waterUnit, 'oz');
    });
  });

  group('SettingsRestTimerOption', () {
    test('nearest picks the closest preset', () {
      expect(SettingsRestTimerOption.nearest(90), SettingsRestTimerOption.ninetySeconds);
      expect(SettingsRestTimerOption.nearest(60), SettingsRestTimerOption.oneMinute);
      expect(SettingsRestTimerOption.nearest(121), SettingsRestTimerOption.twoMinutes);
      expect(SettingsRestTimerOption.nearest(300), SettingsRestTimerOption.threeMinutes);
    });

    test('presets are ordered from shortest to longest', () {
      final seconds = [for (final option in SettingsRestTimerOption.values) option.seconds];
      expect(seconds, seconds..sort());
    });
  });

  group('Numeric options', () {
    test('warm-up sets offers 0 through 4', () {
      expect(kSettingsWarmUpSetOptions.length, 5);
      expect(kSettingsWarmUpSetOptions.first.value, 0);
      expect(kSettingsWarmUpSetOptions.last.value, 4);
    });

    test('weight increment offers fractional steps', () {
      expect(kSettingsWeightIncrementOptions.map((o) => o.value),
          containsAll([1.25, 2.5, 5.0]));
    });

    test('plate and barbell options are non-empty', () {
      expect(kSettingsPlateWeightOptions, isNotEmpty);
      expect(kSettingsBarWeightOptions, isNotEmpty);
    });
  });

  group('SettingsReminderType', () {
    test('covers every stable key and displays in order', () {
      expect(
        kSettingsReminderTypes.map((type) => type.key),
        ['workout', 'rest', 'daily', 'weekly'],
      );
      for (final type in kSettingsReminderTypes) {
        expect(type.label, isNotEmpty);
        expect(type.subtitle, isNotEmpty);
        expect(type.icon, isNotNull);
      }
    });
  });

  group('formatSettingNumber', () {
    test('renders integers without a decimal part', () {
      expect(formatSettingNumber(2.0), '2');
      expect(formatSettingNumber(20), '20');
    });

    test('renders fractions trimmed of trailing zeros', () {
      expect(formatSettingNumber(1.25), '1.25');
      expect(formatSettingNumber(1.50), '1.5');
      expect(formatSettingNumber(2.500), '2.5');
    });
  });
}
