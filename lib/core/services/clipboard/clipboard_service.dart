// Clipboard service for the Forge application.
//
// Reusable wrapper over Flutter's system clipboard so features copy text,
// JSON and clear the clipboard through one typed API instead of talking to
// the platform channel directly. Operations return a [Result] and classify
// failures as [ClipboardFailure].
library;

import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../design/utilities/haptic_helper.dart';
import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// Typed clipboard operations for Forge.
class ClipboardService {
  /// Creates a clipboard service.
  ///
  /// [printer] is only used for diagnostics and defaults to no-ops;
  /// [logger] optionally records failures.
  ClipboardService({ForgeLogger? logger, bool hapticFeedback = true})
      : _logger = logger,
        _hapticFeedback = hapticFeedback;

  final ForgeLogger? _logger;
  final bool _hapticFeedback;

  /// Copies [text] to the system clipboard.
  Future<Result<void>> copyText(String text) => Result.tryAsync(
        () async {
          await Clipboard.setData(ClipboardData(text: text));
          _playHaptic();
        },
        classify: _clipboardFailure,
      );

  /// Reads the current clipboard text, or null when empty/unavailable.
  Future<Result<String?>> readText() => Result.tryAsync(
        () async => (await Clipboard.getData(Clipboard.kTextPlain))?.text,
        classify: _clipboardFailure,
      );

  /// Encodes and copies [json] as pretty JSON text.
  Future<Result<void>> copyJson(Map<String, dynamic> json) => Result.tryAsync(
        () async {
          const encoder = JsonEncoder.withIndent('  ');
          await Clipboard.setData(ClipboardData(text: encoder.convert(json)));
          _playHaptic();
        },
        classify: _clipboardFailure,
      );

  /// Clears the system clipboard.
  Future<Result<void>> clear() => Result.tryAsync(
        () async => Clipboard.setData(const ClipboardData(text: '')),
        classify: _clipboardFailure,
      );

  void _playHaptic() {
    if (_hapticFeedback) {
      unawaited(HapticHelper.fire(HapticType.light));
    }
  }

  ForgeFailure _clipboardFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Clipboard operation failed', error, stackTrace);
    return ClipboardFailure('$error', cause: error);
  }
}
