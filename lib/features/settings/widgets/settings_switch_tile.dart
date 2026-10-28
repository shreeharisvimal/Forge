// Settings switch tile for the Forge application.
//
// A settings row pairing a title (with optional subtitle) and a [GlassSwitch]
// trailing control.
library;

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';

/// A settings row with a trailing switch.
class SettingsSwitchTile extends StatelessWidget {
  /// Creates a settings switch tile.
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The row title.
  final String title;

  /// Optional supporting text.
  final String? subtitle;

  /// The current switch value.
  final bool value;

  /// Invoked with the new value when toggled.
  final ValueChanged<bool> onChanged;

  /// Whether the switch is interactive.
  final bool enabled;

  /// Optional semantic label for the switch.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GlassListTile(
      title: title,
      subtitle: subtitle,
      trailing: GlassSwitch(
        value: value,
        onChanged: onChanged,
        enabled: enabled,
        semanticLabel: semanticLabel ?? title,
      ),
    );
  }
}
