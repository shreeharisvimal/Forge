// Settings section for the Forge application.
//
// A glass card that groups a heading (icon, title, optional subtitle) with
// the setting rows beneath it. Every Settings-tab section renders through
// this widget so the header and rhythm stay consistent.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A titled group of settings rows.
class SettingsSection extends StatelessWidget {
  /// Creates a settings section.
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  /// The section accent icon.
  final IconData icon;

  /// The section title.
  final String title;

  /// Optional supporting text under the title.
  final String? subtitle;

  /// The setting rows rendered under the header.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.lg.all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.huge,
                height: AppSpacing.huge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: colors.primaryGradient),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.medium,
                  color: colors.onPrimary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          GlassDivider(),
          SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
