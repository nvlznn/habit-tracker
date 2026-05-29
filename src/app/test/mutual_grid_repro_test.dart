import 'package:flutter_test/flutter_test.dart';

import 'package:nokapp_habits/models/challenge.dart';
import 'package:nokapp_habits/utils/date_key.dart';
import 'package:nokapp_habits/utils/streak.dart';

/// Reproduces what the challenge detail screen computes for the mutual grid:
///   mutual = mutualDays(challenge.activeCheckins)
/// using the SAME key the check squares stamp (simulatedTodayKey()).
void main() {
  tearDown(() => demoDayOffset = 0);

  test('2-person challenge: both check the simulated today -> mutual has it', () {
    demoDayOffset = 12; // pretend 12 days passed (the "+days" button)
    final todayK = simulatedTodayKey();

    final c = Challenge(
      id: 'c',
      name: 'n',
      description: '',
      colorValue: 0,
      iconCodePoint: 0,
      participantIds: ['me', 'friend'],
      checkins: {
        'me': {todayK},
        'friend': {todayK},
      },
      createdAt: fromEpochDay(simulatedTodayEpochDay() - 1),
    );

    final mutual = mutualDays(c.activeCheckins);
    expect(mutual.contains(todayK), isTrue,
        reason: 'mutual grid should light up the simulated today');
  });

  test('3 participants but only two checked -> mutual is empty for today', () {
    demoDayOffset = 5;
    final todayK = simulatedTodayKey();

    final c = Challenge(
      id: 'c',
      name: 'n',
      description: '',
      colorValue: 0,
      iconCodePoint: 0,
      participantIds: ['me', 'f1', 'f2'],
      checkins: {
        'me': <String>{}, // <-- never checked
        'f1': {todayK},
        'f2': {todayK},
      },
      createdAt: fromEpochDay(simulatedTodayEpochDay() - 1),
    );

    final mutual = mutualDays(c.activeCheckins);
    expect(mutual.contains(todayK), isFalse,
        reason: 'one active participant has not checked -> no mutual day');
  });
}
