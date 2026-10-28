// Glass slider for the Forge Design System.
//
// A draggable glass slider with an animated fill, glowing thumb and
// optional discrete divisions.
library;

import 'package:flutter/material.dart';

import '../extensions/theme_extensions.dart';
import '../glass/glass_border.dart';
import '../glass/glass_decoration.dart';
import '../glass/glass_gradient.dart';
import '../tokens/border_width_tokens.dart';
import '../tokens/gradient_presets.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../utilities/haptic_helper.dart';
import 'glass_container.dart';

/// A glass slider.
class GlassSlider extends StatefulWidget {
  /// Creates a glass slider.
  const GlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.activeColor,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The current value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Optional number of discrete steps.
  final int? divisions;

  /// Invoked with the new value while dragging.
  final ValueChanged<double>? onChanged;

  /// Fill color override.
  final Color? activeColor;

  /// Optional semantic label.
  final String? semanticLabel;

  /// Whether the slider is interactive.
  final bool enabled;

  @override
  State<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<GlassSlider> {
  double? _dragValue;

  double get _value => (_dragValue ?? widget.value).clamp(widget.min, widget.max);

  double _snap(double raw) {
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0) return raw;
    final steps = divisions.toDouble();
    final snapped = ((raw - widget.min) * steps / (widget.max - widget.min))
            .round() /
        steps;
    return widget.min + snapped * (widget.max - widget.min);
  }

  void _handleDrag(double fraction) {
    final raw = widget.min + (widget.max - widget.min) * fraction.clamp(0.0, 1.0);
    final snapped = _snap(raw);
    if (snapped != _dragValue) {
      HapticHelper.fire(HapticType.selection);
    }
    setState(() => _dragValue = snapped);
    widget.onChanged?.call(snapped);
  }

  void _endDrag() {
    setState(() => _dragValue = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final activeColor = widget.activeColor ?? colors.primary;
    final thumbSize = AppSpacing.xxl;
    final trackHeight = AppSpacing.sm;
    final range = widget.max - widget.min;

    final fraction = range <= 0
        ? 0.0
        : (_value - widget.min) / range;

    return Semantics(
      label: widget.semanticLabel,
      slider: true,
      value: _value.toStringAsFixed(2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth - thumbSize;
          final thumbLeft = fraction * trackWidth;

          return GestureDetector(
            onHorizontalDragStart: (details) {
              final localDx = details.localPosition.dx - thumbSize / 2;
              _handleDrag(localDx / trackWidth);
            },
            onHorizontalDragUpdate: (details) {
              final localDx = details.localPosition.dx - thumbSize / 2;
              _handleDrag(localDx / trackWidth);
            },
            onHorizontalDragEnd: (_) => _endDrag(),
            child: SizedBox(
              height: thumbSize,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GlassContainer(
                    decoration: GlassDecoration(
                      color: colors.glassStrong,
                      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                      border: const GlassBorder(width: AppBorderWidth.none),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                    height: trackHeight,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                          gradient: GlassGradient(colors: AppGradients.primary)
                              .toLinearGradient(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: GlassGradient(colors: AppGradients.glass)
                            .toLinearGradient(),
                        border: Border.all(color: colors.borderStrong),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: thumbSize / 2,
                          height: thumbSize / 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
