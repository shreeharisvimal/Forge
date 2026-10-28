// Selected-day summary card for the Forge application.
//
// The glass card below the calendar grid summarizing the selected day. Tapping
// it opens the day-detail sheet; the hero tag links the two for a smooth
// container flight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/forge_design.dart';
import '../../../services/providers.dart';
import '../../dashboard/widgets/dashboard_formatters.dart';
import '../domain/calendar_queries.dart';
import '../providers/calendar_providers.dart';
import 'calendar_marker_badges.dart';
import 'day_detail_sheet.dart';

/// The day summary shown beneath the grid.
class SelectedDaySummaryCard extends ConsumerWidget {
  /// Creates the summary card.
  const SelectedDaySummaryCard({super.key, required this.day});

  /// The selected day.
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).forgeColors;
    final view = ref.watch(calendarDayViewProvider(day));
    final unit = ref.watch(settingsProvider).weightUnit;
    final previousWeight = ref.watch(calendarPreviousWeightProvider(day));

    return GlassPressable(
      onTap: () => showDayDetailSheet(context, day: day),
      borderRadius: BorderRadius.circular(AppRadius.large),
      semanticLabel: 'Open details for ${formatFullDayLabel(day)}',
      child: GlassContainer(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDayLabel(day),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colors.onSurface),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          relativeDay(day, DateTime.now()),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                  if (view.markers.isNotEmpty)
                    CalendarMarkerBadges(
                      markers: view.markers,
                      limit: 4,
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              if (view.hasData)
                Row(
                  children: [
                    _Stat(
                      icon: Icons.monitor_weight_outlined,
                      color: colors.success,
                      value: view.weight == null
                          ? '—'
                          : formatWeight(view.weight!, unit),
                      caption: _weightCaption(view.weight, previousWeight),
                    ),
                    _Stat(
                      icon: Icons.bedtime_outlined,
                      color: colors.secondary,
                      value: view.sleepHours == null
                          ? '—'
                          : '${view.sleepHours!.toStringAsFixed(1)} h',
                      caption: 'Sleep',
                    ),
                    _Stat(
                      icon: Icons.water_drop_outlined,
                      color: colors.info,
                      value: view.waterLitres == null
                          ? '—'
                          : '${view.waterLitres!.toStringAsFixed(2)} L',
                      caption: 'Water',
                    ),
                    _Stat(
                      icon: Icons.mood_rounded,
                      color: colors.warning,
                      value: moodEmoji(view.mood) ?? '—',
                      caption: moodLabel(view.mood),
                    ),
                    _Stat(
                      icon: Icons.fitness_center_rounded,
                      color: colors.primary,
                      value: '${view.sessions.length}',
                      caption: 'Workouts',
                    ),
                    _Stat(
                      icon: Icons.photo_camera_outlined,
                      color: colors.secondary,
                      value: '${view.photoCount}',
                      caption: 'Photos',
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.edit_calendar_outlined,
                      size: AppIconSize.small,
                      color: colors.onSurfaceMuted,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Nothing logged yet — tap to add weight, sleep, water or notes.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }

  static String _weightCaption(double? current, double? previous) {
    if (current == null || previous == null) return 'Weight';
    final delta = current - previous;
    if (delta == 0) return 'Same as before';
    return delta < 0
        ? '${delta.toStringAsFixed(1)} from prev'
        : '+${delta.toStringAsFixed(1)} from prev';
  }
}

/// A compact stat tile used by the summary card.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: AppIconSize.small, color: color),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
