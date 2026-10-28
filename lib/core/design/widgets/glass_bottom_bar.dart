// Glass bottom bar compatibility export for the Forge Design System.
//
// Re-exports [GlassNavigationBar] under the alias [GlassBottomBar] to satisfy
// the rules.txt specification while maintaining 100% backward compatibility.
library;

import 'package:flutter/material.dart';

import 'glass_navigation_bar.dart';

/// Compatibility typedef mapping [GlassBottomBar] to [GlassNavigationBar].
typedef GlassBottomBar = GlassNavigationBar;

/// Extension or wrapper helpers if needed for [GlassBottomBar].
abstract final class GlassBottomBarUtils {
  GlassBottomBarUtils._();

  /// Utility builder for creating a standard bottom navigation bar instance.
  static GlassNavigationBar create({
    required List<GlassNavigationDestination> destinations,
    required int currentIndex,
    required ValueChanged<int> onDestinationSelected,
    bool showLabels = true,
  }) {
    return GlassNavigationBar(
      destinations: destinations,
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      showLabels: showLabels,
    );
  }
}
