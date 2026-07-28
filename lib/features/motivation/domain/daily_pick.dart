/// Deterministically picks one item for a given calendar day.
///
/// Used for the daily "your why" quote so it stays stable within a day but
/// rotates day to day. Pure and generic (no Flutter/drift), so it's trivially
/// testable. Returns null for an empty list.
T? pickDaily<T>(List<T> items, DateTime date) {
  if (items.isEmpty) return null;
  final int dayNumber =
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
  return items[dayNumber % items.length];
}
