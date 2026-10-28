// Color theme extension for the Forge Design System.
//
// Exposes the semantic brand palette through [ThemeData.extensions] so any
// widget can read `Theme.of(context).extension<ColorThemeExtension>()`.
// The palette is assembled from the base dark/light surfaces plus a
// selectable accent (see [ForgeAccentPalettes]), so accent switching and
// light mode resolve entirely through the theme.
library;

import 'package:flutter/material.dart';

import '../colors/forge_accent_palettes.dart';
import '../colors/forge_colors.dart';
import '../colors/forge_light_colors.dart';

/// Semantic color tokens available to every Forge widget.
class ColorThemeExtension extends ThemeExtension<ColorThemeExtension> {
  /// Creates a color theme extension.
  const ColorThemeExtension({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.background,
    required this.backgroundRaised,
    required this.surface,
    required this.surfaceHigh,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceTertiary,
    required this.onSurfaceDisabled,
    required this.outline,
    required this.hover,
    required this.pressed,
    required this.focusRing,
    required this.inputFill,
    required this.glass,
    required this.glassStrong,
    required this.border,
    required this.borderStrong,
    required this.glowViolet,
    required this.glowCyan,
    required this.glowVioletDeep,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.primaryToSecondary,
  });

  /// Builds the default dark-mode extension from [palette].
  ///
  /// [primary]/[secondary] override the palette values when dynamic color
  /// derivation is active; otherwise they are the palette's own colors.
  factory ColorThemeExtension.darkAccent({
    ForgeAccentPalette palette = ForgeAccentPalettes.violet,
    Color? primary,
    Color? secondary,
    bool amoled = true,
    Color? hover,
    Color? pressed,
    Color? focusRing,
    Color? inputFill,
  }) {
    final primaryColor = primary ?? palette.primary;
    final secondaryColor = secondary ?? palette.secondary;
    return ColorThemeExtension(
      primary: primaryColor,
      onPrimary: primaryColor == ForgeColors.primary
          ? ForgeColors.onPrimary
          : _contrastOn(primaryColor),
      secondary: secondaryColor,
      onSecondary: secondaryColor == ForgeColors.secondary
          ? ForgeColors.onSecondary
          : _contrastOn(secondaryColor),
      success: ForgeColors.success,
      warning: ForgeColors.warning,
      danger: ForgeColors.danger,
      info: ForgeColors.info,
      background: amoled ? ForgeColors.background : ForgeColors.backgroundRaised,
      backgroundRaised: ForgeColors.backgroundRaised,
      surface: ForgeColors.surface,
      surfaceHigh: ForgeColors.surfaceHigh,
      onSurface: ForgeColors.onSurface,
      onSurfaceMuted: ForgeColors.onSurfaceMuted,
      onSurfaceTertiary: ForgeColors.onSurfaceTertiary,
      onSurfaceDisabled: ForgeColors.onSurfaceDisabled,
      outline: ForgeColors.outline,
      hover: hover ?? ForgeColors.hover,
      pressed: pressed ?? ForgeColors.pressed,
      focusRing: focusRing ?? ForgeColors.focusRing,
      inputFill: inputFill ?? ForgeColors.inputFill,
      glass: ForgeColors.glass,
      glassStrong: ForgeColors.glassStrong,
      border: ForgeColors.border,
      borderStrong: ForgeColors.borderStrong,
      glowViolet: ForgeColors.glowViolet,
      glowCyan: ForgeColors.glowCyan,
      glowVioletDeep: ForgeColors.glowVioletDeep,
      primaryGradient: _ramp(
        primaryColor,
        exact: primary == null ? palette.primaryGradient : null,
      ),
      secondaryGradient: _ramp(
        secondaryColor,
        exact: secondary == null ? palette.secondaryGradient : null,
      ),
      primaryToSecondary: primary == null && secondary == null
          ? palette.primaryToSecondary
          : [primaryColor, secondaryColor],
    );
  }

  /// Builds the light-mode extension from [palette].
  factory ColorThemeExtension.lightAccent({
    ForgeAccentPalette palette = ForgeAccentPalettes.violet,
    Color? primary,
    Color? secondary,
    Color? hover,
    Color? pressed,
    Color? focusRing,
    Color? inputFill,
  }) {
    final primaryColor = primary ?? palette.lightPrimary;
    final secondaryColor = secondary ?? palette.lightSecondary;
    return ColorThemeExtension(
      primary: primaryColor,
      onPrimary: _contrastOn(primaryColor),
      secondary: secondaryColor,
      onSecondary: _contrastOn(secondaryColor),
      success: ForgeColors.success,
      warning: ForgeColors.warning,
      danger: ForgeColors.danger,
      info: ForgeColors.info,
      background: ForgeLightColors.background,
      backgroundRaised: ForgeLightColors.backgroundRaised,
      surface: ForgeLightColors.surface,
      surfaceHigh: ForgeLightColors.surfaceHigh,
      onSurface: ForgeLightColors.onSurface,
      onSurfaceMuted: ForgeLightColors.onSurfaceMuted,
      onSurfaceTertiary: ForgeLightColors.onSurfaceTertiary,
      onSurfaceDisabled: ForgeLightColors.onSurfaceDisabled,
      outline: ForgeLightColors.outline,
      hover: hover ?? ForgeLightColors.hover,
      pressed: pressed ?? ForgeLightColors.pressed,
      focusRing: focusRing ?? ForgeLightColors.focusRing,
      inputFill: inputFill ?? ForgeLightColors.inputFill,
      glass: ForgeLightColors.glass,
      glassStrong: ForgeLightColors.glassStrong,
      border: ForgeLightColors.border,
      borderStrong: ForgeLightColors.borderStrong,
      glowViolet: ForgeLightColors.glowViolet,
      glowCyan: ForgeLightColors.glowCyan,
      glowVioletDeep: ForgeLightColors.glowVioletDeep,
      primaryGradient: _ramp(
        primaryColor,
        exact: primary == null ? palette.lightPrimaryGradient : null,
      ),
      secondaryGradient: _ramp(secondaryColor, exact: null),
      primaryToSecondary: primary == null && secondary == null
          ? palette.lightPrimaryToSecondary
          : [primaryColor, secondaryColor],
    );
  }

  /// Creates the default fallback color extension from the palette.
  factory ColorThemeExtension.fallback() =>
      ColorThemeExtension.darkAccent();

  /// Brand indigo used for highlights and selected states.
  final Color primary;

  /// Content color on top of [primary].
  final Color onPrimary;

  /// Brand violet used for subtle accents.
  final Color secondary;

  /// Content color on top of [secondary].
  final Color onSecondary;

  /// Success feedback color.
  final Color success;

  /// Warning feedback color.
  final Color warning;

  /// Danger / destructive color.
  final Color danger;

  /// Informational color.
  final Color info;

  /// App background (AMOLED black, or raised black when AMOLED is off).
  final Color background;

  /// A barely-lifted tint of the background used to add depth.
  final Color backgroundRaised;

  /// Default surface color.
  final Color surface;

  /// Elevated surface color.
  final Color surfaceHigh;

  /// Primary text color.
  final Color onSurface;

  /// Muted text color.
  final Color onSurfaceMuted;

  /// Tertiary text color.
  final Color onSurfaceTertiary;

  /// Disabled text and icon color.
  final Color onSurfaceDisabled;

  /// Outline / divider color.
  final Color outline;

  /// Hover state fill over glass surfaces.
  final Color hover;

  /// Pressed state fill over glass surfaces.
  final Color pressed;

  /// Focus ring tint derived from the brand primary.
  final Color focusRing;

  /// Input field fill.
  final Color inputFill;

  /// Default glass fill (6% alpha).
  final Color glass;

  /// Strong glass fill (12% alpha).
  final Color glassStrong;

  /// Default glass border (15% alpha).
  final Color border;

  /// Strong glass border (18% alpha).
  final Color borderStrong;

  /// Ambient primary glow used in the shell background.
  final Color glowViolet;

  /// Ambient deep-indigo glow used in the shell background.
  final Color glowCyan;

  /// Deep glow that grounds the background's lower edge.
  final Color glowVioletDeep;

  /// Primary brand gradient ramp (matches [AppGradients.primary] for violet).
  final List<Color> primaryGradient;

  /// Secondary brand gradient ramp.
  final List<Color> secondaryGradient;

  /// Signature primary-to-secondary gradient.
  final List<Color> primaryToSecondary;

  @override
  ColorThemeExtension copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? background,
    Color? backgroundRaised,
    Color? surface,
    Color? surfaceHigh,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? onSurfaceTertiary,
    Color? onSurfaceDisabled,
    Color? outline,
    Color? hover,
    Color? pressed,
    Color? focusRing,
    Color? inputFill,
    Color? glass,
    Color? glassStrong,
    Color? border,
    Color? borderStrong,
    Color? glowViolet,
    Color? glowCyan,
    Color? glowVioletDeep,
    List<Color>? primaryGradient,
    List<Color>? secondaryGradient,
    List<Color>? primaryToSecondary,
  }) {
    return ColorThemeExtension(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      background: background ?? this.background,
      backgroundRaised: backgroundRaised ?? this.backgroundRaised,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceTertiary: onSurfaceTertiary ?? this.onSurfaceTertiary,
      onSurfaceDisabled: onSurfaceDisabled ?? this.onSurfaceDisabled,
      outline: outline ?? this.outline,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      focusRing: focusRing ?? this.focusRing,
      inputFill: inputFill ?? this.inputFill,
      glass: glass ?? this.glass,
      glassStrong: glassStrong ?? this.glassStrong,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      glowViolet: glowViolet ?? this.glowViolet,
      glowCyan: glowCyan ?? this.glowCyan,
      glowVioletDeep: glowVioletDeep ?? this.glowVioletDeep,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      primaryToSecondary: primaryToSecondary ?? this.primaryToSecondary,
    );
  }

  @override
  ColorThemeExtension lerp(ThemeExtension<ColorThemeExtension>? other, double t) {
    if (other is! ColorThemeExtension) return this;
    return ColorThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundRaised: Color.lerp(backgroundRaised, other.backgroundRaised, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceTertiary:
          Color.lerp(onSurfaceTertiary, other.onSurfaceTertiary, t)!,
      onSurfaceDisabled:
          Color.lerp(onSurfaceDisabled, other.onSurfaceDisabled, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      glowViolet: Color.lerp(glowViolet, other.glowViolet, t)!,
      glowCyan: Color.lerp(glowCyan, other.glowCyan, t)!,
      glowVioletDeep: Color.lerp(glowVioletDeep, other.glowVioletDeep, t)!,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      secondaryGradient: t < 0.5 ? secondaryGradient : other.secondaryGradient,
      primaryToSecondary:
          t < 0.5 ? primaryToSecondary : other.primaryToSecondary,
    );
  }

  static Color _contrastOn(Color color) {
    // WCAG-style luminance: pick white or black text for the accent.
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
    return luminance > 0.5 ? const Color(0xFF17171F) : const Color(0xFFFFFFFF);
  }

  static List<Color> _ramp(Color primary, {List<Color>? exact}) {
    if (exact != null && exact.isNotEmpty) return exact;
    return [primary, Color.lerp(primary, Colors.white, 0.32)!];
  }
}
