// Progress section header for the Forge application.
//
// A plain header used above list-style Progress sections (exercises,
// achievements, PR timeline) that are not hosted in a chart container.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A titled Progress section header with optional subtitle.
class ProgressSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const ProgressSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  /// The headline text.
  final String title;

  /// Optional supporting line.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.md),
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
      ],
    );
  }
}
