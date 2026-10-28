// Glass progress bar for the Forge Design System.
//
// A rounded glass progress bar with animated determinate fill and an
// indeterminate sliding shimmer.
library;

import 'package:flutter/material.dart';

import '../animations/animation_config.dart';
import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/radius_tokens.dart';
import 'glass_container.dart';

/// A glass progress bar.
class GlassProgressBar extends StatefulWidget {
  /// Creates a glass progress bar.
  const GlassProgressBar({
    super.key,
    this.value,
    this.height,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Progress from 0.0 to 1.0. When `null` the bar is indeterminate.
  final double? value;

  /// Track height.
  final double? height;

  /// Fill color override.
  final Color? color;

  /// Track color override.
  final Color? backgroundColor;

  /// Corner radius of the track.
  final BorderRadiusGeometry? borderRadius;

  @override
  State<GlassProgressBar> createState() => _GlassProgressBarState();
}

class _GlassProgressBarState extends State<GlassProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.value == null && !AnimationConfig.isDisabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlassProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isIndeterminate = widget.value == null;
    if (AnimationConfig.isDisabled) {
      _controller.stop();
    } else if (isIndeterminate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!isIndeterminate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final trackColor = widget.backgroundColor ?? colors.glassStrong;
    final fillColor = widget.color ?? colors.primary;
    final height = widget.height ?? 6;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.extraSmall);

    Widget track = GlassContainer(
      decoration: GlassDecoration(
        color: trackColor,
        borderRadius: radius,
        border: const GlassBorder(width: AppBorderWidth.none),
      ),
      borderRadius: radius,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.extraSmall),
        child: widget.value == null
            ? _buildIndeterminate(fillColor)
            : _buildDeterminate(fillColor),
      ),
    );
    return track;
  }

  Widget _buildDeterminate(Color fillColor) {
    final value = widget.value?.clamp(0.0, 1.0) ?? 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 240),
      builder: (context, animated, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: animated,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: GlassGradient(colors: AppGradients.primary)
                    .toLinearGradient(),
                borderRadius: BorderRadius.circular(AppRadius.extraSmall),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndeterminate(Color fillColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final barWidth = width * 0.3;
            final left = AnimationConfig.isDisabled
                ? width * 0.35
                : (_controller.value - 0.3) * width;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  width: barWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: GlassGradient(colors: AppGradients.primary)
                          .toLinearGradient(),
                      borderRadius: BorderRadius.circular(AppRadius.extraSmall),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
