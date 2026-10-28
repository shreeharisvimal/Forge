// Glass divider for the Forge Design System.
//
// A soft gradient divider line that fades out at both ends, optionally
// indented to align with content.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../tokens/border_width_tokens.dart';

/// A glass divider.
class GlassDivider extends StatelessWidget {
  /// Creates a glass divider.
  const GlassDivider({
    super.key,
    this.thickness = AppBorderWidth.hairline,
    this.color,
    this.indent,
    this.endIndent,
    this.vertical = false,
  });

  /// Line thickness.
  final double thickness;

  /// Color override.
  final Color? color;

  /// Leading inset.
  final double? indent;

  /// Trailing inset.
  final double? endIndent;

  /// Whether the divider runs vertically.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final baseColor = color ?? colors.border;

    if (vertical) {
      return Container(
        width: thickness,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              baseColor.withValues(alpha: 0),
              baseColor,
              baseColor.withValues(alpha: 0),
            ],
          ),
        ),
      );
    }

    return Container(
      height: thickness,
      margin: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor.withValues(alpha: 0),
            baseColor,
            baseColor.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
