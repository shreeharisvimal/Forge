// Shared styling and options for the workout split feature.
//
// Provides the accent-color palette and icon options used by split cards and
// the split editor, plus helpers to reconstruct [IconData] from the
// codepoints persisted on [WorkoutSplit].
library;

import 'package:flutter/material.dart';

/// Accent color options for a split.
const List<Color> kSplitColors = [
  Color(0xFF7C4DFF), // primary violet
  Color(0xFF00E5FF), // secondary cyan
  Color(0xFF69F0AE), // mint
  Color(0xFFFFB300), // amber
  Color(0xFFFF5252), // red
  Color(0xFFFF8A65), // orange
  Color(0xFF40C4FF), // light blue
  Color(0xFFB388FF), // light purple
  Color(0xFFF06292), // pink
];

/// Material icons offered for a split.
const List<IconData> kSplitIcons = [
  Icons.fitness_center,
  Icons.directions_run,
  Icons.accessibility_new,
  Icons.self_improvement,
  Icons.flag,
  Icons.star,
  Icons.local_fire_department,
  Icons.sports_gymnastics,
];

/// Default accent for new splits.
Color kSplitColorFallback() => kSplitColors.first;

/// Resolves a persisted codepoint into displayable [IconData].
///
/// Returns the matching const instance from [kSplitIcons] (or a const
/// fallback) so the icon font tree-shaker can see every referenced glyph
/// and stale codepoints from old data degrade gracefully.
IconData splitIcon(int codePoint) {
  for (final icon in kSplitIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.fitness_center;
}

/// Formats a rest value in seconds for compact display.
String formatRestSeconds(int seconds) {
  if (seconds <= 0) return '—';
  if (seconds % 60 == 0) return '${seconds ~/ 60}m';
  if (seconds < 60) return '${seconds}s';
  return '${seconds ~/ 60}m${seconds % 60}';
}
