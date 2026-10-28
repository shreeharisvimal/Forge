// File service for the Forge application.
//
// Centralized file-system access: read, write, delete, copy, move, exists
// and the safe-path helpers every other service builds on. All operations
// return a [Result] and classify file-system exceptions as [FileFailure] so
// callers never have to reason about raw [FileSystemException]s.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// Thrown when a requested path escapes the service's base directory.
class UnsafePathException implements Exception {
  /// Creates an unsafe-path exception.
  const UnsafePathException(this.path);

  /// The offending path.
  final String path;

  @override
  String toString() => 'UnsafePathException: $path';
}

/// Centralized file-system operations for Forge.
class FileService {
  /// Creates a file service rooted at [baseDirectory].
  ///
  /// When [baseDirectory] is null the app-documents directory is resolved
  /// lazily via path_provider. [logger] optionally reports failures.
  FileService({Directory? baseDirectory, ForgeLogger? logger})
      : _baseDirectory = baseDirectory,
        _logger = logger;

  /// Creates a service rooted at the app's documents directory.
  static Future<FileService> root({ForgeLogger? logger}) async {
    final directory = await getApplicationDocumentsDirectory();
    return FileService(baseDirectory: directory, logger: logger);
  }

  final Directory? _baseDirectory;
  final ForgeLogger? _logger;

  /// The resolved base directory (documents dir when none was injected).
  Future<Directory> get _base async =>
      _baseDirectory ?? await getApplicationDocumentsDirectory();

  /// Normalizes [path] and, when a base is set, ensures it stays inside it.
  ///
  /// Relative paths are rooted at the base directory so callers can hand in
  /// paths like `photos/2026-01-01/a.jpg` without knowing where the base is.
  Future<String> _resolve(String path) async {
    final base = await _base;
    final input = File(path);
    final joined = input.isAbsolute
        ? input.path
        : '${base.path}${Platform.pathSeparator}${input.path}';
    final normalized = File(joined).absolute.path;
    final basePath = base.absolute.path;
    final baseWithSeparator = basePath.endsWith(Platform.pathSeparator)
        ? basePath
        : '$basePath${Platform.pathSeparator}';
    if (!normalized.startsWith(baseWithSeparator) &&
        normalized != basePath) {
      throw UnsafePathException(normalized);
    }
    return normalized;
  }

  /// Reads the text content of the file at [path].
  Future<Result<String>> readText(String path) => Result.tryAsync(
        () async => File(await _resolve(path)).readAsString(),
        classify: _fileFailure,
      );

  /// Reads the bytes of the file at [path].
  Future<Result<List<int>>> readBytes(String path) => Result.tryAsync(
        () async => File(await _resolve(path)).readAsBytes(),
        classify: _fileFailure,
      );

  /// Writes [content] to [path], creating parent directories as needed.
  Future<Result<void>> writeText(
    String path,
    String content, {
    bool overwrite = true,
  }) async {
    try {
      final file = File(await _resolve(path));
      if (await file.exists() && !overwrite) {
        return const Failure(FileFailure('File already exists.'));
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Writes [bytes] to [path], creating parent directories as needed.
  Future<Result<void>> writeBytes(
    String path,
    List<int> bytes, {
    bool overwrite = true,
  }) async {
    try {
      final file = File(await _resolve(path));
      if (await file.exists() && !overwrite) {
        return const Failure(FileFailure('File already exists.'));
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Deletes the file at [path]; a missing file is a success.
  Future<Result<void>> delete(String path) => Result.tryAsync(
        () async {
          final file = File(await _resolve(path));
          if (await file.exists()) await file.delete();
        },
        classify: _fileFailure,
      );

  /// Copies the file at [source] to [destination].
  Future<Result<void>> copy(String source, String destination) async {
    try {
      final from = File(await _resolve(source));
      final to = File(await _resolve(destination));
      await to.parent.create(recursive: true);
      await from.copy(to.path);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Moves the file at [source] to [destination], creating parents.
  Future<Result<void>> move(String source, String destination) async {
    try {
      final from = File(await _resolve(source));
      final to = File(await _resolve(destination));
      await to.parent.create(recursive: true);
      await from.rename(to.path);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Whether a file exists at [path].
  Future<Result<bool>> exists(String path) => Result.tryAsync(
        () async => File(await _resolve(path)).exists(),
        classify: _fileFailure,
      );

  /// The size in bytes of the file at [path].
  Future<Result<int>> sizeOf(String path) => Result.tryAsync(
        () async {
          final file = File(await _resolve(path));
          if (!await file.exists()) {
            throw const FileSystemException('File does not exist');
          }
          return await file.length();
        },
        classify: _fileFailure,
      );

  /// Creates a directory (and parents) at [path].
  Future<Result<Directory>> createDirectory(
    String path, {
    bool recursive = true,
  }) => Result.tryAsync(
        () async {
          final directory = Directory(await _resolve(path));
          if (!await directory.exists()) {
            await directory.create(recursive: recursive);
          }
          return directory;
        },
        classify: _fileFailure,
      );

  /// Lists the files under [directory], optionally [recursive].
  Future<Result<List<File>>> list(
    Directory directory, {
    bool recursive = false,
  }) async {
    try {
      final root = Directory(await _resolve(directory.path));
      if (!await root.exists()) {
        return const Failure(FileFailure('Directory does not exist.'));
      }
      final files = <File>[];
      await for (final entity
          in root.list(recursive: recursive, followLinks: false)) {
        if (entity is File) files.add(entity);
      }
      return Success(files);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Creates a uniquely named temporary file in the system temp directory.
  Future<Result<File>> tempFile({String? prefix, String? suffix}) async {
    try {
      final directory = await Directory.systemTemp.createTemp('forge_tmp_');
      final name = '${prefix ?? 'file'}_${DateTime.now().microsecondsSinceEpoch}'
          '${suffix ?? ''}';
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(const []);
      return Success(file);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Creates a uniquely named temporary directory in the system temp area.
  Future<Result<Directory>> tempDirectory({String? prefix}) async {
    try {
      final directory =
          await Directory.systemTemp.createTemp('forge_${prefix ?? 'tmp'}_');
      return Success(directory);
    } catch (error, stackTrace) {
      return Failure(_fileFailure(error, stackTrace));
    }
  }

  /// Returns the normalized, base-checked absolute form of [path].
  Future<Result<String>> safePath(String path) => Result.tryAsync(
        () => _resolve(path),
        classify: _fileFailure,
      );

  ForgeFailure _fileFailure(Object error, StackTrace stackTrace) {
    _logger?.error('File operation failed', error, stackTrace);
    return switch (error) {
      UnsafePathException() => FileFailure(
          'Path is outside the app directory: ${error.path}',
          cause: error,
        ),
      FileSystemException() =>
        FileFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}
