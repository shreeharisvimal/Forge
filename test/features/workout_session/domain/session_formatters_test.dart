// Domain tests for the session formatters.
//
// Plain-text number and duration formatting in both weight units.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/domain/session_formatters.dart';

void main() {
  group('SessionFormatters.weight', () {
    test('kg trims trailing zeros', () {
      expect(SessionFormatters.weight(80, SessionWeightUnit.kg), '80');
      expect(SessionFormatters.weight(82.5, SessionWeightUnit.kg), '82.5');
    });

    test('lb converts from kg', () {
      expect(SessionFormatters.weight(80, SessionWeightUnit.lb), '176.4');
      expect(SessionFormatters.weight(82.5, SessionWeightUnit.lb), '181.9');
    });

    test('weightWithUnit appends the unit label', () {
      expect(
        SessionFormatters.weightWithUnit(80, SessionWeightUnit.kg),
        '80 kg',
      );
      expect(
        SessionFormatters.weightWithUnit(80, SessionWeightUnit.lb),
        '176.4 lb',
      );
    });
  });

  group('SessionFormatters.volume', () {
    test('groups thousands and appends the unit', () {
      expect(SessionFormatters.volume(1250, SessionWeightUnit.kg), '1,250 kg');
      expect(
        SessionFormatters.volume(1250, SessionWeightUnit.lb),
        '2,756 lb',
      );
    });
  });

  group('SessionFormatters durations', () {
    test('shortDuration', () {
      expect(SessionFormatters.shortDuration(const Duration(seconds: 45)), '45s');
      expect(
        SessionFormatters.shortDuration(const Duration(minutes: 4, seconds: 20)),
        '4m 20s',
      );
      expect(
        SessionFormatters.shortDuration(const Duration(hours: 1, minutes: 5)),
        '1h 05m',
      );
    });

    test('clock', () {
      expect(SessionFormatters.clock(252), '04:12');
      expect(SessionFormatters.clock(3852), '01:04:12');
    });

    test('longDuration', () {
      expect(SessionFormatters.longDuration(const Duration(minutes: 34)), '34m');
      expect(
        SessionFormatters.longDuration(const Duration(minutes: 83)),
        '1h 23m',
      );
    });
  });

  group('SessionWeightUnit.fromSettings', () {
    test('maps the settings string to a unit', () {
      expect(SessionWeightUnit.fromSettings('kg'), SessionWeightUnit.kg);
      expect(SessionWeightUnit.fromSettings('lb'), SessionWeightUnit.lb);
      expect(SessionWeightUnit.fromSettings(null), SessionWeightUnit.kg);
    });
  });
}
