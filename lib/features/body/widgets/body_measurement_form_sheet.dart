// Body measurement form sheet for the Forge application.
//
// A full-screen glass sheet for logging or editing a day's measurements:
// every trackable field, notes and progress photos. Saves through the
// [BodyMeasurementEditor] (upsert + prune) and pops `true` on success so the
// caller can confirm the write.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../data/body_photo_service.dart';
import '../domain/body_measurement_fields.dart';
import '../providers/body_providers.dart';
import 'body_form_fields.dart';

/// Presents the measurement form for [date], optionally prefilled with
/// [initial]. Resolves `true` when a record was saved.
Future<bool?> showBodyMeasurementFormSheet(
  BuildContext context, {
  required DateTime date,
  BodyMeasurement? initial,
}) {
  return GlassBottomSheet.show<bool>(
    context,
    showDragHandle: true,
    maxChildSize: 0.95,
    builder: (context) =>
        BodyMeasurementFormSheet(date: date, initial: initial),
  );
}

/// The editable body-measurement form.
class BodyMeasurementFormSheet extends ConsumerStatefulWidget {
  /// Creates the form.
  const BodyMeasurementFormSheet({
    super.key,
    required this.date,
    this.initial,
  });

  /// The day being logged or edited.
  final DateTime date;

  /// Pre-existing record to edit, or null for a fresh entry.
  final BodyMeasurement? initial;

  @override
  ConsumerState<BodyMeasurementFormSheet> createState() =>
      _BodyMeasurementFormSheetState();
}

class _BodyMeasurementFormSheetState
    extends ConsumerState<BodyMeasurementFormSheet> {
  late final Map<BodyField, TextEditingController> _controllers;
  late final TextEditingController _notesController;
  late List<BodyPhoto> _photos;
  final List<BodyPhoto> _removedPhotos = [];
  bool _saving = false;
  bool _addingPhotos = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _controllers = {
      for (final field in BodyField.all)
        field: TextEditingController(
          text: _fieldText(initial == null ? null : field.valueOf(initial)),
        ),
    };
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _photos = [
      for (var i = 0; i < (initial?.photos.length ?? 0); i++)
        BodyPhoto(
          path: initial!.photos[i],
          thumbPath: initial.photoThumbs[i],
        ),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  static String _fieldText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString());

  static double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _addPhotos() async {
    final service = ref.read(bodyPhotoServiceProvider);
    setState(() => _addingPhotos = true);
    final result = await service.pick(day: widget.date, max: 9 - _photos.length);
    if (!mounted) return;
    setState(() => _addingPhotos = false);
    result.when(
      success: (photos) {
        if (photos.isEmpty) return;
        setState(() => _photos.addAll(photos));
      },
      failure: (failure) {
        if (mounted) context.showError(failure.message);
      },
    );
  }

  Future<void> _removePhoto(int index) async {
    final photo = _photos[index];
    setState(() {
      _photos.removeAt(index);
      _removedPhotos.add(photo);
    });
  }

  Future<void> _save() async {
    final editor = ref.read(bodyMeasurementEditorProvider);
    final photoService = ref.read(bodyPhotoServiceProvider);

    final measurement = BodyMeasurement(
      id: widget.initial?.id,
      date: dateOnly(widget.date),
      weight: _parse(_controllers[BodyField.weight]!.text),
      waist: _parse(_controllers[BodyField.waist]!.text),
      hip: _parse(_controllers[BodyField.hip]!.text),
      chest: _parse(_controllers[BodyField.chest]!.text),
      neck: _parse(_controllers[BodyField.neck]!.text),
      shoulders: _parse(_controllers[BodyField.shoulders]!.text),
      leftArm: _parse(_controllers[BodyField.leftArm]!.text),
      rightArm: _parse(_controllers[BodyField.rightArm]!.text),
      leftForearm: _parse(_controllers[BodyField.leftForearm]!.text),
      rightForearm: _parse(_controllers[BodyField.rightForearm]!.text),
      leftThigh: _parse(_controllers[BodyField.leftThigh]!.text),
      rightThigh: _parse(_controllers[BodyField.rightThigh]!.text),
      leftCalf: _parse(_controllers[BodyField.leftCalf]!.text),
      rightCalf: _parse(_controllers[BodyField.rightCalf]!.text),
      bodyFat: _parse(_controllers[BodyField.bodyFat]!.text),
      notes: _notesController.text.trim(),
      photos: [for (final photo in _photos) photo.path],
      photoThumbs: [for (final photo in _photos) photo.thumbPath],
    );

    setState(() => _saving = true);
    await editor.save(measurement);
    for (final photo in _removedPhotos) {
      await photoService.delete(photo);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(bodySettingsProvider);
    final colors = Theme.of(context).forgeColors;
    final isEditing = widget.initial != null;
    final maxPhotos = 9;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit measurements' : 'Log measurements',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: colors.onSurface),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      formatDayLabel(widget.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                icon: Icons.close_rounded,
                variant: GlassIconButtonVariant.ghost,
                semanticLabel: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          BodyFormFields(
            controllers: _controllers,
            notesController: _notesController,
            weightUnit: settings.weightUnit,
            lengthUnit: settings.lengthUnit,
          ),
          SizedBox(height: AppSpacing.lg),
          _PhotoStrip(
            photos: _photos,
            adding: _addingPhotos,
            canAdd: _photos.length < maxPhotos,
            onAdd: _addPhotos,
            onRemove: _removePhoto,
          ),
          SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: isEditing ? 'Save changes' : 'Save measurement',
                  icon: Icons.check_rounded,
                  onPressed: _saving ? null : _save,
                  loading: _saving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The progress-photo thumbnails of the form with an add tile.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.adding,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final List<BodyPhoto> photos;
  final bool adding;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  static const double _tileSize = 72;

  @override
  Widget build(BuildContext context) {
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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < photos.length; i++)
              GlassContainer(
                width: _tileSize,
                height: _tileSize,
                borderRadius: BorderRadius.circular(AppRadius.small),
                decoration: GlassDecoration(
                  color: colors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: const GlassBorder(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(photos[i].thumbPath),
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
                          semanticLabel: 'Remove photo',
                          onPressed: () => onRemove(i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (canAdd)
              GlassPressable(
                onTap: adding ? null : onAdd,
                borderRadius: BorderRadius.circular(AppRadius.small),
                semanticLabel: 'Add photos',
                child: Container(
                  width: _tileSize,
                  height: _tileSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: colors.borderStrong,
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: adding
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(
                            strokeWidth: AppBorderWidth.thin,
                            color: colors.secondary,
                          ),
                        )
                      : Icon(
                          Icons.add_a_photo_outlined,
                          color: colors.secondary,
                          size: AppIconSize.medium,
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Formats the sheet header date, e.g. "Sun, Aug 6".
String formatDayLabel(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
