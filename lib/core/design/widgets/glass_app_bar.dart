// Glass app bar for the Forge Design System.
//
// A blurred glass top bar with title, optional leading (back) button and
// actions. Safely insets above system areas.
library;

import 'package:flutter/material.dart';

import '../colors/forge_colors.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_blur.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/blur_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';
import 'glass_icon_button.dart';

/// A frosted-glass application bar.
class GlassAppBar extends StatelessWidget {
  /// Creates a glass app bar.
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.blur = true,
    this.bottom,
  });

  /// The bar title.
  final String? title;

  /// Leading widget override.
  final Widget? leading;

  /// Trailing actions.
  final List<Widget> actions;

  /// Whether to center the title.
  final bool centerTitle;

  /// Whether to insert a back button when the route can pop.
  final bool automaticallyImplyLeading;

  /// Whether the bar renders its backdrop blur.
  final bool blur;

  /// Optional widget rendered below the bar.
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;

    final Widget effectiveLeading = leading ??
        (automaticallyImplyLeading && canPop
            ? GlassIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back',
                haptic: HapticType.selection,
                onPressed: () => Navigator.maybePop(context),
              )
            : const SizedBox.shrink());

    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.background.withValues(alpha: 0.6),
        blur: GlassBlur(blur ? AppBlur.light : AppBlur.none),
        border: const GlassBorder(color: ForgeColors.border),
        borderRadius: BorderRadius.zero,
      ),
      borderRadius: BorderRadius.zero,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  effectiveLeading,
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: centerTitle
                                ? Alignment.center
                                : Alignment.centerLeft,
                            child: Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                  ),
                  if (actions.isNotEmpty) ...[
                    SizedBox(width: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final action in actions) ...[
                          action,
                          SizedBox(width: AppSpacing.xs),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
