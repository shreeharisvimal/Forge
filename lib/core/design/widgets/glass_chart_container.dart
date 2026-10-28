// Glass chart container for the Forge Design System.
//
// A titled glass card that hosts any chart widget with optional actions
// and a fixed height, giving charts a consistent frame.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_card.dart';

/// A glass frame around chart content.
class GlassChartContainer extends StatelessWidget {
  /// Creates a chart container.
  const GlassChartContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.height,
    this.padding,
  });

  /// The chart content.
  final Widget child;

  /// Optional title above the chart.
  final String? title;

  /// Optional subtitle below the title.
  final String? subtitle;

  /// Optional trailing widget (e.g. a menu button).
  final Widget? trailing;

  /// Optional fixed height for the chart area.
  final double? height;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: padding ?? AppSpacing.lg.all,
      decoration: GlassDecoration(
        color: colors.glass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: const GlassBorder(color: ForgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || trailing != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (subtitle != null) ...[
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: AppSpacing.lg),
          ],
          SizedBox(
            height: height,
            width: double.infinity,
            child: child,
          ),
        ],
      ),
    );
  }
}
