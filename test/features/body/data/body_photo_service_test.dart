// Tests for the body progress-photo service.
//
// Uses a fake image picker plus the real [ImageService] and a [FileService]
// rooted at a temp directory, so the whole pick → resize → compress →
// thumbnail → store pipeline runs against real code without plugins.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/file/file_service.dart';
import 'package:forge/core/services/images/image_service.dart';
import 'package:forge/features/body/data/body_photo_service.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this._files);

  final List<XFile> _files;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async =>
      _files;
}

Uint8List _pngBytes() {
  final image = img.Image(width: 4, height: 3);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  late Directory baseDir;
  late DeviceBodyPhotoService service;
  final validBytes = _pngBytes();

  setUp(() async {
    baseDir = await Directory.systemTemp.createTemp('forge_photo_test');
    service = DeviceBodyPhotoService(
      imageService: ImageService(),
      fileService: FileService(baseDirectory: baseDir),
      picker: _FakeImagePicker([
        XFile('${baseDir.path}/selected.png'),
      ]),
    );
    await File('${baseDir.path}/selected.png').writeAsBytes(validBytes);
  });

  tearDown(() {
    if (baseDir.existsSync()) baseDir.deleteSync(recursive: true);
  });

  test('stores a picked photo with a thumbnail under the day folder',
      () async {
    final result =
        await service.pick(day: DateTime(2026, 8, 4), max: 9);

    expect(result.isSuccess, isTrue);
    final photo = result.valueOrNull!.single;
    expect(photo.path, contains('body_photos/2026-08-04/'));
    expect(photo.thumbPath, contains('body_photos/2026-08-04/'));
    expect(photo.path, endsWith('.jpg'));
    expect(photo.thumbPath, endsWith('.jpg'));

    expect(File('${baseDir.path}/${photo.path}').existsSync(), isTrue);
    expect(File('${baseDir.path}/${photo.thumbPath}').existsSync(), isTrue);
  });

  test('groups photos by day folder', () async {
    final first = await service.pick(day: DateTime(2026, 8, 4), max: 9);
    final second = await service.pick(day: DateTime(2026, 8, 5), max: 9);

    expect(first.valueOrNull!.single.path, contains('2026-08-04'));
    expect(second.valueOrNull!.single.path, contains('2026-08-05'));
  });

  test('an empty selection returns an empty success', () async {
    service = DeviceBodyPhotoService(
      imageService: ImageService(),
      fileService: FileService(baseDirectory: baseDir),
      picker: _FakeImagePicker(const []),
    );

    final result = await service.pick(day: DateTime(2026, 8, 4), max: 9);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('an unreadable or corrupt image fails the pick', () async {
    service = DeviceBodyPhotoService(
      imageService: ImageService(),
      fileService: FileService(baseDirectory: baseDir),
      picker: _FakeImagePicker([
        XFile('${baseDir.path}/selected.png'),
      ]),
    );
    await File('${baseDir.path}/selected.png')
        .writeAsBytes([1, 2, 3, 4, 5]);

    final result = await service.pick(day: DateTime(2026, 8, 4), max: 9);

    expect(result.isSuccess, isFalse);
    expect(result.failureOrNull, isA<ImageFailure>());
  });

  test('respects the max photo count', () async {
    service = DeviceBodyPhotoService(
      imageService: ImageService(),
      fileService: FileService(baseDirectory: baseDir),
      picker: _FakeImagePicker([
        XFile('${baseDir.path}/selected.png'),
        XFile('${baseDir.path}/selected.png'),
        XFile('${baseDir.path}/selected.png'),
      ]),
    );

    final result =
        await service.pick(day: DateTime(2026, 8, 4), max: 2);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.length, 2);
  });

  test('delete removes the stored files', () async {
    final result = await service.pick(day: DateTime(2026, 8, 4), max: 9);
    final photo = result.valueOrNull!.single;
    expect(File('${baseDir.path}/${photo.path}').existsSync(), isTrue);

    final deleteResult = await service.delete(photo);

    expect(deleteResult.isSuccess, isTrue);
    expect(File('${baseDir.path}/${photo.path}').existsSync(), isFalse);
    expect(File('${baseDir.path}/${photo.thumbPath}').existsSync(), isFalse);
  });
}
