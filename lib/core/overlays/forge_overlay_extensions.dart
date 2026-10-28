// Forge overlay system — context extension.
//
// Ergonomics on top of [ForgeOverlayController] so call sites read as
// `context.showToast('Saved')` or `await context.showLoading('Syncing')`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'forge_overlay_controller.dart';

/// Convenience accessors for the global overlay layer.
extension ForgeOverlayX on BuildContext {
  /// Shows a brief neutral toast.
  int showToast(
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    return _overlay.show(
      kind: ForgeOverlayKind.toast,
      title: message,
      actionLabel: actionLabel,
      action: action,
    );
  }

  /// Shows a brief success confirmation.
  int showSuccess(
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    return _overlay.show(
      kind: ForgeOverlayKind.success,
      title: message,
      actionLabel: actionLabel,
      action: action,
    );
  }

  /// Shows a brief error notification.
  int showError(
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    return _overlay.show(
      kind: ForgeOverlayKind.error,
      title: message,
      actionLabel: actionLabel,
      action: action,
    );
  }

  /// Shows an indeterminate loading overlay.
  ///
  /// The returned future completes when the overlay is dismissed, so async
  /// call sites can write `await context.showLoading('Saving…')`.
  Future<void> showLoading(
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    final id = _overlay.show(
      kind: ForgeOverlayKind.loading,
      title: message,
      actionLabel: actionLabel,
      action: action,
    );
    return _overlay.whenDismissed(id);
  }

  /// Shows a determinate progress overlay and returns its id.
  int showProgress({
    required String title,
    String? message,
    double? value,
    String? actionLabel,
    VoidCallback? action,
  }) {
    return _overlay.show(
      kind: ForgeOverlayKind.progress,
      title: title,
      message: message,
      actionLabel: actionLabel,
      action: action,
      progress: value,
    );
  }

  /// Updates a progress overlay created with [showProgress].
  void updateProgress(
    int id, {
    String? title,
    String? message,
    double? value,
  }) {
    _overlay.updateProgress(
      id,
      title: title,
      message: message,
      progress: value,
    );
  }

  /// Dismisses an overlay by its id.
  void dismissOverlay(int id) => _overlay.dismiss(id);

  /// Dismisses every active overlay.
  void dismissAllOverlays() => _overlay.dismissAll();

  ForgeOverlayController get _overlay =>
      ProviderScope.containerOf(this).read(forgeOverlayControllerProvider);
}
