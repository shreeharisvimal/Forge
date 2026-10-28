// Test helper: a disposable, real Hive storage environment.
//
// Initializes Hive against a throwaway temp directory (bypassing the
// path_provider plugin, which is unavailable under `flutter test`) and
// tears it down afterwards.
library;

import 'dart:io';

import 'package:forge/database/database_service.dart';

/// A self-contained, real Hive environment for repository/service tests.
class HiveTestEnv {
  HiveTestEnv._(this.databaseService, this._tempDir);

  /// The initialized [DatabaseService] bound to a temp directory.
  final DatabaseService databaseService;

  final Directory _tempDir;

  /// Creates a fresh storage environment.
  static Future<HiveTestEnv> create() async {
    final tempDir = await Directory.systemTemp.createTemp('forge_test');
    final databaseService =
        await DatabaseService.initialize(directory: tempDir.path);
    return HiveTestEnv._(databaseService, tempDir);
  }

  /// Closes Hive and removes the temp directory.
  Future<void> dispose() async {
    await databaseService.close();
    if (_tempDir.existsSync()) _tempDir.deleteSync(recursive: true);
  }
}
