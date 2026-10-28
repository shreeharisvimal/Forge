// Calendar marker badges for the Forge application.
//
// Maps [CalendarDayMarker] kinds to their brand icons and accent colors, and
// renders them as small glass pills on day cells and as labelled rows in the
// day-detail sheet.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../domain/calendar_models.dart';

/// The visual identity of a marker kind.
class CalendarMarkerStyle {
  /// Creates a marker style.
  const CalendarMarkerStyle({required this.icon, required this.color});

  /// The marker icon.
  final IconData icon;

  /// The marker accent color.
  final Color color;
}

/// Looks up the [CalendarMarkerStyle] for [marker].
CalendarMarkerStyle markerStyle(BuildContext context, CalendarDayMarker marker) {
  final colors = Theme.of(context).forgeColors;
  return switch (marker) {
    CalendarDayMarker.workout =>
      CalendarMarkerStyle(icon: Icons.fitness_center_rounded, color: colors.primary),
    CalendarDayMarker.pr =>
      CalendarMarkerStyle(icon: Icons.emoji_events_rounded, color: colors.warning),
    CalendarDayMarker.streak =>
      CalendarMarkerStyle(icon: Icons.local_fire_department_rounded, color: colors.danger),
    CalendarDayMarker.scheduled =>
      CalendarMarkerStyle(icon: Icons.event_repeat_rounded, color: colors.info),
    CalendarDayMarker.rest =>
      CalendarMarkerStyle(icon: Icons.self_improvement_rounded, color: colors.secondary),
    CalendarDayMarker.weight =>
      CalendarMarkerStyle(icon: Icons.monitor_weight_outlined, color: colors.success),
    CalendarDayMarker.measurement =>
      CalendarMarkerStyle(icon: Icons.straighten_rounded, color: colors.info),
    CalendarDayMarker.sleep =>
      CalendarMarkerStyle(icon: Icons.bedtime_outlined, color: colors.secondary),
    CalendarDayMarker.water =>
      CalendarMarkerStyle(icon: Icons.water_drop_outlined, color: colors.info),
    CalendarDayMarker.mood =>
      CalendarMarkerStyle(icon: Icons.mood_rounded, color: colors.warning),
    CalendarDayMarker.photo =>
      CalendarMarkerStyle(icon: Icons.photo_camera_outlined, color: colors.secondary),
    CalendarDayMarker.notes =>
      CalendarMarkerStyle(icon: Icons.notes_rounded, color: colors.onSurfaceMuted),
  };
}

/// A row of compact marker pills.
class CalendarMarkerBadges extends StatelessWidget {
  /// Creates the badges row.
  const CalendarMarkerBadges({
    super.key,
    required this.markers,
    this.limit = 3,
    this.size = AppIconSize.extraSmall,
    this.spacing = AppSpacing.xxs,
  });

  /// The markers to render, in display order.
  final List<CalendarDayMarker> markers;

  /// Maximum number of pills shown before an overflow indicator.
  final int limit;

  /// Pill icon size.
  final double size;

  /// Gap between pills.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (markers.isEmpty) return const SizedBox.shrink();
    final shown = markers.take(limit).toList();
    final overflow = markers.length - shown.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          _pill(context, shown[i]),
          if (i != shown.length - 1 || overflow > 0)
            SizedBox(width: spacing),
        ],
        if (overflow > 0)
          Text(
            '+$overflow',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).forgeColors.onSurfaceMuted),
          ),
      ],
    );
  }

  Widget _pill(BuildContext context, CalendarDayMarker marker) {
    final style = markerStyle(context, marker);
    return GlassContainer(
      decoration: GlassDecoration(
        color: style.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: const GlassBorder(width: AppBorderWidth.none),
      ),
      borderRadius: BorderRadius.circular(AppRadius.small),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      child: Icon(style.icon, size: size, color: style.color),
    );
  }
}

/// A labelled marker row used in the day-detail sheet.
class CalendarMarkerRow extends StatelessWidget {
  /// Creates a labelled marker row.
  const CalendarMarkerRow({super.key, required this.marker, required this.label});

  /// The marker kind.
  final CalendarDayMarker marker;

  /// The human label shown next to the icon.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final style = markerStyle(context, marker);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, size: AppIconSize.small, color: style.color),
        SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}
