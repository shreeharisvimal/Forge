// Forge overlay system — controller.
//
// A lightweight, app-wide overlay layer for loading, progress, toast,
// success and error feedback. The [ForgeOverlayHost] widget renders the
// active entries above the router; this file owns the state and the
// Riverpod provider the host watches.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../design/tokens/duration_tokens.dart';

/// The visual classes of overlay supported by the system.
enum ForgeOverlayKind {
  /// A brief neutral message.
  toast,

  /// A brief positive confirmation.
  success,

  /// A brief error notification.
  error,

  /// An indeterminate blocking-ish indicator.
  loading,

  /// A determinate progress indicator.
  progress,
}

/// A single active overlay entry.
@immutable
class ForgeOverlayEntry {
  /// Creates an overlay entry.
  const ForgeOverlayEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.action,
    this.progress,
  });

  /// Unique identifier of this entry.
  final int id;

  /// The overlay kind, which drives its presentation.
  final ForgeOverlayKind kind;

  /// The primary text.
  final String title;

  /// Optional supporting text.
  final String? message;

  /// Optional action button label.
  final String? actionLabel;

  /// Invoked when the action button is pressed.
  final VoidCallback? action;

  /// Current progress (0–1) for [ForgeOverlayKind.progress].
  final double? progress;

  /// The default auto-dismiss duration for a kind, or `null` when the entry
  /// must be dismissed explicitly.
  static Duration? autoDismissFor(ForgeOverlayKind kind) {
    return switch (kind) {
      ForgeOverlayKind.toast => AppDuration.slow + const Duration(milliseconds: 200),
      ForgeOverlayKind.success => AppDuration.slow + const Duration(milliseconds: 400),
      ForgeOverlayKind.error => AppDuration.slow + const Duration(milliseconds: 800),
      ForgeOverlayKind.loading => null,
      ForgeOverlayKind.progress => null,
    };
  }
}

/// Stateful controller for the global overlay layer.
///
/// Notifies [ForgeOverlayHost] on every change. Exposed through
/// [forgeOverlayControllerProvider] so any widget can show and dismiss
/// overlays without owning a reference to the host.
class ForgeOverlayController extends ChangeNotifier {
  final List<ForgeOverlayEntry> _entries = [];
  final Map<int, Completer<void>> _completers = {};
  final List<Timer> _timers = [];

  int _nextId = 0;

  /// The active entries, newest last.
  List<ForgeOverlayEntry> get entries => List.unmodifiable(_entries);

  /// Whether any overlay is currently active.
  bool get isActive => _entries.isNotEmpty;

  /// Shows an overlay entry.
  ///
  /// Returns the entry id, which can be used with [dismiss],
  /// [updateProgress] and [whenDismissed].
  int show({
    required ForgeOverlayKind kind,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? action,
    double? progress,
    Duration? autoDismiss,
  }) {
    final id = _nextId++;
    final entry = ForgeOverlayEntry(
      id: id,
      kind: kind,
      title: title,
      message: message,
      actionLabel: actionLabel,
      action: action,
      progress: progress,
    );
    _entries.add(entry);
    _completers[id] = Completer<void>();

    final timeout = autoDismiss ?? ForgeOverlayEntry.autoDismissFor(kind);
    if (timeout != null) {
      _timers.add(Timer(timeout, () => dismiss(id)));
    }

    notifyListeners();
    return id;
  }

  /// Updates a progress entry's value and/or text.
  void updateProgress(
    int id, {
    String? title,
    String? message,
    double? progress,
  }) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final current = _entries[index];
    _entries[index] = ForgeOverlayEntry(
      id: current.id,
      kind: current.kind,
      title: title ?? current.title,
      message: message ?? current.message,
      actionLabel: current.actionLabel,
      action: current.action,
      progress: progress ?? current.progress,
    );
    notifyListeners();
  }

  /// Dismisses a single entry by id.
  void dismiss(int id) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries.removeAt(index);
    _complete(id);
    notifyListeners();
  }

  /// Dismisses every active entry.
  void dismissAll() {
    if (_entries.isEmpty) return;
    final ids = _entries.map((entry) => entry.id).toList(growable: false);
    _entries.clear();
    for (final id in ids) {
      _complete(id);
    }
    notifyListeners();
  }

  /// A future that resolves when the entry with [id] is dismissed.
  ///
  /// Completes immediately if the id is unknown.
  Future<void> whenDismissed(int id) {
    final completer = _completers[id];
    return completer?.future ?? Future.value();
  }

  void _complete(int id) {
    final completer = _completers.remove(id);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Riverpod provider for the single shared overlay controller.
///
/// The legacy provider disposes the controller automatically when the
/// provider itself is disposed, so no manual teardown is registered here.
final forgeOverlayControllerProvider =
    ChangeNotifierProvider<ForgeOverlayController>(
  (ref) => ForgeOverlayController(),
);
