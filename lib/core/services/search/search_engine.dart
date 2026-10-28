// Reusable search utilities for the Forge application.
//
// This file provides a small, pure search toolkit: a scored [SearchResult]
// model, an abstract [SearchEngine] contract, a concrete [FuzzySearchEngine]
// that ranks items by substring, prefix and word-boundary matches, and a
// [Debouncer] that throttles rapid input. None of these touch storage or the
// logger, so they are trivially testable in isolation.
library;

import 'dart:async';

/// A single search hit carrying its relevance [score] and the [matchedTerms]
/// that produced it.
class SearchResult<T> {
  /// Creates a search result.
  const SearchResult({
    required this.item,
    required this.score,
    required this.matchedTerms,
  });

  /// The matched item.
  final T item;

  /// Relevance score; higher is a better match.
  final double score;

  /// The query tokens that matched at least one field of [item].
  final List<String> matchedTerms;
}

/// The contract for search implementations.
abstract class SearchEngine<T> {
  /// Returns [items] ranked by relevance to [query], best first.
  List<SearchResult<T>> search(Iterable<T> items, String query);

  /// Splits [query] into the searchable tokens it uses.
  List<String> tokens(String query);
}

/// A substring, prefix and word-boundary search over one text projection.
///
/// Each item's searchable text is produced by [textOf]. Callers with several
/// searchable fields should concatenate them, e.g.
/// `textOf: (item) => '${item.name} ${item.muscleGroup}'`.
class FuzzySearchEngine<T> extends SearchEngine<T> {
  /// Creates a fuzzy search engine.
  ///
  /// [textOf] projects an item onto its searchable text and defaults to
  /// [toString].
  FuzzySearchEngine({String Function(T)? textOf})
    : _textOf = textOf ?? ((T item) => item.toString());

  final String Function(T) _textOf;

  /// Score per matched character of a token.
  static const double _charScore = 10;

  /// Bonus when the item's text starts with the token.
  static const double _prefixBonus = 5;

  /// Bonus when the token starts a word (preceded by a word boundary).
  static const double _boundaryBonus = 3;

  /// ASCII range for the digit `0`.
  static const int _asciiZero = 0x30;

  /// ASCII range for the digit `9`.
  static const int _asciiNine = 0x39;

  /// ASCII range for `a`.
  static const int _asciiLowerA = 0x61;

  /// ASCII range for `z`.
  static const int _asciiLowerZ = 0x7a;

  @override
  List<String> tokens(String query) {
    final lower = query.toLowerCase();
    return lower
        .split(RegExp('[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  @override
  List<SearchResult<T>> search(Iterable<T> items, String query) {
    final queryTokens = tokens(query);
    if (queryTokens.isEmpty) return const [];

    final ranked = <(int, SearchResult<T>)>[];
    var index = 0;
    for (final item in items) {
      final haystack = _textOf(item).toLowerCase();
      var score = 0.0;
      final matched = <String>[];
      for (final token in queryTokens) {
        final tokenScore = _scoreToken(token, haystack);
        if (tokenScore > 0) {
          matched.add(token);
          score += tokenScore;
        }
      }
      if (score > 0) {
        ranked.add((
          index,
          SearchResult(item: item, score: score, matchedTerms: matched),
        ));
      }
      index++;
    }

    ranked.sort((a, b) {
      final byScore = b.$2.score.compareTo(a.$2.score);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return [for (final entry in ranked) entry.$2];
  }

  /// Scores one [token] against the lowercased [haystack].
  ///
  /// Returns 0 when the token is absent, otherwise the per-character base
  /// score plus a bonus when the match is a prefix of the text (+5) or
  /// starts a word (+3).
  double _scoreToken(String token, String haystack) {
    final index = haystack.indexOf(token);
    if (index < 0) return 0;
    var score = _charScore * token.length;
    if (index == 0) {
      score += _prefixBonus;
    } else if (!_isWordCharacter(haystack.codeUnitAt(index - 1))) {
      score += _boundaryBonus;
    }
    return score;
  }

  /// Whether [codeUnit] is a lowercase letter or digit (ASCII).
  ///
  /// The haystack is lowercased before scoring, so only the lowercase
  /// ranges need checking.
  bool _isWordCharacter(int codeUnit) =>
      (codeUnit >= _asciiZero && codeUnit <= _asciiNine) ||
      (codeUnit >= _asciiLowerA && codeUnit <= _asciiLowerZ);
}

/// Throttles a burst of calls so only the last one runs.
///
/// Each [call] cancels the pending timer (if any) and starts a fresh one, so
/// [action] fires only after [delay] of silence. [onDone], when provided,
/// runs immediately after a fired [action]. Call [cancel] to drop the
/// pending action without firing.
class Debouncer {
  /// Creates a debouncer with a [delay] and optional completion hook.
  Debouncer(this.delay, {this.onDone});

  /// How long to wait after the last [call] before firing.
  final Duration delay;

  /// Runs after a debounced [action] completes.
  final void Function()? onDone;

  Timer? _timer;

  /// Debounces [action]: cancels any pending timer and schedules a new one.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      action();
      onDone?.call();
    });
  }

  /// Cancels any pending action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
