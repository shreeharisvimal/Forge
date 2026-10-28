// Glass celebration dialog for the Forge application.
//
// The post-workout payoff: a frosted dialog over a confetti burst that lists
// every record the finished session broke, with a success haptic and a system
// sound cue. Non-blocking — the user can dismiss it to reach the summary.
// The confetti respects [AnimationConfig] and renders a static frame under
// tests and reduced-motion settings.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/design/forge_design.dart';
import '../../workout_session/domain/session_formatters.dart';
import '../data/pr_event.dart';
import '../services/pr_sound_service.dart';
import 'pr_widget_utils.dart';

/// Presents the PR celebration dialog.
abstract final class GlassCelebrationDialog {
  GlassCelebrationDialog._();

  /// Shows the celebration for [events], firing a success haptic and the
  /// celebration sound. No-op when [events] is empty.
  static Future<void> show(
    BuildContext context, {
    required List<PrEvent> events,
    required SessionWeightUnit unit,
    PrSoundService? sound,
  }) {
    if (events.isEmpty) return Future.value();
    unawaited(HapticHelper.fire(HapticType.success));
    final cues = sound ?? PrSoundService();
    unawaited(cues.celebrate());
    return GlassDialog.show<void>(
      context,
      barrierDismissible: true,
      builder: (context) => _CelebrationBody(events: events, unit: unit),
    );
  }
}

/// The dialog content: confetti burst behind a glass record card.
class _CelebrationBody extends StatelessWidget {
  const _CelebrationBody({required this.events, required this.unit});

  final List<PrEvent> events;
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final radius = BorderRadius.circular(AppRadius.large);

    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(child: _ConfettiBurst()),
        GlassContainer(
          decoration: GlassDecoration(
            color: colors.glassStrong,
            borderRadius: radius,
            border: GlassBorder(color: colors.border),
            blur: const GlassBlur(AppBlur.heavy),
            shadows: [
              for (final s in AppShadows.modal)
                GlassShadow(color: s.color, blurRadius: s.blurRadius, offset: s.offset),
              GlassShadow(color: colors.primary.withValues(alpha: 0.12), blurRadius: 36, offset: const Offset(0, 18)),
            ],
            highlight: true,
          ),
          borderRadius: radius,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          constraints: BoxConstraints(maxWidth: AppSpacing.maxContentWidth * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer(
                width: AppSpacing.huge + AppSpacing.sm,
                height: AppSpacing.huge + AppSpacing.sm,
                borderRadius: BorderRadius.circular(AppRadius.large),
                decoration: GlassDecoration(
                  color: colors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: const GlassBorder(),
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: AppIconSize.extraLarge,
                    color: colors.success,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'New personal records',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                events.length == 1
                    ? 'You beat a lifetime best this session.'
                    : 'You beat ${events.length} lifetime bests this session.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
              ),
              SizedBox(height: AppSpacing.lg),
              for (final event in events.take(3))
                _RecordRow(event: event, unit: unit),
              if (events.length > 3) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  '+${events.length - 3} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                ),
              ],
              SizedBox(height: AppSpacing.xxl),
              GlassButton(
                label: 'Keep going',
                icon: Icons.flag_rounded,
                size: GlassButtonSize.large,
                expanded: true,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single freshly broken record inside the celebration card.
class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.event, required this.unit});

  final PrEvent event;
  final SessionWeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).forgeColors;
    final type = event.prType;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(prTypeIcon(type), size: AppIconSize.small, color: colors.success),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${event.exerciseName} · ${type.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
            ),
          ),
          Text(
            prValueLabel(type, event.value, unit),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// A lightweight confetti burst.
///
/// Animates colored specks falling across the dialog. When animations are
/// disabled it renders a static mid-frame burst instead of a repeating
/// controller.
class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst();

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static final List<Color> _palette = [
    ForgeColors.success,
    ForgeColors.primary,
    ForgeColors.secondary,
    ForgeColors.warning,
  ];

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _particles = List.generate(
      42,
      (_) => _Particle(
        color: _palette[random.nextInt(_palette.length)],
        size: 4 + random.nextDouble() * 5,
        startX: random.nextDouble(),
        phase: random.nextDouble(),
        speed: 0.7 + random.nextDouble() * 0.6,
        drift: 0.5 + random.nextDouble(),
        rotationRate: random.nextDouble() * 4,
      ),
    );
    _controller = AnimationController(vsync: this, duration: AppDuration.slow);
    if (AnimationConfig.isDisabled) {
      _controller.value = 0.5;
    } else {
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            progress: _controller.value,
            particles: _particles,
          ),
        ),
      ),
    );
  }
}

/// One falling speck of confetti.
class _Particle {
  const _Particle({
    required this.color,
    required this.size,
    required this.startX,
    required this.phase,
    required this.speed,
    required this.drift,
    required this.rotationRate,
  });

  final Color color;
  final double size;
  final double startX;
  final double phase;
  final double speed;
  final double drift;
  final double rotationRate;
}

/// Paints the falling particles at [progress] (0..1).
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final particle in particles) {
      final t = ((progress * particle.speed + particle.phase) % 1.0);
      final y = -0.1 * size.height + t * 1.2 * size.height;
      final sway = sin(t * 2 * pi * particle.drift) * 0.08;
      final x = (particle.startX + sway) * size.width;
      final angle = t * particle.rotationRate * pi * 2;

      paint.color = particle.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.particles != particles;
}
