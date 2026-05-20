import 'date_key.dart';

int currentStreak(Set<String> dateKeys) {
  if (dateKeys.isEmpty) return 0;
  final today = DateTime.now();
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
int mutualStreak(Iterable<Set<String>> all) => currentStreak(mutualDays(all));

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
