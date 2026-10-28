// Settings slider tile for the Forge application.
//
// A settings row whose trailing value is edited with a [GlassSlider]. The
// live value label sits on the right and updates while dragging.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A settings row driven by a slider.
class SettingsSliderTile extends StatelessWidget {
  /// Creates a settings slider tile.
  const SettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.semanticLabel,
  });

  /// The row title.
  final String title;

  /// Optional supporting text.
  final String? subtitle;

  /// The formatted label of the current value.
  final String valueLabel;

  /// The current slider value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Optional number of discrete steps.
  final int? divisions;

  /// Invoked while dragging.
  final ValueChanged<double> onChanged;

  /// Optional semantic label for the slider.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              ),
              child: Text(
                valueLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        GlassSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          semanticLabel: semanticLabel ?? title,
        ),
      ],
    );
  }
}
