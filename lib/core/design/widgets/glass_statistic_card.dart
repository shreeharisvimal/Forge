// Glass statistic card for the Forge Design System.
//
// A compact data card showing an animated number, optional unit, trend
// delta and progress bar. Ideal for dashboard metrics.
library;

import 'package:flutter/material.dart';

import '../animations/animated_number.dart';
import '../extensions/theme_extensions.dart';
import '../colors/forge_colors.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../typography/forge_typography.dart';
import '../utilities/haptic_helper.dart';
import 'glass_card.dart';
import 'glass_progress_bar.dart';
import 'glass_pressable.dart';

/// A glass card for a single statistic.
class GlassStatisticCard extends StatelessWidget {
  /// Creates a statistic card.
  const GlassStatisticCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.delta,
    this.deltaLabel,
    this.icon,
    this.progress,
    this.onTap,
    this.decimals = 1,
    this.valueFormatter,
    this.semanticLabel,
  });

  /// The metric title.
  final String title;

  /// The metric value.
  final double value;

  /// Optional unit suffix (e.g. "kg").
  final String? unit;

  /// Optional trend delta (positive / negative).
  final double? delta;

  /// Optional label explaining the delta.
  final String? deltaLabel;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional 0..1 progress fill.
  final double? progress;

  /// Invoked when the card is tapped.
  final VoidCallback? onTap;

  /// Number of decimals for the value.
  final int decimals;

  /// Custom value formatter.
  final String Function(double value)? valueFormatter;

  /// Optional semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final hasDelta = delta != null;

    final deltaColor = (delta ?? 0) >= 0 ? colors.success : colors.danger;
    final deltaIcon = (delta ?? 0) >= 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
            if (icon != null)
              Icon(
                icon,
                size: AppIconSize.small,
                color: colors.primary,
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: GlassAnimatedNumber(
                value: value,
                decimals: decimals,
                formatter: valueFormatter,
                style: ForgeTypography.numberStyle(fontSize: 28, color: colors.onSurface),
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: AppSpacing.xs),
              Text(
                unit!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
        if (hasDelta) ...[
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(deltaIcon, size: AppIconSize.extraSmall, color: deltaColor),
              SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  deltaLabel ??
                      '${(delta ?? 0) >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (progress != null) ...[
          SizedBox(height: AppSpacing.md),
          GlassProgressBar(value: progress, height: 5),
        ],
      ],
    );

    Widget card = GlassCard(
      margin: EdgeInsets.zero,
      padding: AppSpacing.lg.all,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(color: ForgeColors.border),
      ),
      child: content,
    );

    if (onTap != null) {
      card = GlassPressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? title,
        haptic: HapticType.selection,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: card,
      );
    }
    return card;
  }
}
