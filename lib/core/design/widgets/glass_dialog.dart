// Glass dialog for the Forge Design System.
//
// A frosted-glass modal dialog with a spring entrance. Provides the
// primitive presentation plus a standard content layout; the app shell
// composes typed dialogs (confirm, delete, info, input, selection,
// progress) on top of these.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_blur.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_shadow.dart';
import '../tokens/blur_tokens.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_button.dart';
import 'glass_container.dart';

/// The glass dialog presentation helper.
abstract final class GlassDialog {
  GlassDialog._();

  /// Presents a glass dialog built by [builder].
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dialog',
      barrierColor: barrierColor ?? ForgeColors.scrim,
      transitionDuration: AppDuration.long,
      pageBuilder: (context, animation, secondaryAnimation) {
        // Dialogs sit on the root navigator with no Scaffold above them, so
        // a transparent Material is required for InkWell-based widgets
        // (buttons, pressables) inside the dialog to work.
        return Material(
          type: MaterialType.transparency,
          child: builder(context),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.spring,
          reverseCurve: AppCurves.standard,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppCurves.linear),
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Presents a standard glass dialog with title, message and actions.
  static Future<T?> showContent<T>(
    BuildContext context, {
    String? title,
    String? message,
    Widget? icon,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? accentColor,
  }) {
    return show<T>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (context) => GlassDialogContent(
        title: title,
        message: message,
        icon: icon,
        content: content,
        actions: actions,
        accentColor: accentColor,
      ),
    );
  }
}

/// The standard content layout of a glass dialog.
class GlassDialogContent extends StatelessWidget {
  /// Creates dialog content.
  const GlassDialogContent({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.content,
    this.actions,
    this.accentColor,
    this.padding,
  });

  /// Dialog headline.
  final String? title;

  /// Supporting message.
  final String? message;

  /// Leading icon in a tinted circle.
  final Widget? icon;

  /// Arbitrary body content (replaces [message]).
  final Widget? content;

  /// Action buttons rendered at the bottom.
  final List<Widget>? actions;

  /// Accent color used for the icon circle and primary action.
  final Color? accentColor;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.extraLarge);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassContainer(
          decoration: GlassDecoration(
            color: colors.glassStrong,
            borderRadius: radius,
            border: GlassBorder(color: colors.border),
            blur: const GlassBlur(AppBlur.heavy),
            shadows: [
              for (final s in AppShadows.modal)
                GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
            ],
            highlight: true,
          ),
          borderRadius: radius,
          padding: padding ?? EdgeInsets.all(AppSpacing.xxl),
          constraints: BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                GlassContainer(
                  width: AppSpacing.huge + AppSpacing.sm,
                  height: AppSpacing.huge + AppSpacing.sm,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  decoration: GlassDecoration(
                    color: (accentColor ?? colors.primary).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: GlassBorder(color: colors.border),
                  ),
                  child: Center(child: icon),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
              if (title != null)
                Text(
                  title!,
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
              if (content != null) ...[
                SizedBox(height: AppSpacing.lg),
                content!,
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final action in actions!) ...[
                      Flexible(child: action),
                      if (action != actions!.last) SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helpers for assembling dialog actions.
abstract final class DialogActions {
  DialogActions._();

  /// A primary confirm action.
  static Widget confirm({
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return GlassButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expanded: true,
    );
  }

  /// A neutral cancel action.
  static Widget cancel({
    required BuildContext context,
    String label = 'Cancel',
  }) {
    return GlassButton(
      label: label,
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      variant: GlassButtonVariant.ghost,
      expanded: true,
    );
  }
}
