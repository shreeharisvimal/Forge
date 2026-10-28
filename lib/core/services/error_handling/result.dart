// Result wrapper for the Forge application.
//
// Every fallible service operation returns a [Result] instead of throwing.
// A [Result] is either a [Success] carrying the value or a [Failure]
// carrying a typed [ForgeFailure]. Callers use [when]/[map] to branch, and
// [trySync]/[tryAsync] convert thrown exceptions into failures at the edge.
library;

import 'forge_failures.dart';

/// The outcome of a fallible operation.
///
/// Sealed so the compiler keeps every pattern-match over a [Result] in sync.
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Whether this result succeeded.
  bool get isSuccess;

  /// Whether this result failed.
  bool get isFailure => !isSuccess;

  /// The value on success, otherwise null.
  T? get valueOrNull;

  /// The failure on error, otherwise null.
  ForgeFailure? get failureOrNull;

  /// Returns the value if present, otherwise the result of [fallback].
  T getOrElse(T Function() fallback);

  /// Branches on the outcome.
  R when<R>({
    required R Function(T value) success,
    required R Function(ForgeFailure failure) failure,
  });

  /// Transforms the value, passing failures through unchanged.
  Result<R> map<R>(R Function(T value) transform);

  /// Transforms the value asynchronously, passing failures through.
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform);

  /// A successful [Result] wrapping [value].
  static Success<T> success<T>(T value) => Success(value);

  /// A failed [Result] wrapping [failure].
  static Failure<T> failure<T>(ForgeFailure failure) => Failure(failure);

  /// Runs [action], converting any thrown error into an [UnknownFailure].
  static Result<T> trySync<T>(T Function() action) {
    try {
      return Success(action());
    } catch (error, stackTrace) {
      return Failure(FailureMapper.toFailure(error, stackTrace: stackTrace));
    }
  }

  /// Runs [action], converting any thrown error into a [Failure].
  ///
  /// [classify] lets callers map specific exceptions onto a typed failure;
  /// when omitted, [FailureMapper] decides.
  static Future<Result<T>> tryAsync<T>(
    Future<T> Function() action, {
    ForgeFailure Function(Object error, StackTrace stackTrace)? classify,
  }) async {
    try {
      return Success(await action());
    } catch (error, stackTrace) {
      return Failure(
        classify?.call(error, stackTrace) ??
            FailureMapper.toFailure(error, stackTrace: stackTrace),
      );
    }
  }
}

/// The successful outcome of an operation.
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.value);

  /// The produced value.
  final T value;

  @override
  bool get isSuccess => true;

  @override
  T? get valueOrNull => value;

  @override
  ForgeFailure? get failureOrNull => null;

  @override
  T getOrElse(T Function() fallback) => value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(ForgeFailure failure) failure,
  }) =>
      success(value);

  @override
  Result<R> map<R>(R Function(T value) transform) =>
      Success(transform(value));

  @override
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      Success(await transform(value));

  @override
  String toString() => 'Success($value)';
}

/// The failed outcome of an operation.
final class Failure<T> extends Result<T> {
  /// Creates a failed result.
  const Failure(this.failure);

  /// The typed failure describing the error.
  final ForgeFailure failure;

  @override
  bool get isSuccess => false;

  @override
  T? get valueOrNull => null;

  @override
  ForgeFailure? get failureOrNull => failure;

  @override
  T getOrElse(T Function() fallback) => fallback();

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(ForgeFailure failure) failure,
  }) =>
      failure(this.failure);

  @override
  Result<R> map<R>(R Function(T value) transform) => Failure(failure);

  @override
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      Failure(failure);

  @override
  String toString() => 'Failure($failure)';
}
