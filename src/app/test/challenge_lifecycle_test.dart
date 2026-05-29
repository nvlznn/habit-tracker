import 'package:flutter_test/flutter_test.dart';

import 'package:nokapp_habits/models/challenge.dart';
import 'package:nokapp_habits/utils/challenge_lifecycle.dart';
import 'package:nokapp_habits/utils/date_key.dart';

/// A check-in date-key for the given epoch day (round-trips through date_key).
String keyForDay(int epoch) => dateKey(fromEpochDay(epoch));

/// Build a challenge whose participants checked in on the given epoch days.
Challenge make(
  List<String> ids,
  Map<String, List<int>> checkinDays, {
  required int startDay,
}) {
  return Challenge(
    id: 'c',
    name: 'n',
    description: '',
    colorValue: 0,
    iconCodePoint: 0,
    participantIds: ids,
    checkins: {
      for (final e in checkinDays.entries)
        e.key: {for (final d in e.value) keyForDay(d)},
    },
    createdAt: fromEpochDay(startDay),
  );
}

void main() {
  test('drops the overdue participant while more than two remain', () {
    final c = make(
      ['a', 'b', 'c'],
      {
        'a': [109],
        'b': [108],
        'c': [98, 99, 100], // last check-in day 100 -> stale 10 at today=110
      },
      startDay: 95,
    );

    final changed = evaluateChallenge(c, 110);

    expect(changed, isTrue);
    expect(c.status, ChallengeStatus.active);
    expect(c.activeParticipantIds, ['a', 'b']);
    expect(c.isDropped('c'), isTrue);
    // c had 3 check-ins before being dropped.
    expect(c.dropFor('c')!.daysPersisted, 3);
    expect(c.dropFor('c')!.droppedOn, 110);
  });

  test('ends when only two remain and one lapses', () {
    final c = make(
      ['a', 'b'],
      {
        'a': [109],
        'b': [100], // stale 10 at today=110
      },
      startDay: 95,
    );

    final changed = evaluateChallenge(c, 110);

    expect(changed, isTrue);
    expect(c.status, ChallengeStatus.ended);
    expect(c.endedOn, 110);
  });

  test('cascades from four down to ended through successive drops', () {
    final c = make(
      ['a', 'b', 'c', 'd'],
      {
        'a': [119], // fine
        'b': [100], // overdue
        'c': [101], // overdue
        'd': [100], // overdue
      },
      startDay: 95,
    );

    final changed = evaluateChallenge(c, 120);

    expect(changed, isTrue);
    // b and d (most stale) get dropped first, leaving a + c; c is overdue and
    // only two remain, so the challenge ends.
    expect(c.status, ChallengeStatus.ended);
    expect(c.dropped.length, 2);
    expect(c.isDropped('b'), isTrue);
    expect(c.isDropped('d'), isTrue);
  });

  test('7 silent days is allowed, 8 is not', () {
    final notQuite = make(
      ['a', 'b', 'c'],
      {
        'a': [107],
        'b': [107],
        'c': [100], // stale 7 at today=107 -> still allowed
      },
      startDay: 95,
    );
    expect(evaluateChallenge(notQuite, 107), isFalse);
    expect(notQuite.dropped, isEmpty);

    final overdue = make(
      ['a', 'b', 'c'],
      {
        'a': [108],
        'b': [108],
        'c': [100], // stale 8 at today=108 -> dropped
      },
      startDay: 95,
    );
    expect(evaluateChallenge(overdue, 108), isTrue);
    expect(overdue.isDropped('c'), isTrue);
  });

  test('an already-ended challenge is left untouched', () {
    final c = make(['a', 'b'], {'a': [100], 'b': [100]}, startDay: 95)
      ..status = ChallengeStatus.ended
      ..endedOn = 105;

    expect(evaluateChallenge(c, 999), isFalse);
    expect(c.endedOn, 105);
  });
}
