// Glass bottom sheet for the Forge Design System.
//
// A frosted-glass bottom sheet with a drag handle, optional scroll
// controller and snap positions. Replaces all default bottom sheets.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_blur.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_shadow.dart';
import '../tokens/blur_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';

/// The glass bottom sheet surface + presentation helper.
abstract final class GlassBottomSheet {
  GlassBottomSheet._();

  /// Presents a glass bottom sheet.
  ///
  /// When [snap] is true the sheet supports draggable snap positions using
  /// the [initialChildSize], [minChildSize] and [maxChildSize] fractions.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool showDragHandle = true,
    bool enableDrag = true,
    bool snap = false,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.95,
    Color? barrierColor,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sheet);

    final Widget sheet;
    if (snap) {
      sheet = DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        snap: true,
        expand: false,
        builder: (context, scrollController) {
          return _GlassSheetSurface(
            scrollController: scrollController,
            showDragHandle: showDragHandle,
            radius: radius,
            child: builder(context),
          );
        },
      );
    } else {
      sheet = _GlassSheetSurface(
        showDragHandle: showDragHandle,
        radius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * maxChildSize),
          child: builder(context),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? ForgeColors.scrim,
      builder: (context) => sheet,
    );
  }
}

/// The frosted surface of a glass bottom sheet.
class _GlassSheetSurface extends StatelessWidget {
  const _GlassSheetSurface({
    required this.showDragHandle,
    required this.radius,
    this.scrollController,
    required this.child,
  });

  final bool showDragHandle;
  final BorderRadius radius;
  final ScrollController? scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Container(
              width: AppSpacing.xxxl + AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: colors.onSurfaceMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
        ],
        Flexible(
          child: scrollController == null
              ? SingleChildScrollView(child: child)
              : SingleChildScrollView(controller: scrollController, child: child),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );

    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.glassStrong,
        borderRadius: radius,
        border: GlassBorder(color: colors.border),
        blur: const GlassBlur(AppBlur.strong),
        shadows: [
          for (final s in AppShadows.floating)
            GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
        ],
        highlight: true,
      ),
      borderRadius: radius,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: content,
    );
  }
}
