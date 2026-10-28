// Pressable behavior for the Forge Design System.
//
// Shared interaction wrapper used by every tappable glass widget. It
// provides the springy press-scale animation, haptic feedback, focus
// traversal and semantics in one place so behavior never duplicates.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../animations/animation_config.dart';
import '../extensions/theme_extensions.dart';
import '../tokens/spring_tokens.dart';
import '../utilities/haptic_helper.dart';

/// The interaction wrapper behind tappable Forge widgets.
class GlassPressable extends StatefulWidget {
  /// Creates a pressable wrapper.
  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.semanticLabel,
    this.enabled = true,
    this.haptic = HapticType.selection,
    this.scale = 0.96,
    this.borderRadius,
    this.tooltip,
  });

  /// The child rendered inside the pressable surface.
  final Widget child;

  /// Invoked when the surface is tapped.
  final VoidCallback? onTap;

  /// Invoked when the surface is long-pressed.
  final VoidCallback? onLongPress;

  /// Invoked when a pointer presses down on the surface.
  final VoidCallback? onTapDown;

  /// Invoked when a pointer releases over the surface.
  final VoidCallback? onTapUp;

  /// Invoked when a pointer leaves or the tap is cancelled.
  final VoidCallback? onTapCancel;

  /// Optional semantic label for screen readers.
  final String? semanticLabel;

  /// Whether the surface is interactive.
  final bool enabled;

  /// Haptic fired on tap.
  final HapticType haptic;

  /// Scale applied while pressed.
  final double scale;

  /// Corner radius used for the focus highlight.
  final BorderRadius? borderRadius;

  /// Optional tooltip message.
  final String? tooltip;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _pressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    if (AnimationConfig.isDisabled) {
      _controller.value = target;
      return;
    }
    if (_controller.isAnimating) _controller.stop();
    _controller.fling(
      velocity: target >= 1 ? 1.6 : -1.6,
      springDescription: AppSpring.press,
    );
  }

  void _handleDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    widget.onTapDown?.call();
    _springTo(1);
  }

  void _handleUp(PointerUpEvent event) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onTapUp?.call();
    _springTo(0);
  }

  void _handleCancel(PointerCancelEvent event) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onTapCancel?.call();
    _springTo(0);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    // Haptics are best-effort and must never gate the action: fire without
    // awaiting so taps stay instant even if the platform channel is slow
    // or unavailable (e.g. under widget tests).
    unawaited(HapticHelper.fire(widget.haptic));
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    Widget surface = Semantics(
      button: widget.onTap != null,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: InkWell(
        onTap: widget.onTap == null && !widget.enabled ? null : _handleTap,
        onLongPress: widget.onLongPress,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: widget.enabled ? colors.hover : Colors.transparent,
        focusColor: widget.enabled ? colors.focusRing : Colors.transparent,
        child: widget.child,
      ),
    );

    if (widget.tooltip != null) {
      surface = Tooltip(message: widget.tooltip!, child: surface);
    }

    return FocusTraversalGroup(
      child: Listener(
        onPointerDown: _handleDown,
        onPointerUp: _handleUp,
        onPointerCancel: _handleCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale =
                1.0 - (1.0 - widget.scale) * _controller.value.clamp(0, 1.6);
            return Transform.scale(scale: scale, child: child);
          },
          child: surface,
        ),
      ),
    );
  }
}
