// Responsive helper for the Forge Design System.
//
// Maps the ambient screen size to a small set of breakpoints so layouts
// adapt from phones through foldables and tablets up to desktop widths.
library;

import 'package:flutter/material.dart';

/// The responsive breakpoints understood by Forge.
enum ForgeBreakpoint {
  /// Phones and compact layouts (< 600 dp).
  compact,

  /// Foldables and small tablets (600–840 dp).
  medium,

  /// Large tablets and desktop (> 840 dp).
  expanded,
}

/// Helpers for responsive layout decisions.
abstract final class Responsive {
  Responsive._();

  /// Upper bound of the compact (phone) breakpoint.
  static const double compactMaxWidth = 600;

  /// Upper bound of the medium (tablet) breakpoint.
  static const double mediumMaxWidth = 840;

  /// Width threshold at or above which a side navigation rail is shown (900 dp).
  static const double navRailBreakpoint = 900;

  /// The breakpoint matching [context].
  static ForgeBreakpoint breakpointOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactMaxWidth) return ForgeBreakpoint.compact;
    if (width < mediumMaxWidth) return ForgeBreakpoint.medium;
    return ForgeBreakpoint.expanded;
  }

  /// Whether [context] is a phone-sized layout.
  static bool isCompact(BuildContext context) =>
      breakpointOf(context) == ForgeBreakpoint.compact;

  /// Whether [context] is a tablet-sized layout.
  static bool isMedium(BuildContext context) =>
      breakpointOf(context) == ForgeBreakpoint.medium;

  /// Whether [context] is a desktop-sized layout.
  static bool isExpanded(BuildContext context) =>
      breakpointOf(context) == ForgeBreakpoint.expanded;

  /// Whether [context] width is at or above the navigation rail threshold (>= 900 dp).
  static bool shouldShowNavRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= navRailBreakpoint;

  /// Alias for [shouldShowNavRail].
  static bool isNavRail(BuildContext context) => shouldShowNavRail(context);

  /// A spacing multiplier that scales up on larger screens.
  ///
  /// Returns [compact] on phones, [medium] on tablets and [expanded] on
  /// desktop so larger screens breathe more.
  static double spacingScale(
    BuildContext context, {
    double compact = 1,
    double medium = 1.25,
    double expanded = 1.5,
  }) {
    return switch (breakpointOf(context)) {
      ForgeBreakpoint.compact => compact,
      ForgeBreakpoint.medium => medium,
      ForgeBreakpoint.expanded => expanded,
    };
  }

  /// Number of content columns for the ambient width.
  static int columns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    return switch (breakpointOf(context)) {
      ForgeBreakpoint.compact => compact,
      ForgeBreakpoint.medium => medium,
      ForgeBreakpoint.expanded => expanded,
    };
  }
}

