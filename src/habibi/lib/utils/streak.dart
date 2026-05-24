import 'date_key.dart';

/// Length of the current run of consecutive done-days ending at [asOf]
/// (default: the real today). Pass [asOf] to count from a different "today" —
/// challenges use the demo simulated clock so the streak lines up with the
/// check-ins, which are stamped with that same clock.
int currentStreak(Set<String> dateKeys, {DateTime? asOf}) {
  if (dateKeys.isEmpty) return 0;
  final today = asOf ?? DateTime.now();
  var cursor = DateTime(today.year, today.month, today.day);
  if (!dateKeys.contains(dateKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (dateKeys.contains(dateKey(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The days *every* participant marked done: the intersection of all their
/// date-key sets. Empty input (or any empty set) yields an empty result.
Set<String> mutualDays(Iterable<Set<String>> all) {
  final sets = all.toList();
  if (sets.isEmpty) return <String>{};
  var result = sets.first;
  for (var i = 1; i < sets.length; i++) {
    result = result.intersection(sets[i]);
    if (result.isEmpty) break;
  }
  // Copy so callers can't mutate a participant's underlying set.
  return result.toSet();
}

/// Shared streak: the [currentStreak] over the days everyone did the habit.
/// Counts from the simulated "today" so it matches challenge check-ins, which
/// are recorded with that same clock.
int mutualStreak(Iterable<Set<String>> all) => currentStreak(
      mutualDays(all),
      asOf: fromEpochDay(simulatedTodayEpochDay()),
    );

int longestStreak(Set<String> dateKeys) {
  if (dateKeys.isEmpty) return 0;
  final days = dateKeys.map(parseDateKey).toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final diff = days[i].difference(days[i - 1]).inDays;
    if (diff == 1) {
      run += 1;
      if (run > best) best = run;
    } else if (diff > 1) {
      run = 1;
    }
  }
  return best;
}
