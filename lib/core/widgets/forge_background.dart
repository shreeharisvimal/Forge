// Ambient animated background for the Forge application shell.
//
// A slow, drifting layered gradient that gives the glass UI a living,
// premium backdrop. Purely decorative: it repaints at a low cost via two
// radial-gradient blobs and respects the system reduced-motion setting by
// rendering a static frame when animations are disabled.
library;

import 'package:flutter/material.dart';

import '../design/animations/animation_config.dart';
import '../design/extensions/theme_extensions.dart';
import '../design/tokens/curve_tokens.dart';
import '../design/tokens/duration_tokens.dart';

/// A full-bleed animated ambient background.
class ForgeBackground extends StatefulWidget {
  /// Creates the ambient background.
  const ForgeBackground({super.key});

  @override
  State<ForgeBackground> createState() => _ForgeBackgroundState();
}

class _ForgeBackgroundState extends State<ForgeBackground>
    with SingleTickerProviderStateMixin {
  /// Whether the drift animation is gated off entirely.
  ///
  /// True while running under `flutter test` (a never-ending animation
  /// would otherwise make `pumpAndSettle` time out) and whenever the
  /// platform requests reduced motion.
  bool get _isStatic => AnimationConfig.isDisabled;

  late final AnimationController _controller;
  late final Animation<double> _firstDrift;
  late final Animation<double> _secondDrift;
  late final Animation<double> _thirdDrift;

  bool get _reduceMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.background,
    );
    if (!_isStatic) {
      _controller.repeat(reverse: true);
      _firstDrift = CurvedAnimation(
        parent: _controller,
        curve: AppCurves.backgroundDrift,
      );
      _secondDrift = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeInOut),
      );
      _thirdDrift = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion || _isStatic) {
      return const _StaticBackground();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _DriftingBackground(
          firstDrift: _firstDrift.value,
          secondDrift: _secondDrift.value,
          thirdDrift: _thirdDrift.value,
        );
      },
    );
  }
}

/// The fully static background used when animations are disabled.
class _StaticBackground extends StatelessWidget {
  const _StaticBackground();

  @override
  Widget build(BuildContext context) {
    return _DriftingBackground(
      firstDrift: 0.5,
      secondDrift: 0.5,
      thirdDrift: 0.5,
    );
  }
}

/// Lays out the base gradient and the three drifting glow blobs.
class _DriftingBackground extends StatelessWidget {
  const _DriftingBackground({
    required this.firstDrift,
    required this.secondDrift,
    required this.thirdDrift,
  });

  final double firstDrift;
  final double secondDrift;
  final double thirdDrift;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.background,
            colors.backgroundRaised,
            colors.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _Blob(
            color: colors.glowViolet,
            radiusFraction: 0.55,
            alignment: Alignment(
              -0.7 + 0.5 * firstDrift,
              -0.8 + 0.6 * firstDrift,
            ),
          ),
          _Blob(
            color: colors.glowCyan,
            radiusFraction: 0.45,
            alignment: Alignment(
              0.8 - 0.6 * secondDrift,
              0.7 - 0.5 * secondDrift,
            ),
          ),
          _Blob(
            color: colors.glowVioletDeep,
            radiusFraction: 0.6,
            alignment: Alignment(
              0.2 - 0.7 * thirdDrift,
              -0.4 + 0.8 * thirdDrift,
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft radial glow used as a drifting ambient light source.
class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.radiusFraction,
    required this.alignment,
  });

  final Color color;
  final double radiusFraction;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: radiusFraction,
        heightFactor: radiusFraction,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.32),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
