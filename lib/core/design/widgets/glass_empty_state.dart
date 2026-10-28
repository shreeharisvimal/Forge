// Glass empty state for the Forge Design System.
//
// A centered illustration of an empty list or view with an icon, title,
// message and an optional action.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';

/// A glass empty-state panel.
class GlassEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.entrance = GlassEntrance.fade,
  });

  /// The hero icon.
  final IconData icon;

  /// The headline text.
  final String title;

  /// Optional supporting message.
  final String? message;

  /// Optional action rendered under the message.
  final Widget? action;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: GlassAnimated(
        entrance: entrance,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer(
                width: AppSpacing.huge * 2,
                height: AppSpacing.huge * 2,
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                decoration: GlassDecoration(
                  gradient: GlassGradient(
                    colors: AppGradients.primaryToSecondary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  border: const GlassBorder(color: ForgeColors.border),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AppIconSize.doubleExtraLarge,
                    color: colors.onPrimary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceMuted,
                    height: 1.4,
                  ),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: AppSpacing.xxl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
