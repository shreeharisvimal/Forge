// Glass navigation rail for the Forge Design System.
//
// A vertical glass navigation rail hosted on the side of tablet and desktop
// screens. Provides blurred glass aesthetics, animated selection indicators,
// optional badges, expandable/collapsible labels, and custom leading/trailing
// slots.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_blur.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_shadow.dart';
import '../tokens/blur_tokens.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_badge.dart';
import 'glass_container.dart';
import 'glass_navigation_bar.dart';

/// A vertical, floating glass side navigation rail for desktop and tablet layouts.
class GlassNavigationRail extends StatefulWidget {
  /// Creates a glass navigation rail.
  const GlassNavigationRail({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.extended = true,
    this.leading,
    this.trailing,
    this.onToggleExtended,
    this.entrance = GlassEntrance.none,
  });

  /// The ordered navigation destinations.
  final List<GlassNavigationDestination> destinations;

  /// The index of the currently selected destination.
  final int currentIndex;

  /// Invoked when a destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Whether the navigation rail is expanded to show labels.
  final bool extended;

  /// Optional leading widget displayed at the top of the rail (e.g. app logo).
  final Widget? leading;

  /// Optional trailing widget displayed at the bottom of the rail.
  final Widget? trailing;

  /// Optional callback invoked when the expand/collapse toggle is pressed.
  final ValueChanged<bool>? onToggleExtended;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  @override
  State<GlassNavigationRail> createState() => _GlassNavigationRailState();
}

class _GlassNavigationRailState extends State<GlassNavigationRail> {
  late bool _isExtended;

  @override
  void initState() {
    super.initState();
    _isExtended = widget.extended;
  }

  @override
  void didUpdateWidget(GlassNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extended != widget.extended) {
      _isExtended = widget.extended;
    }
  }

  void _toggleExtended() {
    setState(() {
      _isExtended = !_isExtended;
    });
    widget.onToggleExtended?.call(_isExtended);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final railWidth = _isExtended ? 220.0 : 76.0;

    Widget rail = AnimatedContainer(
      duration: AppDuration.medium,
      curve: Curves.easeOutCubic,
      width: railWidth,
      height: double.infinity,
      child: GlassContainer(
        decoration: GlassDecoration(
          color: colors.surface.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: const GlassBorder(),
          blur: const GlassBlur(AppBlur.medium),
          shadows: const [
            GlassShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(8, 0)),
            GlassShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(4, 0)),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              SizedBox(height: AppSpacing.lg),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: widget.destinations.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final destination = widget.destinations[index];
                  final isSelected = index == widget.currentIndex;
                  return _RailItem(
                    destination: destination,
                    isSelected: isSelected,
                    extended: _isExtended,
                    onTap: () => widget.onDestinationSelected(index),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            IconButton(
              onPressed: _toggleExtended,
              tooltip: _isExtended ? 'Collapse rail' : 'Expand rail',
              icon: Icon(
                _isExtended
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.onSurfaceMuted,
              ),
            ),
            if (widget.trailing != null) ...[
              SizedBox(height: AppSpacing.xs),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    if (widget.entrance != GlassEntrance.none) {
      rail = GlassAnimated(entrance: widget.entrance, child: rail);
    }
    return rail;
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  final GlassNavigationDestination destination;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final textTheme = Theme.of(context).textTheme;

    final activeColor = colors.primary;
    final inactiveColor = colors.onSurfaceMuted;

    return Semantics(
      selected: isSelected,
      label: destination.label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: AnimatedContainer(
          duration: AppDuration.short,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: extended ? AppSpacing.md : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: AppBorderWidth.thin,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: AppIconSize.medium,
                  ),
                  if (destination.badge != null)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: destination.badge is Widget
                          ? (destination.badge as Widget)
                          : GlassBadge(
                              value: destination.badge,
                              color: isSelected ? colors.primary : colors.surface,
                            ),

                    ),
                ],
              ),
              if (extended) ...[
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppDuration.short,
                    style: (textTheme.labelLarge ?? const TextStyle()).copyWith(
                      color: isSelected ? activeColor : colors.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
