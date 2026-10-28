// Glass error state for the Forge Design System.
//
// A centered panel shown when content fails to load, with a message and a
// retry action.
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
import 'glass_button.dart';
import 'glass_container.dart';

/// A glass error-state panel.
class GlassErrorState extends StatelessWidget {
  /// Creates an error state.
  const GlassErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.entrance = GlassEntrance.scale,
  });

  /// Headline (defaults to a standard error title).
  final String? title;

  /// Error description.
  final String? message;

  /// Invoked when retry is pressed.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String? retryLabel;

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
                  gradient: GlassGradient(colors: AppGradients.danger),
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  border: const GlassBorder(color: ForgeColors.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: AppIconSize.doubleExtraLarge,
                    color: colors.onSurface,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              Text(
                title ?? 'Something went wrong',
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
              if (onRetry != null) ...[
                SizedBox(height: AppSpacing.xxl),
                GlassButton(
                  label: retryLabel ?? 'Try again',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  variant: GlassButtonVariant.outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
