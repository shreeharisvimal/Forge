// Glass PR badge for the Forge application.
//
// A compact pill that signals the outcome of a record comparison at a glance:
// a glowing "NEW PR" when a set beats the lifetime best, a muted "MATCHED"
// when it ties, and nothing when there is no PR. Used live on the active
// exercise card and inside the celebration dialog.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../domain/pr_types.dart';

/// A glass pill describing a [PrStatus].
class GlassPrBadge extends StatelessWidget {
  /// Creates a PR badge.
  const GlassPrBadge({super.key, required this.status, this.compact = false});

  /// The comparison outcome to describe.
  final PrStatus status;

  /// Smaller padding for inline placement.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final (label, color) = switch (status) {
      PrStatus.newPr => ('NEW PR', colors.success),
      PrStatus.tiedPr => ('MATCHED', colors.warning),
      PrStatus.noPr => (null, colors.onSurfaceMuted),
    };
    if (label == null) return const SizedBox.shrink();

    final radius = BorderRadius.circular(AppRadius.extraLarge);
    return GlassContainer(
      decoration: GlassDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: radius,
        border: GlassBorder(color: color.withValues(alpha: 0.5)),
        shadows: [
          GlassShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      borderRadius: radius,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}
