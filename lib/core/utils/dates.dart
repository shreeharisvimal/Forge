// Date helpers for the Forge application.
//
// Several models store timestamps with time-of-day precision while calendar
// queries need whole-day semantics. These helpers normalize that gap.
library;

/// A new [DateTime] for the same calendar day as [date], at midnight local.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whether [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether [day] falls within the inclusive range [from]..[to].
///
/// Comparisons are day-precision: the time component is ignored.
bool isBetweenInclusive(DateTime day, DateTime from, DateTime to) {
  final d = dateOnly(day);
  final f = dateOnly(from);
  final t = dateOnly(to);
  return (d.isAfter(f) || d == f) && (d.isBefore(t) || d == t);
}
