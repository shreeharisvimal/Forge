// Body photo gallery for the Forge application.
//
// The progress-photo grid for a measurement day: tappable thumbnails opening
// a full-size view. Pure presentation; the owning screen supplies the paths.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// The tappable photo grid of a body measurement day.
class BodyPhotoGallery extends StatelessWidget {
  /// Creates the photo gallery.
  const BodyPhotoGallery({
    super.key,
    required this.photos,
    required this.photoThumbs,
  });

  /// Full-size local file paths.
  final List<String> photos;

  /// Thumbnail local file paths (parallel to [photos]).
  final List<String> photoThumbs;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).forgeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: AppIconSize.small,
              color: colors.secondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Progress photos',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (context, index) => SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => GlassPressable(
              onTap: () => _viewPhoto(context, index),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              semanticLabel: 'View photo ${index + 1}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Image.file(
                  File(photoThumbs.isNotEmpty ? photoThumbs[index] : photos[index]),
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 92,
                    height: 92,
                    color: colors.glassStrong,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _viewPhoto(BuildContext context, int index) {
    GlassBottomSheet.show(
      context,
      showDragHandle: true,
      maxChildSize: 0.95,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.file(
                  File(photos[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).forgeColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Photo ${index + 1} of ${photos.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).forgeColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
