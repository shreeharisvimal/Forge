// Shared text formatting for the Forge dashboard.
//
// Small pure helpers used by the dashboard panels so date and number
// rendering stays consistent. No business logic lives here.
library;

import 'package:intl/intl.dart';

/// Formats a body weight with its unit, e.g. "82.4 kg".
String formatWeight(double value, String unit) =>
    '${value.toStringAsFixed(1)} $unit';

/// Formats a duration in minutes, e.g. "45 min".
String formatMinutes(int minutes) => '$minutes min';

/// Formats a date like "Mon, Feb 3".
String formatDay(DateTime date) => DateFormat('EEE, MMM d').format(date);

/// Formats a date like "February 3, 2026".
String formatFullDate(DateTime date) => DateFormat('MMMM d, y').format(date);

/// Human-friendly distance from [date] to [now].
///
/// Returns "Today", "Yesterday" or "N days ago".
String relativeDay(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference <= 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return '$difference days ago';
}
