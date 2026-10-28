// Glass text field for the Forge Design System.
//
// A frosted-glass text input with an animated floating label, prefix/suffix
// icons and inline error handling. The label lives inside the field as a
// placeholder and floats above it once focused or filled. Focus is signalled
// by a primary ring plus a soft ambient glow.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_container.dart';

/// A glass text input.
class GlassTextField extends StatefulWidget {
  /// Creates a glass text field.
  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.semanticLabel,
  });

  /// The text controller.
  final TextEditingController? controller;

  /// Label rendered inside the field (floats above when focused or filled).
  final String? label;

  /// Placeholder hint text shown once the label has floated.
  final String? hintText;

  /// Leading icon.
  final IconData? prefixIcon;

  /// Trailing widget.
  final Widget? suffixIcon;

  /// Error message; when set the field shows the danger ring.
  final String? errorText;

  /// Whether the input is obscured.
  final bool obscureText;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Invoked as the value changes.
  final ValueChanged<String>? onChanged;

  /// Invoked on submit.
  final ValueChanged<String>? onSubmitted;

  /// Invoked when the field is tapped.
  final VoidCallback? onTap;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// Maximum lines.
  final int maxLines;

  /// Soft keyboard text capitalization.
  final TextCapitalization textCapitalization;

  /// Optional input formatters applied to the text field.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional semantic label.
  final String? semanticLabel;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(GlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
      _hasText = widget.controller?.text.isNotEmpty ?? false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final hasError = widget.errorText != null;
    final radius = BorderRadius.circular(AppRadius.input);
    final textTheme = Theme.of(context).textTheme;

    // Single-line fields float the label; multiline fields keep it above.
    final showFloating = widget.label != null && widget.maxLines <= 1;
    final floated = showFloating && (_focused || _hasText);
    final placeholder = !showFloating
        ? widget.hintText
        : floated
            ? widget.hintText
            : widget.label;

    final ringColor = hasError
        ? colors.danger
        : _focused
            ? colors.primary
            : colors.border;
    final ringWidth = _focused || hasError
        ? AppBorderWidth.thick
        : AppBorderWidth.thin;
    final glow = _focused || hasError
        ? AppShadows.focus(hasError ? colors.danger : colors.primary)
        : const <BoxShadow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFloating)
          AnimatedSize(
            duration: AppDuration.quick,
            curve: AppCurves.standard,
            alignment: Alignment.topLeft,
            child: floated
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: AnimatedSwitcher(
                      duration: AppDuration.quick,
                      switchInCurve: AppCurves.decelerate,
                      switchOutCurve: AppCurves.accelerate,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.35),
                                  end: Offset.zero,
                                ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.label!,
                        key: ValueKey(widget.label),
                        style: textTheme.labelMedium?.copyWith(
                          color: hasError
                              ? colors.danger
                              : _focused
                                  ? colors.primary
                                  : colors.onSurfaceTertiary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  curve: AppCurves.standard,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: ringColor, width: ringWidth),
                    boxShadow: glow,
                  ),
                ),
              ),
            ),
            GlassContainer(
              decoration: GlassDecoration(
                color: widget.enabled ? colors.inputFill : colors.glassStrong,
                borderRadius: radius,
                border: GlassBorder(
                  color: Colors.transparent,
                  width: AppBorderWidth.none,
                ),
                highlight: false,
              ),
              borderRadius: radius,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: widget.maxLines > 1 ? AppSpacing.md : 0,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                maxLines: widget.maxLines,
                textCapitalization: widget.textCapitalization,
                inputFormatters: widget.inputFormatters,
                onChanged: (value) {
                  if (_hasText != value.isNotEmpty) {
                    setState(() => _hasText = value.isNotEmpty);
                  }
                  widget.onChanged?.call(value);
                },
                onSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                cursorColor: colors.primary,
                cursorWidth: 2,
                cursorRadius: const Radius.circular(1),
                cursorOpacityAnimates: true,
                style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: placeholder,
                  hintStyle: TextStyle(
                    color: colors.onSurfaceTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: widget.prefixIcon == null
                      ? null
                      : Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: _focused
                              ? colors.primary
                              : colors.onSurfaceMuted,
                        ),
                  suffixIcon: widget.suffixIcon,
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }
}
