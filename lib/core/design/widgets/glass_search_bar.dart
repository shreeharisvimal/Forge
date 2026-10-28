// Glass search bar for the Forge Design System.
//
// A frosted-glass search input with a search icon, hint, optional clear
// affordance and the same focus ring as [GlassTextField].
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/curve_tokens.dart';
import '../tokens/duration_tokens.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/shadow_presets.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';

/// A glass search input.
class GlassSearchBar extends StatefulWidget {
  /// Creates a glass search bar.
  const GlassSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.showClear = true,
  });

  /// The search controller.
  final TextEditingController? controller;

  /// Placeholder hint.
  final String hintText;

  /// Invoked as the query changes.
  final ValueChanged<String>? onChanged;

  /// Invoked on submit.
  final ValueChanged<String>? onSubmitted;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// Whether the bar is interactive.
  final bool enabled;

  /// Whether to show the clear button when text is present.
  final bool showClear;

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  late final TextEditingController _controller;
  FocusNode? _focusNode;
  bool _hasText = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.controller == null) {
      _controller.addListener(_onTextChanged);
    }
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
    }
    _focusNode?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Future<void> _clear() async {
    await HapticHelper.selection();
    _controller.clear();
    widget.onChanged?.call('');
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.input);
    final ringColor = _focused ? colors.primary : colors.border;
    final ringWidth = _focused ? AppBorderWidth.thick : AppBorderWidth.thin;

    return Focus(
      onFocusChange: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: AppDuration.fast,
                curve: AppCurves.standard,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: ringColor, width: ringWidth),
                  boxShadow: _focused
                      ? AppShadows.focus(colors.primary)
                      : const <BoxShadow>[],
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
            height: AppSpacing.giant + AppSpacing.sm,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: AppIconSize.small,
                  color: _focused ? colors.primary : colors.onSurfaceMuted,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    enabled: widget.enabled,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    cursorColor: colors.primary,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(1),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: colors.onSurfaceTertiary),
                    ),
                  ),
                ),
                if (widget.showClear && _hasText)
                  InkWell(
                    onTap: _clear,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.close_rounded,
                        size: AppIconSize.small,
                        color: colors.onSurfaceMuted.withValues(
                          alpha: AppOpacity.disabled,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
