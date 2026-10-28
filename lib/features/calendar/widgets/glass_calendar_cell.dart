// Glass calendar cell for the Forge application.
//
// A single day cell rendered through table_calendar's `prioritizedBuilder`.
// Feature wrapper around the generic core [GlassCalendarCell].
library;

import 'package:flutter/material.dart';

import '../../../core/design/widgets/glass_calendar_cell.dart' as core;
import '../domain/calendar_models.dart';
import 'calendar_marker_badges.dart';

/// A frosted-glass calendar day cell (feature wrapper).
class GlassCalendarCell extends StatelessWidget {
  /// Creates a calendar cell.
  const GlassCalendarCell({
    super.key,
    required this.day,
    required this.isOutside,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    this.isPast = false,
    this.isDisabled = false,
    required this.view,
  });

  /// The cell's day.
  final DateTime day;

  /// Whether the day belongs to an adjacent month.
  final bool isOutside;

  /// Whether the day is the selected day.
  final bool isSelected;

  /// Whether the day is today.
  final bool isToday;

  /// Whether the day lies after today (an upcoming, not-yet-logged day).
  final bool isFuture;

  /// Whether the day lies before today. Renders in the standard style.
  final bool isPast;

  /// Whether the cell is locked. Disabled cells render fully muted and take
  /// no part in hero flights.
  final bool isDisabled;

  /// The day's stored content, if any.
  final CalendarDayView? view;

  @override
  Widget build(BuildContext context) {
    final markers = view?.markers ?? const <CalendarDayMarker>[];
    return core.GlassCalendarCell(
      day: day,
      isSelected: isSelected,
      isToday: isToday,
      isOutside: isOutside,
      isFuture: isFuture,
      isPast: isPast,
      isDisabled: isDisabled,
      heroTag: 'calendar-day-summary-${day.year}-${day.month}-${day.day}',
      markers: markers.isNotEmpty
          ? [CalendarMarkerBadges(markers: markers, limit: 3)]
          : const [],
    );
  }
}
