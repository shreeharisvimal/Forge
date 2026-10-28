// Production logger for the Forge application.
//
// ForgeLogger is a small, dependency-free logging facade with leveled
// records, tag scoping, pluggable sinks (console + ring-buffer memory),
// pretty/colored formatting and release-safe filtering. It never throws:
// a failing sink is caught and dropped so logging can never crash the app.
library;

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show debugPrint;

/// The severity of a [LogRecord].
enum LogLevel {
  /// Verbose diagnostic output; typically disabled in release builds.
  debug(0),

  /// Notable lifecycle and background events.
  info(1),

  /// Recoverable problems that deserve attention.
  warning(2),

  /// Errors and exceptions.
  error(3);

  /// Creates a level with a [severity] ordering.
  const LogLevel(this.severity);

  /// Higher means more severe; used for threshold comparisons.
  final int severity;

  /// Whether this level meets or exceeds [threshold].
  bool allows(LogLevel threshold) => severity >= threshold.severity;
}

/// A single formatted log entry.
class LogRecord {
  /// Creates a log record.
  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// When the record was created.
  final DateTime timestamp;

  /// The severity.
  final LogLevel level;

  /// The originating scope, e.g. `backup` or `workout-session`.
  final String tag;

  /// The human-readable message.
  final String message;

  /// The attached error, when present.
  final Object? error;

  /// The attached stack trace, when present.
  final StackTrace? stackTrace;
}

/// Decides which records reach a sink.
abstract class LogFilter {
  /// Whether [record] should be logged.
  bool accepts(LogRecord record);

  /// A filter that passes every record.
  static LogFilter get everything => _EverythingFilter();

  /// A filter that only drops records below [minLevel].
  static LogFilter atLeast(LogLevel minLevel) => _LevelFilter(minLevel);

  /// A filter combining several filters; a record must pass all of them.
  static LogFilter all(Iterable<LogFilter> filters) => _AndFilter(filters);
}

class _EverythingFilter implements LogFilter {
  @override
  bool accepts(LogRecord record) => true;
}

class _LevelFilter implements LogFilter {
  _LevelFilter(this.minLevel);

  final LogLevel minLevel;

  @override
  bool accepts(LogRecord record) => record.level.allows(minLevel);
}

class _AndFilter implements LogFilter {
  _AndFilter(Iterable<LogFilter> filters) : filters = filters.toList();

  final List<LogFilter> filters;

  @override
  bool accepts(LogRecord record) => filters.every((f) => f.accepts(record));
}

/// A destination for formatted [LogRecord]s.
abstract class LogSink {
  /// Writes [record] to the destination.
  Future<void> write(LogRecord record);

  /// Releases any resources held by the sink.
  Future<void> close() async {}

  /// A no-op sink used as a safe default.
  static LogSink get none => _NoneSink();
}

class _NoneSink extends LogSink {
  @override
  Future<void> write(LogRecord record) async {}
}

/// ANSI escape helpers for colored console output.
abstract final class AnsiColor {
  AnsiColor._();

  /// The ANSI escape start.
  static const String _start = '\u001b[';
  static const String _end = 'm';
  static const String reset = '\u001b[0m';
  static const String bold = '\u001b[1m';

  /// The escape sequence for the given foreground [code].
  static String foreground(int code) => '$_start${38};5;$code$_end';
}

/// Sink that prints records to the console.
///
/// Uses [debugPrint] so long lines are throttled and appear intact on
/// Android. When [color] is true the severity is tinted with ANSI codes.
class ConsoleLogSink extends LogSink {
  /// Creates a console sink.
  ConsoleLogSink({this.color = false, void Function(String line)? printer})
      : _printer = printer ?? debugPrint;

  /// Whether to tint output with ANSI colors.
  final bool color;

  final void Function(String line) _printer;

  /// Severity foreground colors (256-color palette).
  static const Map<LogLevel, int> _colors = {
    LogLevel.debug: 245,
    LogLevel.info: 39,
    LogLevel.warning: 214,
    LogLevel.error: 196,
  };

  @override
  Future<void> write(LogRecord record) async {
    final line = PrettyLogFormatter.ansi(record, color: color);
    _printer(line);
  }
}

/// Sink that keeps the most recent records in memory.
///
/// Primarily for diagnostics: recent entries can be surfaced in an app
/// report or debug screen without touching the file system.
class InMemoryLogSink extends LogSink {
  /// Creates a memory sink holding up to [maxEntries] records.
  InMemoryLogSink({this.maxEntries = 200});

  /// Maximum number of records retained before old ones are dropped.
  final int maxEntries;

  final List<LogRecord> _records = [];

  /// The retained records, oldest first.
  List<LogRecord> get recent => List.unmodifiable(_records);

  /// Removes all retained records.
  void clear() => _records.clear();

  @override
  Future<void> write(LogRecord record) async {
    _records.add(record);
    if (_records.length > maxEntries) {
      _records.removeRange(0, _records.length - maxEntries);
    }
  }
}

/// Builds the human-readable text form of a [LogRecord].
abstract final class PrettyLogFormatter {
  PrettyLogFormatter._();

  /// The prefix used by every line of a multi-line record.
  static const String _continuation = '     ';

  /// Formats [record] into text, optionally with [color] highlighting.
  static String ansi(LogRecord record, {bool color = true}) {
    final level = _level(record.level, color);
    final timestamp = _time(record.timestamp);
    final header = '$timestamp $level [$record.tag] ${record.message}';

    final buffer = StringBuffer(header);
    if (record.error != null) {
      buffer.writeln();
      buffer.write('$_continuation$record.error');
    }
    if (record.stackTrace != null) {
      buffer.writeln();
      buffer.write(
        record.stackTrace.toString().trimRight().split('\n').join('\n$_continuation'),
      );
    }
    if (color) buffer.write(AnsiColor.reset);
    return buffer.toString();
  }

  static String _level(LogLevel level, bool color) {
    final label = level.name.toUpperCase().padLeft(5);
    if (!color) return label;
    return '${AnsiColor.bold}${AnsiColor.foreground(ConsoleLogSink._colors[level]!)}$label';
  }

  static String _time(DateTime timestamp) {
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    String two(int value) => value.toString().padLeft(2, '0');
    return '[${two(timestamp.year % 100)}-${two(timestamp.month)}-'
        '${two(timestamp.day)} ${two(timestamp.hour)}:${two(timestamp.minute)}:'
        '${two(timestamp.second)}.$ms]';
  }
}

/// A leveled logger scoped to a [tag].
class ForgeLogger {
  /// Creates a logger.
  ForgeLogger({
    required this.tag,
    LogFilter? filter,
    LogSink? sink,
    DateTime Function()? clock,
  })  : filter = filter ?? LogFilter.everything,
        _sink = sink ?? ConsoleLogSink(),
        _clock = clock ?? DateTime.now;

  /// Creates a release-tuned logger that keeps only warnings and errors.
  factory ForgeLogger.release({
    required String tag,
    LogSink? sink,
  }) {
    return ForgeLogger(
      tag: tag,
      filter: LogFilter.atLeast(LogLevel.warning),
      sink: sink,
    );
  }

  /// The scope this logger reports under.
  final String tag;

  /// The active filter.
  final LogFilter filter;

  final LogSink _sink;
  final DateTime Function() _clock;

  /// Logs a debug-level message.
  void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.debug, message, error, stackTrace);

  /// Logs an info-level message.
  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.info, message, error, stackTrace);

  /// Logs a warning-level message.
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, message, error, stackTrace);

  /// Logs an error-level message.
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    final record = LogRecord(
      timestamp: _clock(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    if (!filter.accepts(record)) return;
    // Logging must never crash the app; drop sink failures silently.
    try {
      unawaited(_sink.write(record));
    } catch (_) {}
  }

  /// Returns a logger sharing this sink/filter under a more specific [subTag].
  ForgeLogger child(String subTag) => ForgeLogger(
        tag: '$tag.$subTag',
        filter: filter,
        sink: _sink,
        clock: _clock,
      );
}
