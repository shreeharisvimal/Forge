// Glass avatar for the Forge Design System.
//
// A circular or rounded glass avatar showing initials or an icon on a
// brand gradient.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A glass avatar.
class GlassAvatar extends StatelessWidget {
  /// Creates a glass avatar.
  const GlassAvatar({
    super.key,
    this.label,
    this.icon,
    this.background,
    this.size = AppSpacing.giant,
    this.borderRadius,
    this.onTap,
    this.semanticLabel,
    this.haptic = HapticType.selection,
  });

  /// Text used to derive initials (e.g. a person's name).
  final String? label;

  /// Optional icon shown instead of initials.
  final IconData? icon;

  /// Optional gradient override.
  final List<Color>? background;

  /// Diameter of the avatar.
  final double size;

  /// Corner radius; when `null` the avatar is a circle.
  final BorderRadiusGeometry? borderRadius;

  /// Invoked when the avatar is tapped.
  final VoidCallback? onTap;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Haptic fired on tap.
  final HapticType haptic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    final Widget content;
    if (icon != null) {
      content = Icon(
        icon,
        size: size * 0.5,
        color: colors.onPrimary,
      );
    } else {
      final initials = _initials(label ?? '?');
      content = Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      );
    }

    Widget avatar = GlassContainer(
      decoration: GlassDecoration(
        gradient: GlassGradient(
          colors: background ?? AppGradients.primaryToSecondary,
        ),
        borderRadius: radius,
        border: const GlassBorder(color: ForgeColors.border, width: AppBorderWidth.thin),
      ),
      borderRadius: radius,
      width: size,
      height: size,
      child: Center(child: content),
    );

    if (onTap != null) {
      avatar = GlassPressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? label,
        haptic: haptic,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }
    return avatar;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1 ? parts.last.characters.first.toUpperCase() : '';
    return '$first$second';
  }
}
