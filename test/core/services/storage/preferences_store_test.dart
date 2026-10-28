// Tests for the preferences store.
//
// SharedPreferences is exercised through its in-memory mock so no platform
// storage is touched.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/storage/preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<PreferencesStore> store() async =>
      PreferencesStore(await SharedPreferences.getInstance());

  group('typed values', () {
    test('round-trips strings, bools, ints, doubles and string lists',
        () async {
      final prefs = await store();

      await prefs.setString('s', 'value');
      await prefs.setBool('b', true);
      await prefs.setInt('i', 7);
      await prefs.setDouble('d', 2.5);
      await prefs.setStringList('l', ['a', 'b']);

      expect((await prefs.getString('s')).valueOrNull, 'value');
      expect((await prefs.getBool('b')).valueOrNull, isTrue);
      expect((await prefs.getInt('i')).valueOrNull, 7);
      expect((await prefs.getDouble('d')).valueOrNull, 2.5);
      expect((await prefs.getStringList('l')).valueOrNull, ['a', 'b']);
    });

    test('missing keys read as null', () async {
      final prefs = await store();
      expect((await prefs.getString('missing')).valueOrNull, isNull);
      expect((await prefs.getInt('missing')).valueOrNull, isNull);
    });

    test('contains and remove manage keys', () async {
      final prefs = await store();
      await prefs.setString('s', 'x');

      expect((await prefs.contains('s')).valueOrNull, isTrue);
      expect((await prefs.remove('s')).isSuccess, isTrue);
      expect((await prefs.contains('s')).valueOrNull, isFalse);
    });

    test('clear removes every key', () async {
      final prefs = await store();
      await prefs.setString('a', '1');
      await prefs.setInt('b', 2);

      await prefs.clear();

      expect((await prefs.keys()).valueOrNull, isEmpty);
    });
  });

  group('JSON values', () {
    test('setJson/getJson round-trips nested maps', () async {
      final prefs = await store();
      final value = {
        'name': 'forge',
        'nested': {'count': 3},
      };

      final write = await prefs.setJson('config', value);
      expect(write.isSuccess, isTrue);

      final read = await prefs.getJson('config');
      expect(read.valueOrNull, value);
    });

    test('getJson returns null when nothing is stored', () async {
      final prefs = await store();
      expect((await prefs.getJson('config')).valueOrNull, isNull);
    });

    test('getJson fails when the stored value is not a JSON object',
        () async {
      final prefs = await store();
      await prefs.setString('config', '[1, 2, 3]');

      final result = await prefs.getJson('config');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });
}
