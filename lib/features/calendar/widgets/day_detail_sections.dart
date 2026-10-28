// Day-detail sections for the Forge application.
//
// Stateless building blocks for the day-detail sheet. Each section renders a
// single concern and reports changes upward through callbacks; the owning
// sheet is the only place that persists values.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/forge_design.dart';
import '../../../models/workout_session.dart';
import '../domain/calendar_models.dart';
import '../domain/calendar_queries.dart';

/// Sliders for sleep and water with live value labels.
class SleepWaterSection extends StatelessWidget {
  /// Creates the sleep/water section.
  const SleepWaterSection({
    super.key,
    required this.sleepHours,
    required this.waterLitres,
    required this.onSleepChanged,
    required this.onWaterChanged,
    required this.onSleepCleared,
    required this.onWaterCleared,
  });

  /// Current sleep hours (null when not logged).
  final double? sleepHours;

  /// Current water litres (null when not logged).
  final double? waterLitres;

  /// Invoked as the sleep slider moves.
  final ValueChanged<double> onSleepChanged;

  /// Invoked as the water slider moves.
  final ValueChanged<double> onWaterChanged;

  /// Invoked to clear the sleep value.
  final VoidCallback onSleepCleared;

  /// Invoked to clear the water value.
  final VoidCallback onWaterCleared;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(),
      ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            icon: Icons.bedtime_outlined,
            label: 'Sleep',
            value: sleepHours ?? 0,
            min: 0,
            max: 12,
            divisions: 24,
            format: (value) => '${value.toStringAsFixed(1)} h',
            activeColor: Theme.of(context).forgeColors.secondary,
            onChanged: onSleepChanged,
            onCleared: sleepHours == null ? null : onSleepCleared,
          ),
          SizedBox(height: AppSpacing.lg),
          _SliderRow(
            icon: Icons.water_drop_outlined,
            label: 'Water',
            value: waterLitres ?? 0,
            min: 0,
            max: 8,
            divisions: 32,
            format: (value) => '${value.toStringAsFixed(2)} L',
            activeColor: Theme.of(context).forgeColors.info,
            onChanged: onWaterChanged,
            onCleared: waterLitres == null ? null : onWaterCleared,
          ),
        ],
      ),
    );
  }
}

/// One labelled slider row used by [SleepWaterSection].
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    required this.activeColor,
    required this.onCleared,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.small, color: activeColor),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colors.onSurface),
            ),
            const Spacer(),
            Text(
              format(value),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (onCleared != null) ...[
              SizedBox(width: AppSpacing.xs),
              GlassIconButton(
                icon: Icons.close_rounded,
                size: AppIconSize.extraSmall,
                variant: GlassIconButtonVariant.ghost,
                semanticLabel: 'Clear $label',
                onPressed: onCleared,
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        GlassSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A row of five mood emoji chips.
class MoodSection extends StatelessWidget {
  /// Creates the mood section.
  const MoodSection({
    super.key,
    required this.mood,
    required this.onSelected,
  });

  /// The current mood (1-5), or null.
  final int? mood;

  /// Invoked when a mood is chosen.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var value = 1; value <= 5; value++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: GlassChip(
                    label: moodEmoji(value)!,
                    selected: mood == value,
                    onTap: () => onSelected(value),
                    semanticLabel: 'Mood ${moodLabel(value)}',
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          moodLabel(mood),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// The workout-complete toggle plus the day's performed sessions.
class WorkoutSection extends StatelessWidget {
  /// Creates the workout section.
  const WorkoutSection({
    super.key,
    required this.completed,
    required this.sessions,
    required this.onChanged,
  });

  /// Whether the day's workout is marked complete.
  final bool completed;

  /// The performed sessions for the day.
  final List<WorkoutSession> sessions;

  /// Invoked when the toggle changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(),
      ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: AppIconSize.small,
                color: colors.primary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Workout',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              GlassSwitch(
                value: completed,
                semanticLabel: 'Workout completed',
                onChanged: onChanged,
              ),
            ],
          ),
          if (sessions.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            for (final session in sessions)
              _SessionTile(session: session),
          ],
        ],
      ),
    );
  }
}

/// A read-only summary tile for a performed session.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final parts = <String>[
      '${session.exercises.length} exercises',
    ];
    if (session.durationMinutes > 0) parts.add('${session.durationMinutes} min');
    if (session.volume > 0) parts.add('${session.volume.toStringAsFixed(0)} kg');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: GlassListTile(
        title: 'Workout session',
        subtitle: parts.join(' · '),
        leading: Icon(Icons.check_circle_rounded, color: colors.success),
      ),
    );
  }
}

/// The daily weigh-in field.
class WeightFieldSection extends StatelessWidget {
  /// Creates the weight section.
  const WeightFieldSection({
    super.key,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  /// Weight unit label, e.g. "kg".
  final String unit;

  /// The weight controller.
  final TextEditingController controller;

  /// Invoked as the field changes.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: controller,
      label: 'Weight ($unit)',
      hintText: 'e.g. ${unit == 'kg' ? '82.4' : '181.5'}',
      prefixIcon: Icons.monitor_weight_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
    );
  }
}

/// A multiline notes field with a live character counter.
class NotesFieldSection extends StatefulWidget {
  /// Creates the notes section.
  const NotesFieldSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  /// The notes controller.
  final TextEditingController controller;

  /// Invoked as the notes change.
  final ValueChanged<String> onChanged;

  @override
  State<NotesFieldSection> createState() => _NotesFieldSectionState();
}

class _NotesFieldSectionState extends State<NotesFieldSection> {
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(NotesFieldSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _length = widget.controller.text.length;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final length = widget.controller.text.length;
    if (length != _length) {
      setState(() => _length = length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final remaining = maxNotesLength - _length;
    final nearLimit = remaining <= 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassTextField(
          controller: widget.controller,
          label: 'Notes',
          hintText: 'How did today feel? What did you work on?',
          prefixIcon: Icons.notes_rounded,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(maxNotesLength)],
          onChanged: widget.onChanged,
        ),
        SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_length / $maxNotesLength',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: nearLimit ? colors.danger : colors.onSurfaceMuted,
                ),
          ),
        ),
      ],
    );
  }
}
