// Glass navigation item for the Forge Design System.
//
// A single destination inside a [GlassNavigationBar] with an animated icon
// swap, label and optional badge.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_badge.dart';
import 'glass_pressable.dart';

/// One destination of the glass navigation bar.
class GlassNavigationItem extends StatelessWidget {
  /// Creates a navigation item.
  const GlassNavigationItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.showLabel = true,
    this.semanticLabel,
  });

  /// The unselected icon.
  final IconData icon;

  /// The selected icon.
  final IconData selectedIcon;

  /// The destination label.
  final String label;

  /// Whether this destination is selected.
  final bool selected;

  /// Invoked when the destination is tapped.
  final VoidCallback onTap;

  /// Optional badge value shown on the icon.
  final Object? badge;

  /// Whether to render the label below the icon.
  final bool showLabel;

  /// Optional semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    Widget icon = AnimatedSwitcher(
      duration: AppDuration.quick,
      switchInCurve: AppCurves.spring,
      switchOutCurve: AppCurves.standard,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.7, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Icon(
        selected ? selectedIcon : this.icon,
        key: ValueKey(selected),
        size: 24,
        color: selected ? colors.primary : colors.onSurfaceMuted,
      ),
    );

    if (badge != null) {
      icon = GlassBadge(
        value: badge,
        margin: const EdgeInsets.all(AppSpacing.xxs),
        child: icon,
      );
    }

    return GlassPressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      haptic: HapticType.selection,
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: AnimatedContainer(
        duration: AppDuration.quick,
        curve: AppCurves.standard,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: AppOpacity.glassLow)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          boxShadow: selected
              ? AppShadows.glow(colors.primary, intensity: 0.16)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (showLabel) ...[
              SizedBox(height: AppSpacing.xxs),
              AnimatedDefaultTextStyle(
                duration: AppDuration.quick,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: selected ? colors.primary : colors.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
