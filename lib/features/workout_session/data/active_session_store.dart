// Active session persistence for the Forge application.
//
// The in-progress workout is stored in two halves so a session survives an
// app restart mid-workout:
//   * the workout content ([WorkoutSession] + exercises + sets) lives in the
//     dedicated active-session box, and
//   * the transient UI state (stage, focused exercise, rest timer, timer
//     pause) lives as a JSON document in the metadata box.
// A running rest timer therefore keeps counting even while the app is closed.
library;

import 'dart:convert';

import '../../../database/database_service.dart';
import '../../../models/workout_session.dart';
import '../domain/session_models.dart';

/// Reads and writes the single active workout.
class ActiveSessionStore {
  /// Creates a store backed by [database].
  ActiveSessionStore(this._database);

  final DatabaseService _database;

  /// Box key under which the content [WorkoutSession] is stored.
  static const String activeSessionKey = 'active_session';

  /// Metadata key under which the [SessionUiState] JSON document lives.
  static const String uiStateKey = 'active_session_ui_state';

  /// Persists [session] (content and UI state).
  Future<void> save(ActiveSession session) async {
    await _database.activeSessionBox.put(activeSessionKey, session.snapshot);
    await _database.metaBox.put(uiStateKey, jsonEncode(session.ui.toMap()));
  }

  /// Loads the active session, or null when no workout is in progress.
  ///
  /// A corrupt UI-state document falls back to a fresh preparation state
  /// rather than discarding the workout content.
  Future<ActiveSession?> load() async {
    final content = _database.activeSessionBox.get(activeSessionKey);
    if (content == null) return null;

    var ui = SessionUiState();
    final raw = _database.metaBox.get(uiStateKey) as String?;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          ui = SessionUiState.fromMap(decoded);
        }
      } catch (_) {
        ui = SessionUiState();
      }
    }
    return ActiveSession(content: content, ui: ui);
  }

  /// Removes the active session after it is finished or abandoned.
  Future<void> clear() async {
    await _database.activeSessionBox.delete(activeSessionKey);
    await _database.metaBox.delete(uiStateKey);
  }

  /// The stored content record, or null when no workout is in progress.
  WorkoutSession? peek() =>
      _database.activeSessionBox.get(activeSessionKey);
}
