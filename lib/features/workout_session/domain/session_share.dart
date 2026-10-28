// Share-text builder for a finished workout session.
//
// Produces a compact, plain-text summary ready to paste into a messenger or
// social post. Pure functions only — no Flutter or Riverpod imports.
library;

import 'session_formatters.dart';

/// Builds the human-readable summary shared after a session.
abstract final class SessionShareText {
  SessionShareText._();

  /// Builds the share text.
  static String build({
    required String sessionName,
    required DateTime date,
    required Duration duration,
    required int exerciseCount,
    required int setCount,
    required double volumeKg,
    required int repCount,
    required int calories,
    required SessionWeightUnit unit,
  }) {
    final dateLabel = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer()
      ..writeln('#Forge Workout — $sessionName')
      ..writeln(dateLabel)
      ..writeln()
      ..writeln('$exerciseCount exercises · $setCount sets · $repCount reps')
      ..writeln(
        'Volume: ${SessionFormatters.volume(volumeKg, unit)} · Duration: '
        '${SessionFormatters.shortDuration(duration)}',
      );
    if (calories > 0) buffer.writeln('Est. $calories kcal');
    buffer.write('#ForgeApp #TrainHard');
    return buffer.toString();
  }
}
