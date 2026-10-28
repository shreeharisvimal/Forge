// Identifiable contract for the Forge application.
//
// Implemented by every persisted model so storage code can uniformly
// key, look up, and update records by their string id.
library;

/// A persisted entity that can be addressed by a unique string [id].
abstract interface class Identifiable {
  /// Unique identifier, used as the Hive box key.
  String get id;
}
