// Glass segmented control for the Forge Design System.
//
// A glass pill control where the active segment is highlighted by an
// animated sliding indicator.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A glass segmented control.
class GlassSegmentedControl extends StatelessWidget {
  /// Creates a segmented control.
  const GlassSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.height,
    this.semanticLabels,
  });

  /// The segment labels.
  final List<String> options;

  /// The currently selected index.
  final int selectedIndex;

  /// Invoked when a segment is selected.
  final ValueChanged<int> onChanged;

  /// Track height.
  final double? height;

  /// Optional per-segment semantic labels.
  final List<String>? semanticLabels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final height = this.height ?? AppSpacing.giant + AppSpacing.xs;
    final radius = BorderRadius.circular(AppRadius.extraLarge);

    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glassStrong,
        borderRadius: radius,
        border: const GlassBorder(),
      ),
      borderRadius: radius,
      height: height,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / options.length;
          final indicatorWidth = segmentWidth - AppSpacing.xs;
          final left = selectedIndex * segmentWidth + AppSpacing.xxs;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDuration.short,
                curve: Curves.easeOutCubic,
                left: left,
                width: indicatorWidth,
                top: 0,
                bottom: 0,
                child: GlassContainer(
                  decoration: GlassDecoration(
                    gradient: GlassGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.85)]),
                    borderRadius: radius,
                    border: const GlassBorder(width: AppBorderWidth.none),
                  ),
                  borderRadius: radius,
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: GlassPressable(
                        onTap: () => onChanged(i),
                        haptic: HapticType.selection,
                        borderRadius: radius,
                        child: SizedBox(
                          height: double.infinity,
                          child: Center(
                            child: Text(
                              options[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: i == selectedIndex
                                        ? colors.onPrimary
                                        : colors.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
