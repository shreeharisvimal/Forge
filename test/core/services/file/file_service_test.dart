// Tests for the file service.
//
// A temp directory stands in for the app-documents directory so every
// operation is exercised against the real filesystem without touching user
// data.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/file/file_service.dart';

void main() {
  late Directory base;
  late FileService service;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('forge_file_test_');
    service = FileService(baseDirectory: base);
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  String pathOf(String name) =>
      '${base.path}${Platform.pathSeparator}$name';

  group('read/write', () {
    test('writeText then readText round-trips content', () async {
      final write = await service.writeText(pathOf('a.txt'), 'hello');
      expect(write.isSuccess, isTrue);

      final read = await service.readText(pathOf('a.txt'));
      expect(read.valueOrNull, 'hello');
    });

    test('writeBytes then readBytes round-trips bytes', () async {
      await service.writeBytes(pathOf('a.bin'), [1, 2, 3, 4]);

      final read = await service.readBytes(pathOf('a.bin'));
      expect(read.valueOrNull, [1, 2, 3, 4]);
    });

    test('writeText creates parent directories', () async {
      final result =
          await service.writeText('${pathOf('nested')}${Platform.pathSeparator}deep${Platform.pathSeparator}b.txt', 'x');
      expect(result.isSuccess, isTrue);
      expect(
        await File(
          '${pathOf('nested')}${Platform.pathSeparator}deep${Platform.pathSeparator}b.txt',
        ).exists(),
        isTrue,
      );
    });

    test('writeText with overwrite:false fails when the file exists', () async {
      await service.writeText(pathOf('a.txt'), 'first');

      final result = await service.writeText(
        pathOf('a.txt'),
        'second',
        overwrite: false,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<FileFailure>());
      expect((await service.readText(pathOf('a.txt'))).valueOrNull, 'first');
    });

    test('reading a missing file fails with a FileFailure', () async {
      final result = await service.readText(pathOf('missing.txt'));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<FileFailure>());
    });
  });

  group('delete/copy/move/exists', () {
    test('exists reports presence', () async {
      expect((await service.exists(pathOf('a.txt'))).valueOrNull, isFalse);
      await service.writeText(pathOf('a.txt'), 'x');
      expect((await service.exists(pathOf('a.txt'))).valueOrNull, isTrue);
    });

    test('delete removes the file; missing delete succeeds', () async {
      await service.writeText(pathOf('a.txt'), 'x');

      final deleted = await service.delete(pathOf('a.txt'));
      expect(deleted.isSuccess, isTrue);
      expect((await service.exists(pathOf('a.txt'))).valueOrNull, isFalse);

      final missing = await service.delete(pathOf('a.txt'));
      expect(missing.isSuccess, isTrue);
    });

    test('copy duplicates content to a new path', () async {
      await service.writeText(pathOf('src.txt'), 'copied');

      final result = await service.copy(pathOf('src.txt'), pathOf('dst.txt'));

      expect(result.isSuccess, isTrue);
      expect((await service.readText(pathOf('dst.txt'))).valueOrNull, 'copied');
    });

    test('move relocates the file', () async {
      await service.writeText(pathOf('src.txt'), 'moved');

      final result = await service.move(pathOf('src.txt'), pathOf('dst.txt'));

      expect(result.isSuccess, isTrue);
      expect((await service.exists(pathOf('src.txt'))).valueOrNull, isFalse);
      expect((await service.readText(pathOf('dst.txt'))).valueOrNull, 'moved');
    });
  });

  group('size/directories', () {
    test('sizeOf returns the byte length', () async {
      await service.writeText(pathOf('a.txt'), '12345');

      final size = await service.sizeOf(pathOf('a.txt'));
      expect(size.valueOrNull, 5);
    });

    test('sizeOf fails for a missing file', () async {
      final result = await service.sizeOf(pathOf('missing.txt'));
      expect(result.isFailure, isTrue);
    });

    test('createDirectory and list enumerate files recursively', () async {
      await service.createDirectory('${pathOf('dir')}${Platform.pathSeparator}sub');
      await service.writeText(
        '${pathOf('dir')}${Platform.pathSeparator}sub${Platform.pathSeparator}f.txt',
        'x',
      );

      final listing = await service.list(
        Directory(pathOf('dir')),
        recursive: true,
      );

      expect(listing.valueOrNull, hasLength(1));
      expect(listing.valueOrNull!.single.path, contains('f.txt'));
    });
  });

  group('path safety', () {
    test('writing outside the base directory is rejected', () async {
      final outside = await Directory.systemTemp.createTemp('forge_escape_');

      final result = await service.writeText(
        '${outside.path}${Platform.pathSeparator}evil.txt',
        'x',
      );

      expect(result.isFailure, isTrue);
      final failure = result.failureOrNull;
      expect(failure, isA<FileFailure>());
      expect(failure!.cause, isA<UnsafePathException>());
      await outside.delete(recursive: true);
    });

    test('safePath returns a normalized in-base path', () async {
      final result = await service.safePath(
        '${pathOf('sub')}${Platform.pathSeparator}..'
        '${Platform.pathSeparator}a.txt',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, contains('a.txt'));
    });
  });

  group('temp helpers', () {
    test('tempFile creates an empty file', () async {
      final result = await service.tempFile(prefix: 't');

      expect(result.isSuccess, isTrue);
      expect(await result.valueOrNull!.exists(), isTrue);
      expect(await result.valueOrNull!.length(), 0);
    });

    test('tempDirectory creates a directory', () async {
      final result = await service.tempDirectory(prefix: 'd');

      expect(result.isSuccess, isTrue);
      expect(await result.valueOrNull!.exists(), isTrue);
    });
  });
}
