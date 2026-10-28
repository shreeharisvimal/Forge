// Glass switch for the Forge Design System.
//
// A glass toggle with a spring-animated thumb and brand-tinted active
// state.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../glass/glass_shadow.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_pressable.dart';

/// A glass switch.
class GlassSwitch extends StatelessWidget {
  /// Creates a glass switch.
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The current value.
  final bool value;

  /// Invoked with the new value when toggled.
  final ValueChanged<bool> onChanged;

  /// Active track color override.
  final Color? activeColor;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Whether the switch is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final height = AppSpacing.xxxl;
    final width = height + AppSpacing.lg + AppSpacing.xs;
    final thumb = height - AppSpacing.sm;
    final activeColor = this.activeColor ?? colors.primary;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GlassPressable(
        onTap: enabled ? () => _toggle() : null,
        haptic: HapticType.selection,
        scale: 0.94,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        child: GlassContainer(
          decoration: GlassDecoration(
            color: value ? null : colors.glassStrong,
            gradient: value
                ? GlassGradient(colors: [activeColor, activeColor])
                : null,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            border: value
                ? const GlassBorder(width: AppBorderWidth.none)
                : GlassBorder(color: colors.borderStrong),
            shadows: value
                ? [
                    for (final s in AppShadows.glow(activeColor, intensity: 0.4))
                      GlassShadow(
                        color: s.color,
                        blurRadius: s.blurRadius,
                        offset: s.offset,
                      ),
                  ]
                : null,
          ),
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          width: width,
          height: height,
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: GlassGradient(colors: AppGradients.glass)
                        .toLinearGradient(),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle() async {
    await HapticHelper.selection();
    onChanged(!value);
  }
}
