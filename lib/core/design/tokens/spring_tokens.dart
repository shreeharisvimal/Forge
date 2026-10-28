// Spring physics tokens for the Forge Design System.
//
// Premium motion uses physical springs instead of linear tweens. Every
// press, release, sheet and selection animation must come from this scale.
library;

import 'package:flutter/physics.dart';

/// The shared spring scale for Forge.
abstract final class AppSpring {
  AppSpring._();

  /// Press-down: quick and firm so taps feel immediate.
  static const SpringDescription press = SpringDescription(
    mass: 1,
    stiffness: 900,
    damping: 30,
  );

  /// Release: a lively bounce back to rest.
  static const SpringDescription release = SpringDescription(
    mass: 1,
    stiffness: 480,
    damping: 17,
  );

  /// Entrance for sheets, dialogs and hero surfaces.
  static const SpringDescription entrance = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 24,
  );

  /// Selection for switches, chips and nav indicators.
  static const SpringDescription toggle = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 19,
  );
}
