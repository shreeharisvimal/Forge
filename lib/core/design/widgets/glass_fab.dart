// Glass FAB for the Forge Design System.
//
// A floating glass action button with an optional extended label, ambient
// glow and press animation.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../glass/glass_shadow.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A floating glass action button.
class GlassFAB extends StatelessWidget {
  /// Creates a glass FAB.
  const GlassFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.mini = false,
    this.semanticLabel,
    this.tooltip,
    this.haptic = HapticType.medium,
    this.entrance = GlassEntrance.none,
    this.duration,
  });

  /// The FAB icon.
  final IconData icon;

  /// Invoked when pressed.
  final VoidCallback? onPressed;

  /// Optional extended label.
  final String? label;

  /// Whether to render the compact circular form.
  final bool mini;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Optional tooltip.
  final String? tooltip;

  /// Haptic fired on press.
  final HapticType haptic;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  /// Entrance animation duration.
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.fab);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSize.medium, color: colors.onPrimary),
        if (label != null && !mini) ...[
          SizedBox(width: AppSpacing.sm),
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );

    final padding = mini
        ? EdgeInsets.all(AppSpacing.lg)
        : EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg);

    Widget fab = GlassContainer(
      decoration: GlassDecoration(
        gradient: GlassGradient(colors: AppGradients.primary),
        borderRadius: radius,
        border: const GlassBorder(width: AppBorderWidth.none),
        shadows: [
          for (final s in AppShadows.glowPrimary)
            GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
          GlassShadow(color: const Color(0x1F000000), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      borderRadius: radius,
      child: GlassPressable(
        onTap: onPressed,
        semanticLabel: semanticLabel ?? label,
        tooltip: tooltip,
        haptic: haptic,
        borderRadius: radius,
        child: Padding(padding: padding, child: content),
      ),
    );

    if (entrance != GlassEntrance.none) {
      fab = GlassAnimated(entrance: entrance, duration: duration, child: fab);
    }
    return fab;
  }
}
