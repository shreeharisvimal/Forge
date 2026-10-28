// Identifier helpers for the Forge application.
//
// Every persisted model is keyed by a UUID string. Centralizing generation
// here keeps IDs consistent and lets us swap generators in one place.
library;

import 'package:uuid/uuid.dart';

/// Generates a random v4 UUID string used as a storage key.
String generateId() => const Uuid().v4();

/// An ISO-8601 [DateTime] formatted for compact, sortable serialization.
String toIsoString(DateTime date) => date.toUtc().toIso8601String();

/// Parses an ISO-8601 string (as written by [toIsoString]) back into a
/// local-time [DateTime], preserving the exact instant.
///
/// `DateTime.parse` alone yields a UTC-flagged value for strings with an
/// offset; converting to local keeps round-trips value-equal to the
/// original local timestamps the models are constructed with.
DateTime parseIsoDate(String iso) => DateTime.parse(iso).toLocal();
