// Forge theme factory for the design system.
//
// Builds the Material 3 [ThemeData] used by the application with all Forge
// theme extensions, glass page transitions and base component themes
// registered. Themes resolve from a [ForgeAccentPalette] so accent
// switching and light mode flow through the same code path. This is the
// single place visual defaults are declared.
library;

import 'package:flutter/material.dart';

import '../animations/glass_page_transitions.dart';
import '../colors/forge_accent_palettes.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../typography/forge_typography.dart';
import 'animation_theme_extension.dart';
import 'color_theme_extension.dart';
import 'glass_theme_extension.dart';
import 'spacing_theme_extension.dart';
import 'typography_theme_extension.dart';

/// Central theme factory for the Forge Design System.
abstract final class ForgeTheme {
  ForgeTheme._();

  /// The default dark [ThemeData] for Forge.
  static ThemeData dark({
    ForgeAccentPalette palette = ForgeAccentPalettes.violet,
    bool amoled = true,
    bool dynamicColors = false,
  }) {
    final (primary, secondary) =
        _effectiveAccent(palette, light: false, dynamic: dynamicColors);
    final colors = ColorThemeExtension.darkAccent(
      palette: palette,
      primary: dynamicColors ? primary : null,
      secondary: dynamicColors ? secondary : null,
      amoled: amoled,
    );
    final glass = GlassThemeExtension.fallback().copyWith(glowColor: primary);
    return _build(
      brightness: Brightness.dark,
      colors: colors,
      glass: glass,
      primary: primary,
      secondary: secondary,
    );
  }

  /// The light [ThemeData] for Forge.
  static ThemeData light({
    ForgeAccentPalette palette = ForgeAccentPalettes.violet,
    bool dynamicColors = false,
  }) {
    final (primary, secondary) =
        _effectiveAccent(palette, light: true, dynamic: dynamicColors);
    final colors = ColorThemeExtension.lightAccent(
      palette: palette,
      primary: dynamicColors ? primary : null,
      secondary: dynamicColors ? secondary : null,
    );
    final glass = GlassThemeExtension.lightFallback().copyWith(glowColor: primary);
    return _build(
      brightness: Brightness.light,
      colors: colors,
      glass: glass,
      primary: primary,
      secondary: secondary,
    );
  }

  /// Resolves the [ThemeData] for the stored preferences.
  ///
  /// [themeMode] is 'system', 'light' or 'dark'; [systemBrightness] decides
  /// the effective mode for the 'system' value. The accent and AMOLED/dynamic
  /// options are applied through the shared dark/light builders.
  static ThemeData resolve({
    required String themeMode,
    required String accentKey,
    required bool amoled,
    required bool dynamicColors,
    required Brightness systemBrightness,
  }) {
    final palette = ForgeAccentPalettes.byKey(accentKey);
    final darkMode = switch (themeMode) {
      'dark' => true,
      'light' => false,
      _ => systemBrightness == Brightness.dark,
    };
    return darkMode
        ? dark(
            palette: palette,
            amoled: amoled,
            dynamicColors: dynamicColors,
          )
        : light(palette: palette, dynamicColors: dynamicColors);
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorThemeExtension colors,
    required GlassThemeExtension glass,
    required Color primary,
    required Color secondary,
  }) {
    final textTheme = ForgeTypography.textTheme(brightness: brightness);
    final dark = brightness == Brightness.dark;
    final surface = colors.surface;
    final surfaceHigh = colors.surfaceHigh;
    final raised = colors.backgroundRaised;
    final onSurfaceVariant = colors.onSurfaceMuted;

    final scheme = dark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: colors.onPrimary,
            secondary: secondary,
            onSecondary: colors.onSecondary,
            error: colors.danger,
            onError: const Color(0xFFFFFFFF),
            surface: colors.background,
            onSurface: colors.onSurface,
            surfaceTint: Colors.transparent,
            surfaceContainerLowest: colors.background,
            surfaceContainerLow: raised,
            surfaceContainer: surface,
            surfaceContainerHigh: surfaceHigh,
            surfaceContainerHighest: surfaceHigh,
            onSurfaceVariant: onSurfaceVariant,
            outline: colors.outline,
            outlineVariant: colors.outline,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: colors.onPrimary,
            secondary: secondary,
            onSecondary: colors.onSecondary,
            error: colors.danger,
            onError: const Color(0xFFFFFFFF),
            surface: colors.background,
            onSurface: colors.onSurface,
            surfaceTint: Colors.transparent,
            surfaceContainerLowest: colors.background,
            surfaceContainerLow: raised,
            surfaceContainer: surface,
            surfaceContainerHigh: surfaceHigh,
            surfaceContainerHighest: surfaceHigh,
            onSurfaceVariant: onSurfaceVariant,
            outline: colors.outline,
            outlineVariant: colors.outline,
          );

    final borderRadius = BorderRadius.circular(AppRadius.medium);
    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: colors.background,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [
        glass,
        SpacingThemeExtension.fallback(),
        AnimationThemeExtension.fallback(),
        colors,
        TypographyThemeExtension(textTheme: textTheme),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: colors.border),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: colors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colors.onPrimary,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.borderStrong),
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.glassStrong,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.glassStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.glassStrong,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceHigh.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.glass,
        selectedColor: primary,
        disabledColor: colors.glass,
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(color: colors.onSurfaceTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary,
        selectionHandleColor: primary,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const GlassPageTransitionsBuilder(),
          TargetPlatform.iOS: const GlassPageTransitionsBuilder(),
          TargetPlatform.macOS: const GlassPageTransitionsBuilder(),
          TargetPlatform.windows: const GlassPageTransitionsBuilder(),
          TargetPlatform.linux: const GlassPageTransitionsBuilder(),
          TargetPlatform.fuchsia: const GlassPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// The effective brand pair for [palette], optionally derived dynamically
  /// from the accent seed when [dynamic] is enabled.
  static (Color, Color) _effectiveAccent(
    ForgeAccentPalette palette, {
    required bool light,
    required bool dynamic,
  }) {
    final basePrimary = light ? palette.lightPrimary : palette.primary;
    final baseSecondary = light ? palette.lightSecondary : palette.secondary;
    if (!dynamic) return (basePrimary, baseSecondary);
    final scheme = ColorScheme.fromSeed(
      seedColor: basePrimary,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return (scheme.primary, scheme.secondary);
  }
}
