// Analytics time-range filter for the Forge application.
//
// The Progress tab lets the user scope every analytics section to one of
// six windows. This file owns that vocabulary plus the window math the
// calculations and charts rely on. Pure Dart — no Flutter or Riverpod.
library;

/// The selectable analytics windows.
enum AnalyticsRange {
  /// The trailing 7 days (today and the six before it).
  last7Days,

  /// The trailing 30 days.
  last30Days,

  /// The trailing 90 days.
  last90Days,

  /// The trailing six months.
  last6Months,

  /// The trailing year.
  lastYear,

  /// The entire training history.
  lifetime;

  /// The compact segmented-control label, e.g. "7D".
  String get label => switch (this) {
        AnalyticsRange.last7Days => '7D',
        AnalyticsRange.last30Days => '30D',
        AnalyticsRange.last90Days => '90D',
        AnalyticsRange.last6Months => '6M',
        AnalyticsRange.lastYear => '1Y',
        AnalyticsRange.lifetime => 'All',
      };

  /// The expanded subtitle label, e.g. "Last 7 days".
  String get fullLabel => switch (this) {
        AnalyticsRange.last7Days => 'Last 7 days',
        AnalyticsRange.last30Days => 'Last 30 days',
        AnalyticsRange.last90Days => 'Last 90 days',
        AnalyticsRange.last6Months => 'Last 6 months',
        AnalyticsRange.lastYear => 'Last year',
        AnalyticsRange.lifetime => 'All time',
      };

  /// The inclusive start date of the window relative to [now], or `null`
  /// for [AnalyticsRange.lifetime] (the window starts at the first record).
  DateTime? startDate(DateTime now) {
    final reference = DateTime(now.year, now.month, now.day);
    return switch (this) {
      AnalyticsRange.last7Days => reference.subtract(const Duration(days: 6)),
      AnalyticsRange.last30Days => reference.subtract(const Duration(days: 29)),
      AnalyticsRange.last90Days => reference.subtract(const Duration(days: 89)),
      AnalyticsRange.last6Months => reference.subtract(const Duration(days: 182)),
      AnalyticsRange.lastYear => reference.subtract(const Duration(days: 364)),
      AnalyticsRange.lifetime => null,
    };
  }

  /// The number of days covered by the fixed windows (used to size the
  /// previous-period delta window). Lifetime reports 0.
  int get daySpan => switch (this) {
        AnalyticsRange.last7Days => 7,
        AnalyticsRange.last30Days => 30,
        AnalyticsRange.last90Days => 90,
        AnalyticsRange.last6Months => 183,
        AnalyticsRange.lastYear => 365,
        AnalyticsRange.lifetime => 0,
      };

  /// All ranges in display order.
  static const List<AnalyticsRange> all = [
    AnalyticsRange.last7Days,
    AnalyticsRange.last30Days,
    AnalyticsRange.last90Days,
    AnalyticsRange.last6Months,
    AnalyticsRange.lastYear,
    AnalyticsRange.lifetime,
  ];
}
