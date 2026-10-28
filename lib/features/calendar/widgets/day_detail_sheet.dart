// Day-detail sheet for the Forge application.
//
// A snap glass bottom sheet opened from the calendar. Every field autosaves
// back to storage through the [CalendarDayEditor]; text fields and sliders
// debounce while toggles and mood chips write immediately.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../core/overlays/forge_overlay_extensions.dart';
import '../../../core/utils/dates.dart';
import '../../../services/providers.dart';
import '../../dashboard/widgets/dashboard_formatters.dart';
import '../domain/calendar_models.dart';
import '../domain/calendar_queries.dart';
import '../providers/calendar_providers.dart';
import 'calendar_marker_badges.dart';
import 'day_detail_photos.dart';
import 'day_detail_sections.dart';
import 'measurement_fields_section.dart';
import 'personal_records_section.dart';

/// Opens the day-detail sheet for [day].
Future<void> showDayDetailSheet(BuildContext context, {required DateTime day}) {
  return GlassBottomSheet.show(
    context,
    snap: true,
    initialChildSize: 0.6,
    minChildSize: 0.35,
    maxChildSize: 0.95,
    builder: (context) => DayDetailSheet(day: day),
  );
}

/// The editable day-detail panel.
class DayDetailSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const DayDetailSheet({super.key, required this.day});

  /// The day being edited.
  final DateTime day;

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet> {
  late DateTime _currentDay;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late final Map<MeasurementField, TextEditingController>
      _measurementControllers;
  final _debouncer = _Debouncer(const Duration(milliseconds: 600));
  bool _addingPhotos = false;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.day;
    final view = ref.read(calendarDayViewProvider(_currentDay));
    _weightController = TextEditingController(text: _fieldText(view.weight));
    _notesController = TextEditingController(text: view.notes);
    _measurementControllers = {
      for (final field in MeasurementField.values)
        field: TextEditingController(
          text: _fieldText(measurementFieldValue(view.measurement, field)),
        ),
    };
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _weightController.dispose();
    _notesController.dispose();
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
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

  void _schedule(Future<void> Function() action) {
    _debouncer.run(action);
  }

  Future<void> _saveWeight(String text) async {
    await ref
        .read(calendarDayEditorProvider)
        .setWeight(_currentDay, _parse(text));
  }

  Future<void> _saveNotes(String text) async {
    await ref
        .read(calendarDayEditorProvider)
        .setDaily(date: _currentDay, notes: text);
  }

  Future<void> _saveMeasurements() async {
    await ref.read(calendarDayEditorProvider).setMeasurement(
          date: _currentDay,
          fields: {
            for (final entry in _measurementControllers.entries)
              entry.key: _parse(entry.value.text),
          },
        );
  }

  /// Swipes to the adjacent day, carrying the sheet's fields with it.
  void _changeDay(int delta) {
    final next = dateOnly(_currentDay.add(Duration(days: delta)));
    final view = ref.read(calendarDayViewProvider(next));
    _debouncer.cancel();
    _currentDay = next;
    ref.read(calendarSelectedDayProvider.notifier).state = next;
    ref.read(calendarFocusedDayProvider.notifier).state = next;
    _weightController.text = _fieldText(view.weight);
    _notesController.text = view.notes;
    for (final field in MeasurementField.values) {
      _measurementControllers[field]!.text =
          _fieldText(measurementFieldValue(view.measurement, field));
    }
    setState(() {});
  }

  Future<void> _addPhotos() async {
    setState(() => _addingPhotos = true);
    final result =
        await ref.read(calendarPhotoServiceProvider).pick(day: _currentDay);
    if (!mounted) return;
    setState(() => _addingPhotos = false);
    result.when(
      success: (photos) async {
        if (photos.isEmpty) return;
        final view = ref.read(calendarDayViewProvider(_currentDay));
        await ref.read(calendarDayEditorProvider).setPhotos(
              _currentDay,
              [...view.photos, for (final photo in photos) photo.path],
              [...view.photoThumbs, for (final photo in photos) photo.thumbPath],
            );
        if (mounted) context.showSuccess('Photos added');
      },
      failure: (failure) {
        if (mounted) context.showError(failure.message);
      },
    );
  }

  Future<void> _deletePhoto(int index) async {
    final view = ref.read(calendarDayViewProvider(_currentDay));
    final photos = [...view.photos]..removeAt(index);
    final thumbs = [...view.photoThumbs]..removeAt(index);
    await ref
        .read(calendarDayEditorProvider)
        .setPhotos(_currentDay, photos, thumbs);
    if (mounted) context.showToast('Photo removed');
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(calendarDayViewProvider(_currentDay));
    final unit = ref.watch(settingsProvider).weightUnit;
    final prs = ref.watch(calendarPrsForDayProvider(_currentDay));
    final colors = Theme.of(context).forgeColors;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) {
          _changeDay(1);
        } else if (velocity > 250) {
          _changeDay(-1);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: GlassHero(
          tag:
              'calendar-day-summary-${_currentDay.year}-${_currentDay.month}-${_currentDay.day}',
          child: AnimatedSwitcher(
            duration: AppDuration.short,
            switchInCurve: AppCurves.standard,
            switchOutCurve: AppCurves.standard,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentDay),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DayDetailHeader(day: _currentDay, view: view),
                  SizedBox(height: AppSpacing.lg),
                  WeightFieldSection(
                    unit: unit,
                    controller: _weightController,
                    onChanged: (text) => _schedule(() => _saveWeight(text)),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  SleepWaterSection(
                    sleepHours: view.sleepHours,
                    waterLitres: view.waterLitres,
                    onSleepChanged: (value) => _schedule(
                      () => ref
                          .read(calendarDayEditorProvider)
                          .setDaily(
                            date: _currentDay,
                            sleepHours: () => value,
                          ),
                    ),
                    onWaterChanged: (value) => _schedule(
                      () => ref
                          .read(calendarDayEditorProvider)
                          .setDaily(
                            date: _currentDay,
                            waterLitres: () => value,
                          ),
                    ),
                    onSleepCleared: () => _schedule(
                      () => ref
                          .read(calendarDayEditorProvider)
                          .setDaily(
                            date: _currentDay,
                            sleepHours: () => null,
                          ),
                    ),
                    onWaterCleared: () => _schedule(
                      () => ref
                          .read(calendarDayEditorProvider)
                          .setDaily(
                            date: _currentDay,
                            waterLitres: () => null,
                          ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  MoodSection(
                    mood: view.mood,
                    onSelected: (value) =>
                        ref.read(calendarDayEditorProvider).setDaily(
                              date: _currentDay,
                              mood: () => view.mood == value ? null : value,
                            ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  WorkoutSection(
                    completed: view.workoutCompleted,
                    sessions: view.sessions,
                    onChanged: (value) =>
                        ref.read(calendarDayEditorProvider).setDaily(
                              date: _currentDay,
                              workoutCompleted: value,
                            ),
                  ),
                  if (prs.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.lg),
                    PersonalRecordsSection(
                      entries: prs,
                      weightUnit: unit,
                    ),
                  ],
                  SizedBox(height: AppSpacing.lg),
                  MeasurementFieldsSection(
                    unit: ref.watch(settingsProvider).lengthUnit,
                    controllers: _measurementControllers,
                    onChanged: () => _schedule(_saveMeasurements),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  PhotosSection(
                    photoThumbs: view.photoThumbs,
                    adding: _addingPhotos,
                    onAdd: _addPhotos,
                    onDelete: _deletePhoto,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  NotesFieldSection(
                    controller: _notesController,
                    onChanged: (text) => _schedule(() => _saveNotes(text)),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: AppIconSize.extraSmall,
                        color: colors.success,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Everything saves automatically',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet header: date, relative day and marker badges.
class _DayDetailHeader extends StatelessWidget {
  const _DayDetailHeader({required this.day, required this.view});

  final DateTime day;
  final CalendarDayView view;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatFullDayLabel(day),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              relativeDay(day, DateTime.now()),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceMuted),
            ),
            if (view.markers.isNotEmpty) ...[
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final marker in view.markers)
                        CalendarMarkerRow(
                          marker: marker,
                          label: _markerLabel(marker),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _markerLabel(CalendarDayMarker marker) => switch (marker) {
        CalendarDayMarker.workout => 'Workout',
        CalendarDayMarker.pr => 'New PR',
        CalendarDayMarker.streak => 'Streak',
        CalendarDayMarker.scheduled => 'Scheduled',
        CalendarDayMarker.rest => 'Rest',
        CalendarDayMarker.weight => 'Weight',
        CalendarDayMarker.measurement => 'Measured',
        CalendarDayMarker.sleep => 'Sleep',
        CalendarDayMarker.water => 'Water',
        CalendarDayMarker.mood => 'Mood',
        CalendarDayMarker.photo => 'Photos',
        CalendarDayMarker.notes => 'Notes',
      };
}

/// A tiny debouncer for autosave inputs.
class _Debouncer {
  _Debouncer(this._duration);

  final Duration _duration;
  Timer? _timer;

  void run(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(_duration, action);
  }

  /// Cancels any pending action without running it.
  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
