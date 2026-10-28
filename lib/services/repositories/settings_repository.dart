// Settings repository for the Forge application.
//
// Persistence for the single [SettingsModel] preferences document.
library;

import '../../models/settings_model.dart';
import 'base_repository.dart';

/// Query surface for the single [SettingsModel] document.
abstract class SettingsRepository extends BaseRepository<SettingsModel> {
  /// Creates a repository backed by [box].
  SettingsRepository(super.box);

  /// The stored settings document, or null on a fresh install.
  SettingsModel? get current {
    if (box.isEmpty) return null;
    return box.values.first;
  }

  /// Saves [settings] as the single settings document.
  ///
  /// If a previous document exists its key is reused so only one row is
  /// ever stored.
  Future<void> replace(SettingsModel settings) async {
    if (box.isNotEmpty) {
      await box.deleteAll(box.keys.toList());
    }
    await save(settings);
  }
}

/// Hive-backed [SettingsRepository].
class HiveSettingsRepository extends SettingsRepository {
  /// Creates a repository backed by [box].
  HiveSettingsRepository(super.box);
}
