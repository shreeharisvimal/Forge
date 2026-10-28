// Global error handler for the Forge application.
//
// Installs framework and zone error handlers that route every uncaught
// exception through the logger once, so nothing escapes silently and the
// app can keep running (or fail loudly in debug) instead of crashing with
// an unhandled exception.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;

import '../logger/forge_logger.dart';

/// Central handler for uncaught errors.
class GlobalErrorHandler {
  /// Creates a handler backed by [logger].
  GlobalErrorHandler(this._logger);

  final ForgeLogger _logger;

  /// Reports an uncaught [error] through the logger.
  ///
  /// [context] names the failing subsystem (e.g. `backup`, `lifecycle`)
  /// so logs stay scannable.
  void handle(Object error, StackTrace stackTrace, {String? context}) {
    _logger.error(
      context == null ? 'Uncaught error' : 'Uncaught error ($context)',
      error,
      stackTrace,
    );
  }

  /// Routes [FlutterError.onError] into this handler.
  ///
  /// Calling this more than once keeps the previously installed handler so
  /// the last registered handler still runs.
  void installFlutterErrorHandler() {
    final previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      handle(details.exception, details.stack ?? StackTrace.current,
          context: 'flutter');
      previous?.call(details);
    };
  }

  /// Runs [body] inside a guarded zone that forwards uncaught errors here.
  ///
  /// The returned zone is async-friendly: the caller should `await` a
  /// Future that completes only when the app is finished, or simply not
  /// await and let the zone live for the app's lifetime.
  void runGuarded(Future<void> Function() body) {
    runZonedGuarded(() async {
      await body();
    }, (Object error, StackTrace stack) {
      handle(error, stack, context: 'zone');
    });
  }
}
