// Glass loading for the Forge Design System.
//
// A loading indicator available as a gradient spinner, an indeterminate
// bar or a set of bouncing dots, with an optional label.
library;

import 'package:flutter/material.dart';

import '../animations/animation_config.dart';
import '../extensions/theme_extensions.dart';
import '../tokens/icon_size_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'glass_progress_bar.dart';

/// The loading indicator styles.
enum GlassLoadingVariant {
  /// Rotating gradient arc.
  spinner,

  /// Indeterminate shimmer bar.
  bar,

  /// Bouncing dots.
  dots,
}

/// A glass loading indicator.
class GlassLoading extends StatefulWidget {
  /// Creates a loading indicator.
  const GlassLoading({
    super.key,
    this.variant = GlassLoadingVariant.spinner,
    this.size = AppIconSize.medium,
    this.color,
    this.label,
  });

  /// The indicator style.
  final GlassLoadingVariant variant;

  /// Diameter of the spinner / dots.
  final double size;

  /// Color override.
  final Color? color;

  /// Optional label shown under the indicator.
  final String? label;

  @override
  State<GlassLoading> createState() => _GlassLoadingState();
}

class _GlassLoadingState extends State<GlassLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (!AnimationConfig.isDisabled) {
      _controller.repeat();
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
    final color = widget.color ?? colors.primary;

    final Widget indicator = switch (widget.variant) {
      GlassLoadingVariant.spinner => _Spinner(controller: _controller, size: widget.size, color: color),
      GlassLoadingVariant.bar => SizedBox(
          width: widget.size * 2.4,
          child: GlassProgressBar(value: null, height: 6, color: color),
        ),
      GlassLoadingVariant.dots => _Dots(controller: _controller, size: widget.size, color: color),
    };

    if (widget.label == null) return indicator;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        SizedBox(height: AppSpacing.sm),
        Text(
          widget.label!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
        ),
      ],
    );
  }
}

/// Rotating gradient arc spinner.
class _Spinner extends StatelessWidget {
  const _Spinner({
    required this.controller,
    required this.size,
    required this.color,
  });

  final AnimationController controller;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RotationTransition(
        turns: controller,
        child: CustomPaint(
          painter: _SpinnerPainter(color: color),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -1.5708;
    const sweepAngle = 4.4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [color.withValues(alpha: 0.15), color],
      ).createShader(rect);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.color != color;
}

/// Three staggered bouncing dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.controller, required this.size, required this.color});

  final AnimationController controller;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) _dot(i),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    final phase = (controller.value + index / 3) % 1.0;
    final scale = 0.5 + 0.5 * (1 - (phase - 0.5).abs() * 2);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size / 3,
          height: size / 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.extraSmall),
          ),
        ),
      ),
    );
  }
}
