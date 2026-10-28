// Day-detail photos for the Forge application.
//
// The progress-photo grid inside the day-detail sheet: thumbnails with a
// delete affordance plus an "add photos" tile. Pure presentation; the owning
// sheet drives picking and persistence.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// The photo grid of the day-detail sheet.
class PhotosSection extends StatelessWidget {
  /// Creates the photos section.
  const PhotosSection({
    super.key,
    required this.photoThumbs,
    required this.onAdd,
    required this.onDelete,
    this.adding = false,
    this.max = 9,
  });

  /// Thumbnail file paths.
  final List<String> photoThumbs;

  /// Invoked to add photos.
  final VoidCallback onAdd;

  /// Invoked with the index of a photo to delete.
  final ValueChanged<int> onDelete;

  /// Whether a pick is in flight.
  final bool adding;

  /// Maximum number of photos allowed.
  final int max;

  static const double _tileSize = 84;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final canAdd = photoThumbs.length < max;

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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < photoThumbs.length; i++)
              _PhotoThumb(
                path: photoThumbs[i],
                onView: () => onDelete(i),
                onDelete: () => onDelete(i),
              ),
            if (canAdd) _AddPhotoTile(onTap: onAdd, loading: adding),
          ],
        ),
        if (photoThumbs.isEmpty && !adding)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Snap a physique check-in and track your progress.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceMuted),
            ),
          ),
      ],
    );
  }
}

/// A single thumbnail with a delete affordance.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.path, required this.onView, required this.onDelete});

  final String path;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.medium);
    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.surfaceHigh,
        borderRadius: radius,
        border: const GlassBorder(),
      ),
      borderRadius: radius,
      width: PhotosSection._tileSize,
      height: PhotosSection._tileSize,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.xxs,
              right: AppSpacing.xxs,
              child: GlassIconButton(
                icon: Icons.close_rounded,
                size: AppIconSize.extraSmall,
                variant: GlassIconButtonVariant.filled,
                semanticLabel: 'Delete photo',
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed tile that starts a photo pick.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassPressable(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      semanticLabel: 'Add photos',
      child: Container(
        width: PhotosSection._tileSize,
        height: PhotosSection._tileSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: colors.borderStrong,
            width: AppBorderWidth.hairline,
          ),
        ),
        child: loading
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  strokeWidth: AppBorderWidth.thin,
                  color: colors.secondary,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: colors.secondary,
                    size: AppIconSize.medium,
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Add',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ],
              ),
      ),
    );
  }
}
