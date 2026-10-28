// PrSoundService for the Forge application.
//
// Plays the short system cues that accompany PR moments. Forge ships no audio
// assets, so the service maps each [PrSound] onto the platform's built-in
// SystemSound — it works offline out of the box and is the single seam where a
// richer audio pipeline can land later without touching any caller.
library;

import 'package:flutter/services.dart';

/// The sounds the PR engine can play.
enum PrSound {
  /// Subtle confirmation that a set just beat a record (live badge).
  recordBroken,

  /// Richer cue for the post-workout celebration.
  celebration,
}

/// Plays PR sounds through the platform.
class PrSoundService {
  /// Plays [sound], ignoring platform errors so a cue never crashes a flow.
  Future<void> play(PrSound sound) async {
    final systemSound = switch (sound) {
      PrSound.recordBroken => SystemSoundType.click,
      PrSound.celebration => SystemSoundType.alert,
    };
    try {
      await SystemSound.play(systemSound);
    } on PlatformException {
      // The cue is decorative; silence on platforms without system sounds.
    }
  }

  /// Shortcut for the celebration cue.
  Future<void> celebrate() => play(PrSound.celebration);

  /// Shortcut for the live record-broken cue.
  Future<void> recordBroken() => play(PrSound.recordBroken);
}
