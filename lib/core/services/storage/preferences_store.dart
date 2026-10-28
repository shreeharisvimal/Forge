// Preferences store for the Forge application.
//
// A strongly-typed wrapper over [SharedPreferences] so feature code never
// touches raw keys and JSON. Preferences are reserved for lightweight
// key/value settings (e.g. "last backup date"); Hive boxes remain the
// primary structured store.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// Internal marker for a rejected SharedPreferences write.
class StorageWriteRejected implements Exception {
  /// Creates a write-rejection marker.
  const StorageWriteRejected();
}

/// Typed key/value storage backed by [SharedPreferences].
class PreferencesStore {
  /// Creates a store over [preferences].
  PreferencesStore(this._preferences, {ForgeLogger? logger})
      : _logger = logger;

  /// Loads the platform preferences into an in-memory store.
  ///
  /// Tests should seed via `SharedPreferences.setMockInitialValues` before
  /// calling this.
  static Future<PreferencesStore> initialize({ForgeLogger? logger}) async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesStore(preferences, logger: logger);
  }

  final SharedPreferences _preferences;
  final ForgeLogger? _logger;

  /// Reads the string stored at [key], or null when absent.
  Future<Result<String?>> getString(String key) =>
      _read(() => _preferences.getString(key));

  /// Stores [value] under [key].
  Future<Result<void>> setString(String key, String value) =>
      _write(() => _preferences.setString(key, value));

  /// Reads the boolean stored at [key], or null when absent.
  Future<Result<bool?>> getBool(String key) =>
      _read(() => _preferences.getBool(key));

  /// Stores [value] under [key].
  Future<Result<void>> setBool(String key, bool value) =>
      _write(() => _preferences.setBool(key, value));

  /// Reads the integer stored at [key], or null when absent.
  Future<Result<int?>> getInt(String key) =>
      _read(() => _preferences.getInt(key));

  /// Stores [value] under [key].
  Future<Result<void>> setInt(String key, int value) =>
      _write(() => _preferences.setInt(key, value));

  /// Reads the double stored at [key], or null when absent.
  Future<Result<double?>> getDouble(String key) =>
      _read(() => _preferences.getDouble(key));

  /// Stores [value] under [key].
  Future<Result<void>> setDouble(String key, double value) =>
      _write(() => _preferences.setDouble(key, value));

  /// Reads the string list stored at [key], or null when absent.
  Future<Result<List<String>?>> getStringList(String key) =>
      _read(() => _preferences.getStringList(key));

  /// Stores [value] under [key].
  Future<Result<void>> setStringList(String key, List<String> value) =>
      _write(() => _preferences.setStringList(key, value));

  /// Reads and decodes a JSON object stored at [key].
  Future<Result<Map<String, dynamic>?>> getJson(String key) async {
    final read = await getString(key);
    return read.when(
      success: (raw) {
        if (raw == null) return const Success(null);
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return Success(decoded);
          return const Failure(
            StorageFailure('Stored value is not a JSON object.'),
          );
        } on FormatException catch (error, stackTrace) {
          return Failure(_storageFailure(error, stackTrace));
        }
      },
      failure: Failure.new,
    );
  }

  /// Encodes and stores [value] under [key].
  Future<Result<void>> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  /// Whether a value is stored under [key].
  Future<Result<bool>> contains(String key) => Result.tryAsync(
        () async => _preferences.containsKey(key),
        classify: _storageFailure,
      );

  /// Removes the value stored under [key].
  Future<Result<void>> remove(String key) =>
      _write(() => _preferences.remove(key));

  /// Removes every stored value.
  Future<Result<void>> clear() => _write(_preferences.clear);

  /// All keys currently stored.
  Future<Result<List<String>>> keys() => Result.tryAsync(
        () async => _preferences.getKeys().toList(),
        classify: _storageFailure,
      );

  Future<Result<T?>> _read<T>(T? Function() read) async =>
      Result.trySync<T?>(read);

  Future<Result<void>> _write(Future<bool> Function() write) =>
      Result.tryAsync<void>(
        () async {
          if (!await write()) {
            throw const StorageWriteRejected();
          }
        },
        classify: _storageFailure,
      );

  ForgeFailure _storageFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Preferences operation failed', error, stackTrace);
    return switch (error) {
      StorageWriteRejected() => const StorageFailure('Preferences write rejected.'),
      FormatException() => StorageFailure('Malformed preference value.', cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
