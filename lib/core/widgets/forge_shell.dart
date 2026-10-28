// ForgeShell — the persistent application shell.
//
// Replaces the Material navigation bar with a floating glass pill hosted
// over an ambient animated background. Owns the routing state through
// GoRouter's [StatefulNavigationShell] so each tab keeps its own stack.
// Shell-level chrome (overlays, dialogs) is composed above this widget.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/animations/glass_animated.dart';
import '../design/tokens/duration_tokens.dart';
import '../design/tokens/spacing_tokens.dart';
import '../design/utilities/responsive_helper.dart';
import '../design/widgets/glass_navigation_bar.dart';
import '../design/widgets/glass_navigation_rail.dart';
import '../router/app_route_paths.dart';
import 'forge_background.dart';

/// One top-level destination of the Forge shell.
class _ForgeDestination {
  const _ForgeDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// The tab's route path.
  final String path;

  /// The destination label.
  final String label;

  /// The unselected icon.
  final IconData icon;

  /// The selected icon.
  final IconData selectedIcon;
}

/// The persistent floating-glass application shell.
class ForgeShell extends StatelessWidget {
  /// Creates the application shell.
  const ForgeShell({super.key, required this.navigationShell});

  /// GoRouter's navigation shell controlling the active branch.
  final StatefulNavigationShell navigationShell;

  /// Ordered top-level destinations shown in the navigation bar/rail.
  static const List<_ForgeDestination> _destinations = [
    _ForgeDestination(
      path: AppRoutePaths.dashboard,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _ForgeDestination(
      path: AppRoutePaths.calendar,
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    _ForgeDestination(
      path: AppRoutePaths.workouts,
      label: 'Workouts',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
    ),
    _ForgeDestination(
      path: AppRoutePaths.body,
      label: 'Body',
      icon: Icons.straighten_rounded,
      selectedIcon: Icons.straighten_rounded,
    ),
    _ForgeDestination(
      path: AppRoutePaths.progress,
      label: 'Progress',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    _ForgeDestination(
      path: AppRoutePaths.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final showRail = Responsive.shouldShowNavRail(context);
    final navDestinations = [
      for (final destination in _destinations)
        GlassNavigationDestination(
          label: destination.label,
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
        ),
    ];

    void onDestinationSelected(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    if (showRail) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: ForgeBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: GlassNavigationRail(
                        destinations: navDestinations,
                        currentIndex: navigationShell.currentIndex,
                        onDestinationSelected: onDestinationSelected,
                        leading: Container(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                'Forge',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.maxContentWidth,
                          ),
                          child: navigationShell,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bottomSystem = MediaQuery.paddingOf(context).bottom;
    final contentInset =
        bottomSystem + AppSpacing.giant + AppSpacing.lg + AppSpacing.md;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: ForgeBackground()),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: contentInset),
              // Content stays centered and width-constrained so tablet and
              // desktop layouts remain readable instead of stretching.
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: navigationShell,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth - AppSpacing.xxl * 2,
                ),
                child: GlassAnimated.slide(
                  duration: AppDuration.medium,
                  child: GlassNavigationBar(
                    destinations: navDestinations,
                    currentIndex: navigationShell.currentIndex,
                    onDestinationSelected: onDestinationSelected,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

