import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../screens/challenge_detail_screen.dart';
import '../utils/challenge_lifecycle.dart';
import '../utils/date_key.dart';
import '../utils/streak.dart';
import 'dot_grid.dart';

/// A challenge in the list: icon, name, the shared streak, and a dot grid of the
/// days *everyone* checked in (the set intersection). Shows a warning naming the
/// member(s) about to lapse the 7-day rule.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(challenge.colorValue);
    final mutual = mutualDays(challenge.activeCheckins);
    final streak = mutualStreak(challenge.activeCheckins);

    // Each member has their own 7-day timer (see challenge_lifecycle): they are
    // kicked on their 8th silent day. Warn within 3 days, and name the member(s)
    // who will lapse soonest.
    final today = simulatedTodayEpochDay();
    final actives = challenge.activeParticipantIds;
    int? soonest;
    final atRisk = <String>[];
    for (final id in actives) {
      final left = daysUntilKick(challenge, id, today);
      if (left < 1 || left > 3) continue;
      if (soonest == null || left < soonest) {
        soonest = left;
        atRisk
          ..clear()
          ..add(id);
      } else if (left == soonest) {
        atRisk.add(id);
      }
    }
    final showWarning =
        challenge.status == ChallengeStatus.active && atRisk.isNotEmpty;
    // Kicking a member when only two remain ends the whole challenge instead.
    final endsNext = actives.length <= 2;

    String warningText = '';
    if (showWarning) {
      final myId = context.read<AuthProvider>().currentUser?.id;
      final namesById = {
        for (final f in context.read<ChallengeProvider>().friends)
          f.id: f.displayName,
      };
      final labels = atRisk
          .map((id) => id == myId ? 'You' : (namesById[id] ?? 'A friend'))
          .toList();
      warningText = _warningText(labels, soonest!, endsNext);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(challenge.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${actives.length} people',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.38)),
                      ),
                    ],
                  ),
                ),
                _StreakBadge(streak: streak, color: color),
              ],
            ),
            if (showWarning) ...[
              const SizedBox(height: 12),
              _WarningBanner(text: warningText),
            ],
            const SizedBox(height: 16),
            DotGrid(
              dateKeys: mutual,
              color: color,
              asOf: fromEpochDay(simulatedTodayEpochDay()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Joins names for the warning: "You", "Sam", "Sam and Lee",
/// "Sam, Lee and Max".
String _joinNames(List<String> names) {
  if (names.length == 1) return names.first;
  if (names.length == 2) return '${names[0]} and ${names[1]}';
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// Warning sentence naming who is about to lapse and in how many days. When only
/// two remain, a kick ends the challenge, so it is phrased that way instead.
String _warningText(List<String> labels, int daysLeft, bool endsNext) {
  final dayWord = daysLeft == 1 ? 'day' : 'days';
  final isPlural = labels.length > 1 || labels.first == 'You';

  if (endsNext) {
    // "you" reads better mid-sentence than "You".
    final subject = labels.length == 1 && labels.first == 'You'
        ? 'you'
        : _joinNames(labels);
    final verb = isPlural ? 'check in' : 'checks in';
    return 'Challenge ends in $daysLeft $dayWord unless $subject $verb';
  }

  final subject = _joinNames(labels);
  final verb = isPlural ? 'are' : 'is';
  return '$subject $verb going to be kicked out in $daysLeft $dayWord';
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.local_fire_department,
            size: 20,
            color: streak > 0 ? color : cs.onSurface.withValues(alpha: 0.24)),
        const SizedBox(width: 2),
        Text(
          '$streak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: streak > 0
                ? cs.onSurface
                : cs.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}
