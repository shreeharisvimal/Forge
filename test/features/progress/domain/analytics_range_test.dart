// Unit tests for the progress analytics range.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/progress/domain/analytics_range.dart';

void main() {
  final now = DateTime(2026, 2, 4, 12); // Wednesday

  group('startDate', () {
    test('last7Days starts six days before the reference day', () {
      expect(AnalyticsRange.last7Days.startDate(now),
          DateTime(2026, 1, 29));
    });

    test('last30Days starts 29 days before', () {
      expect(AnalyticsRange.last30Days.startDate(now),
          DateTime(2026, 1, 6));
    });

    test('last90Days starts 89 days before', () {
      expect(AnalyticsRange.last90Days.startDate(now),
          DateTime(2025, 11, 7));
    });

    test('last6Months starts 182 days before', () {
      expect(AnalyticsRange.last6Months.startDate(now),
          DateTime(2025, 8, 6));
    });

    test('lastYear starts 364 days before', () {
      expect(AnalyticsRange.lastYear.startDate(now),
          DateTime(2025, 2, 5));
    });

    test('lifetime has no fixed start', () {
      expect(AnalyticsRange.lifetime.startDate(now), isNull);
    });

    test('truncates time and keeps calendar day precision', () {
      expect(AnalyticsRange.last7Days.startDate(now),
          AnalyticsRange.last7Days.startDate(now.add(const Duration(hours: 5))));
    });
  });

  group('labels', () {
    test('compact labels match the segmented control', () {
      expect(AnalyticsRange.last7Days.label, '7D');
      expect(AnalyticsRange.last30Days.label, '30D');
      expect(AnalyticsRange.last90Days.label, '90D');
      expect(AnalyticsRange.last6Months.label, '6M');
      expect(AnalyticsRange.lastYear.label, '1Y');
      expect(AnalyticsRange.lifetime.label, 'All');
    });

    test('full labels describe the window', () {
      expect(AnalyticsRange.last7Days.fullLabel, 'Last 7 days');
      expect(AnalyticsRange.last30Days.fullLabel, 'Last 30 days');
      expect(AnalyticsRange.last90Days.fullLabel, 'Last 90 days');
      expect(AnalyticsRange.last6Months.fullLabel, 'Last 6 months');
      expect(AnalyticsRange.lastYear.fullLabel, 'Last year');
      expect(AnalyticsRange.lifetime.fullLabel, 'All time');
    });
  });

  group('daySpan', () {
    test('reports the fixed window length', () {
      expect(AnalyticsRange.last7Days.daySpan, 7);
      expect(AnalyticsRange.last30Days.daySpan, 30);
      expect(AnalyticsRange.last90Days.daySpan, 90);
      expect(AnalyticsRange.last6Months.daySpan, 183);
      expect(AnalyticsRange.lastYear.daySpan, 365);
      expect(AnalyticsRange.lifetime.daySpan, 0);
    });
  });

  test('all lists every range in display order', () {
    expect(AnalyticsRange.all, const [
      AnalyticsRange.last7Days,
      AnalyticsRange.last30Days,
      AnalyticsRange.last90Days,
      AnalyticsRange.last6Months,
      AnalyticsRange.lastYear,
      AnalyticsRange.lifetime,
    ]);
  });
}
