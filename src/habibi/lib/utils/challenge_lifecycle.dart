import '../models/challenge.dart';
import 'date_key.dart';

/// Number of silent days a participant is allowed. With a threshold of 7, a
/// participant becomes *overdue* once more than 7 days have passed since their
/// last check-in (i.e. on the 8th silent day).
const int kOverdueThreshold = 7;

/// The most recent day [participantId] checked in (epoch day), or the
/// challenge's start day if they have never checked in.
int lastCheckInDay(Challenge c, String participantId) {
  final keys = c.checkinsFor(participantId);
  var best = c.startEpochDay;
  for (final k in keys) {
    final day = epochDay(parseDateKey(k));
    if (day > best) best = day;
  }
  return best;
}

/// Days since [participantId] last checked in, relative to [today].
int staleDays(Challenge c, String participantId, int today) =>
    today - lastCheckInDay(c, participantId);

/// Applies the lifecycle rules to [c] in place, given [today] (epoch day):
/// while an active participant is overdue, drop them if more than two remain,
/// otherwise end the challenge. Returns true if anything changed.
bool evaluateChallenge(Challenge c, int today) {
  if (c.status == ChallengeStatus.ended) return false;
  var changed = false;

  while (true) {
    final actives = c.activeParticipantIds;
    final overdue = actives
        .where((id) => staleDays(c, id, today) > kOverdueThreshold)
        .toList()
      ..sort((a, b) =>
          staleDays(c, b, today).compareTo(staleDays(c, a, today)));
    if (overdue.isEmpty) break;

    if (actives.length > 2) {
      final victim = overdue.first;
      c.dropped.add(DropRecord(
        participantId: victim,
        droppedOn: today,
        daysPersisted: c.checkinsFor(victim).length,
      ));
      changed = true;
      // Loop again: dropping may now expose the "only two left" end condition.
    } else {
      // Exactly two remain and at least one lapsed -> the challenge ends.
      c.status = ChallengeStatus.ended;
      c.endedOn = today;
      changed = true;
      break;
    }
  }

  return changed;
}
