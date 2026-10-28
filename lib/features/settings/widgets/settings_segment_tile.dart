// Settings segment tile for the Forge application.
//
// A settings row pairing a title with a [GlassSegmentedControl] beneath it,
// used for short enumerations like theme mode or unit system.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A settings row with a segmented control.
class SettingsSegmentTile extends StatelessWidget {
  /// Creates a settings segment tile.
  const SettingsSegmentTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.semanticLabels,
  });

  /// The row title.
  final String title;

  /// Optional supporting text.
  final String? subtitle;

  /// The segment labels.
  final List<String> options;

  /// The currently selected index.
  final int selectedIndex;

  /// Invoked when a segment is selected.
  final ValueChanged<int> onChanged;

  /// Optional per-segment semantic labels.
  final List<String>? semanticLabels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
        SizedBox(height: AppSpacing.md),
        GlassSegmentedControl(
          options: options,
          selectedIndex: selectedIndex,
          onChanged: onChanged,
          semanticLabels: semanticLabels,
        ),
      ],
    );
  }
}
