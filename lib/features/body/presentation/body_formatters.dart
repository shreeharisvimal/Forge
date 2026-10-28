// Value and unit formatting for the body measurement feature.
//
// Storage is always metric (kg / cm / %). Display converts to the user's
// chosen units from settings. Pure functions — no Flutter imports.
library;

import '../../../models/settings_model.dart';
import '../domain/body_measurement_fields.dart';

/// Unit-aware formatting helpers for body measurements.
abstract final class BodyFormatters {
  BodyFormatters._();

  static const double _cmPerInch = 2.54;

  /// The unit label for a field, honoring the user's settings.
  static String unitFor(BodyField field, SettingsModel settings) {
    if (field.isPercent) return '%';
    if (field.isWeight) return settings.weightUnit;
    return settings.lengthUnit;
  }

  /// Converts a stored metric value into the user's display unit.
  static double displayValue(double value, BodyField field, SettingsModel settings) {
    if (field.isPercent) return value;
    if (field.isWeight) {
      return settings.weightUnit == 'lb' ? value * 2.2046226218 : value;
    }
    return settings.lengthUnit == 'in' ? value / _cmPerInch : value;
  }

  /// Formats a value in the user's unit, trimming trailing zeros.
  static String value(double raw, BodyField field, SettingsModel settings) {
    final display = displayValue(raw, field, settings);
    if (display == display.roundToDouble()) return display.round().toString();
    return display.toStringAsFixed(1);
  }

  /// Formats a value including the unit, e.g. "80 kg" or "34.6 in".
  static String valueWithUnit(double raw, BodyField field, SettingsModel settings) =>
      '${value(raw, field, settings)} ${unitFor(field, settings)}';

  /// Formats a signed delta including the unit, e.g. "+1.2 kg".
  static String deltaWithUnit(double delta, BodyField field, SettingsModel settings) {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${value(delta, field, settings)} ${unitFor(field, settings)}';
  }
}
