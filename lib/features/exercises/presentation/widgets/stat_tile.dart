// Stat tile widget for the exercise detail screen.
//
// A small labeled card showing a headline value with a muted caption,
// e.g. "Sets 4", "Reps 6", "Rest 120s".
library;

import 'package:flutter/material.dart';

import '../../../../core/design/forge_design.dart';

/// A single labeled statistic card.
class StatTile extends StatelessWidget {
  /// Creates a stat tile.
  const StatTile({
    super.key,
    required this.label,
    required this.value,
  });

  /// Caption shown under the value.
  final String label;

  /// Headline value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ],
      ),
    );
  }
}
