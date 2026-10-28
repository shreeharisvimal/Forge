// Post-session recovery recommendations for the Forge application.
//
// Derives which muscle buckets were trained from the exercised groups and
// the recommended rest window before each is trained again. Pure functions
// only — no Flutter or Riverpod imports.
library;

import '../../../features/dashboard/domain/dashboard_models.dart';
import '../../../features/dashboard/domain/recovery_service.dart';

/// A muscle bucket trained during the session and its recovery window.
class SessionRecovery {
  /// Creates a recovery recommendation.
  const SessionRecovery({required this.group, required this.targetHours});

  /// The trained muscle bucket.
  final RecoveryGroup group;

  /// Hours to full recovery before training this bucket again.
  final int targetHours;

  /// Human label, e.g. "Chest · ~48h rest".
  String get label => '${group.label} · ~${targetHours}h rest';
}

/// Builds recovery recommendations from the session's muscle groups.
abstract final class SessionRecoveryCalculator {
  SessionRecoveryCalculator._();

  /// Maps a list of trained muscle group names to unique recovery buckets,
  /// ordered as [RecoveryGroup.values]. Groups that do not fatigue a
  /// strength bucket (cardio, mobility) are ignored.
  static List<SessionRecovery> compute(Iterable<String> muscleGroups) {
    final seen = <RecoveryGroup>{};
    final buckets = <SessionRecovery>[];
    for (final group in muscleGroups) {
      for (final bucket in RecoveryGroupResolver.resolve(group)) {
        if (seen.add(bucket)) {
          buckets.add(SessionRecovery(
            group: bucket,
            targetHours: RecoveryWindows.hours[bucket] ?? 48,
          ));
        }
      }
    }
    return [
      for (final group in RecoveryGroup.values)
        if (seen.contains(group))
          buckets.firstWhere((entry) => entry.group == group),
    ];
  }
}
