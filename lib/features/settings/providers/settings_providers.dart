// Settings providers for the Forge application.
//
// Composes the persistence and service layer for the Settings tab. Reading
// [settingsProvider] (from the shared providers) stays the single source of
// truth for the current preferences; this file adds the write-path
// controller, the Data-section manager and the app-wide side-effect sync.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/backup/backup_engine.dart';
import '../../../core/services/file/file_service.dart';
import '../../../core/services/haptics/haptics_service.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../core/services/share/share_service.dart';
import '../../../services/providers.dart';
import '../data/settings_controller.dart';
import '../data/settings_data_manager.dart';

/// The write-path facade for every preference.
final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(
    repository: ref.watch(settingsRepositoryProvider),
    haptics: ref.watch(hapticsServiceProvider),
    notifications: ref.watch(notificationServiceProvider),
  );
});

/// The base data directory for Data-section files.
///
/// `null` in production (each service resolves the app documents directory
/// lazily); overridden in tests with a temp directory so no plugin is needed.
final settingsDataDirectoryProvider = Provider<Directory?>((ref) => null);

/// File access rooted at [settingsDataDirectoryProvider] when provided.
final settingsFileServiceProvider = Provider<FileService>((ref) {
  final base = ref.watch(settingsDataDirectoryProvider);
  return base == null ? FileService() : FileService(baseDirectory: base);
});

/// The backup engine writing into the Data directory when provided.
final settingsBackupEngineProvider = Provider<BackupEngine>((ref) {
  final base = ref.watch(settingsDataDirectoryProvider);
  final source = ref.watch(dataSnapshotSourceProvider);
  if (base == null) return BackupEngine(source);
  return BackupEngine(
    source,
    directory: Directory('${base.path}${Platform.pathSeparator}backups'),
  );
});

/// The Data-section orchestrator.
final settingsDataManagerProvider = Provider<SettingsDataManager>((ref) {
  return SettingsDataManager(
    exportEngine: ref.watch(exportEngineProvider),
    importEngine: ref.watch(importEngineProvider),
    backupEngine: ref.watch(settingsBackupEngineProvider),
    fileService: ref.watch(settingsFileServiceProvider),
    shareService: ref.watch(shareServiceProvider),
  );
});

/// Syncs app-wide services to the persisted preferences.
///
/// Watched from the app shell so haptics follow the setting immediately on
/// launch and after every change, from any tab. Extend here when reminder
/// scheduling ships.
final settingsEffectsProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsProvider);
  final haptics = ref.watch(hapticsServiceProvider);
  haptics.enabled = settings.hapticsEnabled;
});
