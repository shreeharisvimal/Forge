// Glass navigation bar for the Forge Design System.
//
// A floating, blurred, rounded glass pill hosting the primary navigation
// destinations. Designed to sit at the bottom of the screen inside the app
// shell.
library;

import 'package:flutter/material.dart';

import '../animations/glass_animated.dart';
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
import 'glass_navigation_item.dart';
/// A destination for [GlassNavigationBar].
class GlassNavigationDestination {
  /// Creates a navigation destination.
  const GlassNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });

  /// The destination label.
  final String label;

  /// The unselected icon.
  final IconData icon;

  /// The selected icon.
  final IconData selectedIcon;

  /// Optional badge value.
  final Object? badge;
}

/// A floating glass bottom navigation bar.
class GlassNavigationBar extends StatelessWidget {
  /// Creates a glass navigation bar.
  const GlassNavigationBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.showLabels = true,
    this.entrance = GlassEntrance.none,
  });

  /// The ordered destinations.
  final List<GlassNavigationDestination> destinations;

  /// The currently selected index.
  final int currentIndex;

  /// Invoked when a destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Whether to render labels under the icons.
  final bool showLabels;

  /// Optional entrance animation.
  final GlassEntrance entrance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;

    Widget bar = GlassContainer(
      decoration: GlassDecoration(
        color: colors.glassStrong,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: GlassBorder(color: colors.border),
        blur: const GlassBlur(AppBlur.medium),
        shadows: [
          for (final s in AppShadows.floating)
            GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
        ],
        highlight: true,
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      padding: EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: GlassNavigationItem(
                label: destinations[i].label,
                icon: destinations[i].icon,
                selectedIcon: destinations[i].selectedIcon,
                selected: i == currentIndex,
                badge: destinations[i].badge,
                showLabel: showLabels,
                onTap: () => onDestinationSelected(i),
              ),
            ),
        ],
      ),
    );

    if (entrance != GlassEntrance.none) {
      bar = GlassAnimated(entrance: entrance, child: bar);
    }
    return bar;
  }
}
