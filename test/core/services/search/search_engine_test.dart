// Tests for the search engine and debouncer.
//
// Covers tokenization, scoring and ranking rules, stable ordering, matched
// terms, and the timer lifecycle of the Debouncer.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/search/search_engine.dart';

void main() {
  group('tokens', () {
    final engine = FuzzySearchEngine<String>();

    test('splits on non-alphanumerics and lowercases', () {
      expect(engine.tokens('Bench Press'), ['bench', 'press']);
      expect(engine.tokens('Squat-rack 45lb'), ['squat', 'rack', '45lb']);
      expect(engine.tokens('pull-up'), ['pull', 'up']);
    });

    test('drops empty tokens', () {
      expect(engine.tokens(''), isEmpty);
      expect(engine.tokens('   !!!   '), isEmpty);
    });
  });

  group('search', () {
    final engine = FuzzySearchEngine<String>();

    test('empty query returns no results', () {
      expect(engine.search(['bench press'], ''), isEmpty);
    });

    test('no matches return an empty list', () {
      expect(engine.search(['bench press', 'deadlift'], 'curl'), isEmpty);
    });

    test('prefix matches outrank boundary matches', () {
      final results = engine.search([
        'air squat',
        'squat rack',
        'squat',
      ], 'squat');
      expect(results.map((r) => r.item).toList(), [
        'squat rack',
        'squat',
        'air squat',
      ]);
      expect(results.first.score, greaterThan(results.last.score));
    });

    test('ranking is stable for equal scores', () {
      final results = engine.search([
        'squat bar',
        'squat machine',
        'squat',
      ], 'squat');
      expect(results.map((r) => r.item).toList(), [
        'squat bar',
        'squat machine',
        'squat',
      ]);
      expect(results[0].score, results[1].score);
    });

    test('substring matches score but below prefixes', () {
      final prefix = engine.search(['overhead press', 'hold'], 'over');
      expect(prefix.map((r) => r.item).toList(), ['overhead press']);
      final substring = engine.search(['deadlift', 'hold'], 'old');
      expect(substring.map((r) => r.item).toList(), ['hold']);
    });

    test('matching is case-insensitive', () {
      final results = engine.search(['BENCH PRESS'], 'bench');
      expect(results, hasLength(1));
      expect(results.single.item, 'BENCH PRESS');
    });

    test('matchedTerms records every matching token', () {
      final results = engine.search(['bench press', 'press up'], 'bench press');
      final benchPress = results.firstWhere((r) => r.item == 'bench press');
      expect(benchPress.matchedTerms, containsAll(['bench', 'press']));
      final pressUp = results.firstWhere((r) => r.item == 'press up');
      expect(pressUp.matchedTerms, ['press']);
    });
  });

  group('FuzzySearchEngine projection', () {
    test('textOf defaults to toString', () {
      final engine = FuzzySearchEngine<Object>();
      final results = engine.search([_Label('BENCH PRESS')], 'bench');
      expect(results, hasLength(1));
    });

    test('textOf selects the searchable field', () {
      final engine = FuzzySearchEngine<({String name, String note})>(
        textOf: (item) => item.note,
      );
      final items = [
        (name: 'a', note: 'front squat'),
        (name: 'b', note: 'deadlift'),
      ];
      final results = engine.search(items, 'squat');
      expect(results.map((r) => r.item).toList(), [
        (name: 'a', note: 'front squat'),
      ]);
    });
  });

  group('Debouncer', () {
    test('fires only after the delay', () async {
      var fired = 0;
      final debouncer = Debouncer(
        const Duration(milliseconds: 30),
        onDone: () => fired++,
      );
      debouncer(() => fired++);
      expect(fired, 0);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fired, 2);
    });

    test('a later call cancels the pending one', () async {
      var fired = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      debouncer(() => fired++);
      debouncer(() => fired++);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fired, 1);
    });

    test('cancel drops the pending action', () async {
      var fired = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      debouncer(() => fired++);
      debouncer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fired, 0);
    });
  });
}

class _Label {
  _Label(this.text);

  final String text;

  @override
  String toString() => text;
}
