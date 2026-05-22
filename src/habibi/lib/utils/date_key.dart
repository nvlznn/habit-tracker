import 'package:intl/intl.dart';

final DateFormat _fmt = DateFormat('yyyy-MM-dd');

String dateKey(DateTime d) => _fmt.format(DateTime(d.year, d.month, d.day));

String todayKey() => dateKey(DateTime.now());

DateTime parseDateKey(String key) => _fmt.parseStrict(key);

int epochDay(DateTime d) {
  final utcMidnight = DateTime.utc(d.year, d.month, d.day);
  return utcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

DateTime fromEpochDay(int day) {
  return DateTime.fromMillisecondsSinceEpoch(
    day * Duration.millisecondsPerDay,
    isUtc: true,
  );
}

int todayEpochDay() => epochDay(DateTime.now());

/// Demo-only: a number of days to pretend have passed, so the time-based
/// challenge lifecycle can be tested without waiting. 0 in normal use.
int demoDayOffset = 0;

/// "Today" used by the challenge lifecycle, including any demo offset.
int simulatedTodayEpochDay() => todayEpochDay() + demoDayOffset;

/// "Today" as a date-key string, including any demo offset. Challenge check-ins
/// use this so they line up with the simulated lifecycle clock.
String simulatedTodayKey() => dateKey(fromEpochDay(simulatedTodayEpochDay()));
