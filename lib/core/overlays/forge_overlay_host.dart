// Forge overlay system — host widget.
//
// Renders the active overlay entries from [forgeOverlayControllerProvider]
// above the router content. Insert once in the `MaterialApp.builder` so it
// always sits on top of navigation. Entries are laid out by kind:
// transient feedback near the top, loading centered, progress pinned above
// the shell navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/colors/forge_colors.dart';
import '../design/extensions/theme_extensions.dart';
import '../design/glass/glass_blur.dart';
import '../design/glass/glass_border.dart';
import '../design/glass/glass_decoration.dart';
import '../design/tokens/blur_tokens.dart';
import '../design/tokens/icon_size_tokens.dart';
import '../design/tokens/opacity_tokens.dart';
import '../design/tokens/radius_tokens.dart';
import '../design/tokens/spacing_tokens.dart';
import '../design/widgets/glass_button.dart';
import '../design/widgets/glass_container.dart';
import '../design/widgets/glass_loading.dart';
import '../design/widgets/glass_progress_bar.dart';
import 'forge_overlay_controller.dart';

/// Overlay layer placed above the router.
class ForgeOverlayHost extends ConsumerWidget {
  /// Creates the overlay host.
  const ForgeOverlayHost({super.key, required this.child});

  /// The router content shown beneath the overlays.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(forgeOverlayControllerProvider);

    return Stack(
      children: [
        child,
        if (controller.isActive)
          Positioned.fill(
            // A transparent Material provides the ink surface required by
            // the glass pressables in the cards; the overlay layer sits
            // above the navigator so no Scaffold exists to provide one.
            child: Material(
              type: MaterialType.transparency,
              child: IgnorePointer(
                ignoring: true,
                child: Stack(
                  children: [
                    for (final entry in controller.entries)
                      _OverlayPlacement(
                        key: ValueKey(entry.id),
                        entry: entry,
                        controller: controller,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Positions a single overlay entry according to its kind.
class _OverlayPlacement extends StatelessWidget {
  const _OverlayPlacement({
    super.key,
    required this.entry,
    required this.controller,
  });

  final ForgeOverlayEntry entry;
  final ForgeOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return switch (entry.kind) {
      ForgeOverlayKind.loading => Align(
          alignment: Alignment.center,
          child: _OverlayCard(
            entry: entry,
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.xxl),
          ),
        ),
      ForgeOverlayKind.progress => Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: EdgeInsets.only(bottom: AppSpacing.giant + AppSpacing.xxl),
            child: _OverlayCard(
              entry: entry,
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.lg),
            ),
          ),
        ),
      ForgeOverlayKind.toast ||
      ForgeOverlayKind.success ||
      ForgeOverlayKind.error =>
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            minimum: EdgeInsets.only(top: AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _OverlayCard(
                entry: entry,
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
            ),
          ),
        ),
    };
  }
}

/// The frosted card rendering a single overlay entry.
class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.entry,
    required this.controller,
    required this.padding,
  });

  final ForgeOverlayEntry entry;
  final ForgeOverlayController controller;
  final EdgeInsets padding;

  Color get _accent {
    return switch (entry.kind) {
      ForgeOverlayKind.toast => ForgeColors.info,
      ForgeOverlayKind.success => ForgeColors.success,
      ForgeOverlayKind.error => ForgeColors.danger,
      ForgeOverlayKind.loading => ForgeColors.primary,
      ForgeOverlayKind.progress => ForgeColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final leading = switch (entry.kind) {
      ForgeOverlayKind.toast => Icons.info_outline_rounded,
      ForgeOverlayKind.success => Icons.check_circle_rounded,
      ForgeOverlayKind.error => Icons.error_rounded,
      ForgeOverlayKind.loading => null,
      ForgeOverlayKind.progress => null,
    };

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.kind == ForgeOverlayKind.loading) ...[
          const GlassLoading(),
          SizedBox(height: AppSpacing.md),
        ],
        if (leading != null) ...[
          Icon(leading, color: _accent, size: AppIconSize.medium),
          SizedBox(height: AppSpacing.sm),
        ],
        Text(
          entry.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (entry.message != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            entry.message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
          ),
        ],
        if (entry.kind == ForgeOverlayKind.progress) ...[
          SizedBox(height: AppSpacing.md),
          GlassProgressBar(
            value: entry.progress,
            height: AppSpacing.xs,
            color: colors.primary,
          ),
        ],
        if (entry.actionLabel != null) ...[
          SizedBox(height: AppSpacing.md),
          GlassButton(
            label: entry.actionLabel!,
            onPressed: () {
              controller.dismiss(entry.id);
              entry.action?.call();
            },
            variant: GlassButtonVariant.tonal,
            size: GlassButtonSize.small,
          ),
        ],
      ],
    );

    return GlassContainer(
      decoration: GlassDecoration(
        color: colors.surfaceHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: const GlassBorder(),
        blur: const GlassBlur(AppBlur.medium),
      ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      padding: padding,
      constraints: BoxConstraints(
        maxWidth: AppSpacing.maxContentWidth * 0.8,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: entry.kind == ForgeOverlayKind.loading ||
                entry.kind == ForgeOverlayKind.progress
            ? null
            : () => controller.dismiss(entry.id),
        child: Opacity(
          opacity: entry.kind == ForgeOverlayKind.loading ||
                  entry.kind == ForgeOverlayKind.progress
              ? AppOpacity.opaque
              : AppOpacity.highlight,
          child: content,
        ),
      ),
    );
  }
}
