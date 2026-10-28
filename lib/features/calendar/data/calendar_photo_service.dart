// Calendar progress-photo service for the Forge application.
//
// Picks images from the device, prepares them with the [ImageService]
// (resize + JPEG compression + thumbnail) and stores them through the
// [FileService] under the app documents directory. The calendar model only
// persists the resulting local file paths.
library;

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../core/services/error_handling/forge_failures.dart';
import '../../../core/services/error_handling/result.dart';
import '../../../core/services/file/file_service.dart';
import '../../../core/services/images/image_service.dart';

/// One stored photo and its ready-to-display thumbnail path.
class CalendarPhoto {
  /// Creates a photo pair.
  const CalendarPhoto({required this.path, required this.thumbPath});

  /// Full-size image path.
  final String path;

  /// Small thumbnail path.
  final String thumbPath;
}

/// Picks and persists progress photos for a calendar day.
abstract interface class CalendarPhotoService {
  /// Picks up to [max] images and stores them under the [day]'s folder.
  Future<Result<List<CalendarPhoto>>> pick({required DateTime day, int max = 9});

  /// Deletes the stored files behind [photo], if any.
  Future<Result<void>> delete(CalendarPhoto photo);
}

/// Device-backed [CalendarPhotoService] using image_picker + file storage.
class DeviceCalendarPhotoService implements CalendarPhotoService {
  /// Creates the service.
  DeviceCalendarPhotoService({
    required this.imageService,
    required this.fileService,
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  /// Image processing.
  final ImageService imageService;

  /// File storage rooted at the app documents directory.
  final FileService fileService;

  final ImagePicker _picker;

  /// Max edge length of the stored full-size image.
  static const int _maxEdge = 1920;

  /// JPEG quality used for the full-size image.
  static const int _quality = 85;

  /// Thumbnail edge length.
  static const int _thumbEdge = 256;

  @override
  Future<Result<List<CalendarPhoto>>> pick({
    required DateTime day,
    int max = 9,
  }) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) {
      return const Success([]);
    }

    final folder = _folderFor(day);
    final photos = <CalendarPhoto>[];
    final errors = <String>[];

    for (var i = 0; i < picked.length && photos.length < max; i++) {
      final bytes = await _readBytes(picked[i]);
      if (bytes == null) {
        errors.add(picked[i].name);
        continue;
      }

      final resized = await imageService.resize(
        bytes,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
      );
      final compressed = resized.isSuccess
          ? await imageService.compress(
              resized.valueOrNull!.bytes,
              quality: _quality,
            )
          : resized;

      final thumb = resized.isSuccess
          ? await imageService.thumbnail(
              bytes,
              size: _thumbEdge,
            )
          : null;

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final photoPath = '$folder/${stamp}_$i.jpg';
      final thumbPath = '$folder/${stamp}_${i}_thumb.jpg';

      final wrotePhoto = compressed.isSuccess
          ? await fileService.writeBytes(
              photoPath,
              compressed.valueOrNull!.bytes,
            )
          : compressed;
      final wroteThumb = thumb != null && thumb.isSuccess
          ? await fileService.writeBytes(
              thumbPath,
              thumb.valueOrNull!.bytes,
            )
          : const Success<void>(null);

      if (wrotePhoto.isSuccess && (thumb == null || wroteThumb.isSuccess)) {
        photos.add(CalendarPhoto(path: photoPath, thumbPath: thumbPath));
      } else {
        errors.add(picked[i].name);
      }
    }

    if (photos.isEmpty && errors.isNotEmpty) {
      return Failure(ImageFailure('Could not store the selected photos.'));
    }
    return Success(photos);
  }

  @override
  Future<Result<void>> delete(CalendarPhoto photo) async {
    final result = await fileService.delete(photo.path);
    await fileService.delete(photo.thumbPath);
    return result;
  }

  Future<Uint8List?> _readBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  String _folderFor(DateTime day) {
    final key = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return 'photos/$key';
  }
}
