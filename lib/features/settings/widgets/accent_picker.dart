// Accent picker for the Forge application.
//
// A wrap of circular swatches, one per accent palette, with the selected
// accent highlighted by a ring and check mark. The palette itself drives the
// colors so the light/dark theme resolves through the same data.
library;

import 'package:flutter/material.dart';

import '../../../core/design/colors/forge_accent_palettes.dart';
import '../../../core/design/forge_design.dart';

/// Selects an accent palette from a row of swatches.
class AccentPicker extends StatelessWidget {
  /// Creates an accent picker.
  const AccentPicker({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  /// The currently selected accent key.
  final String selectedKey;

  /// Invoked with the new accent key when a swatch is tapped.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final palette in ForgeAccentPalettes.all)
          _AccentSwatch(
            palette: palette,
            selected: palette.key == selectedKey,
            labelColor: colors.onSurfaceMuted,
            labelStyle: textTheme.labelSmall,
            onTap: () => onChanged(palette.key),
          ),
      ],
    );
  }
}

/// One selectable accent swatch with its label.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.palette,
    required this.selected,
    required this.labelColor,
    required this.labelStyle,
    required this.onTap,
  });

  final ForgeAccentPalette palette;
  final bool selected;
  final Color labelColor;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;

    final swatch = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.primaryGradient,
        ),
        border: selected
            ? Border.all(color: palette.primary, width: 3)
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: AppIconSize.medium,
              color: Colors.white,
            )
          : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          selected: selected,
          label: palette.name,
          button: true,
          child: GlassPressable(
            onTap: onTap,
            semanticLabel: palette.name,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            scale: 0.9,
            child: swatch,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          palette.name,
          style: labelStyle?.copyWith(
            color: selected ? palette.primary : labelColor,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}
