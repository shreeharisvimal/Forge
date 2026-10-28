// Shared presentation helpers for the PR widgets.
//
// Icon lookup and value formatting that several PR widgets need. Pure
// presentation code — every visual decision stays in the widgets.
library;

import 'package:flutter/material.dart';

import '../../../../core/utils/dates.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../domain/pr_types.dart';

/// The [IconData] for a record type.
IconData prTypeIcon(PrType type) => switch (type) {
      PrType.heaviestWeight => Icons.scale_rounded,
      PrType.mostReps => Icons.format_list_numbered_rounded,
      PrType.estimatedOneRM => Icons.bolt_rounded,
      PrType.bestVolume => Icons.layers_rounded,
      PrType.longestHold => Icons.schedule_rounded,
      PrType.bestTime => Icons.timer_rounded,
    };

/// Formats a record [value] of [type] in the user's [unit].
String prValueLabel(PrType type, double value, SessionWeightUnit unit) =>
    switch (type) {
      PrType.heaviestWeight => SessionFormatters.weight(value, unit),
      PrType.mostReps => value.round().toString(),
      PrType.estimatedOneRM => SessionFormatters.weight(value, unit),
      PrType.bestVolume => SessionFormatters.volume(value, unit),
      PrType.longestHold => '${value.toStringAsFixed(1)}s',
      PrType.bestTime => '${value.toStringAsFixed(1)}s',
    };

/// A short human label for how a record was broken.
String prScopeLabel(PrScope scope) => switch (scope) {
      PrScope.firstEver => 'First ever',
      PrScope.session => 'Session best',
      PrScope.lifetime => 'New lifetime best',
    };

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A compact relative date: "Today", "Yesterday", "5d ago" or "Feb 4".
String prRelativeDate(DateTime date, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final day = dateOnly(date);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  return '${_months[day.month - 1]} ${day.day}';
}
