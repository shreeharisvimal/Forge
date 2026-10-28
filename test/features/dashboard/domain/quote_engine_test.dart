// Unit tests for the dashboard quote engine.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/dashboard/domain/quote_engine.dart';

void main() {
  group('QuoteEngine.library', () {
    test('contains at least 300 quotes', () {
      expect(QuoteEngine.library.length, greaterThanOrEqualTo(300));
    });

    test('every quote has text and an author', () {
      for (final quote in QuoteEngine.library) {
        expect(quote.text.trim(), isNotEmpty);
        expect(quote.author.trim(), isNotEmpty);
      }
    });
  });

  group('QuoteEngine.forDate', () {
    test('returns an entry from the library for any date', () {
      for (var i = 0; i < 400; i++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: i));
        final quote = QuoteEngine.forDate(date);
        expect(QuoteEngine.library, contains(quote));
      }
    });

    test('is deterministic for the same date', () {
      final first = QuoteEngine.forDate(DateTime(2026, 2, 4, 9));
      final second = QuoteEngine.forDate(DateTime(2026, 2, 4, 21));

      expect(first.text, second.text);
      expect(first.author, second.author);
    });

    test('covers the full library before repeating', () {
      final seen = <String>{};
      for (var i = 0; i < QuoteEngine.library.length; i++) {
        seen.add(QuoteEngine.forDate(DateTime(2026, 3, 1).add(Duration(days: i))).text);
      }
      expect(seen.length, QuoteEngine.library.length);
    });
  });
}
