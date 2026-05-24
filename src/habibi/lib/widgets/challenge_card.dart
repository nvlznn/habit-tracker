import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';
import '../utils/challenge_lifecycle.dart';
import '../utils/date_key.dart';
import '../utils/streak.dart';
import 'dot_grid.dart';

/// A challenge in the list: icon, name, the shared streak, and a dot grid of the
/// days *everyone* checked in (the set intersection). Shows a warning when a
/// member is close to lapsing the 7-day rule.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(challenge.colorValue);
    final mutual = mutualDays(challenge.activeCheckins);
    final streak = mutualStreak(challenge.activeCheckins);

    // Warning based on the most overdue active participant.
    final today = simulatedTodayEpochDay();
    final actives = challenge.activeParticipantIds;
    var maxStale = 0;
    for (final id in actives) {
      final s = staleDays(challenge, id, today);
      if (s > maxStale) maxStale = s;
    }
    final daysLeft = (kOverdueThreshold + 1) - maxStale;
    final showWarning = challenge.status == ChallengeStatus.active &&
        daysLeft >= 1 &&
        daysLeft <= 3;
    final endsNext = actives.length <= 2;

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
              _WarningBanner(daysLeft: daysLeft, endsChallenge: endsNext),
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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.daysLeft, required this.endsChallenge});

  final int daysLeft;
  final bool endsChallenge;

  @override
  Widget build(BuildContext context) {
    final d = daysLeft == 1 ? '1 day' : '$daysLeft days';
    final msg = endsChallenge
        ? 'Ends in $d unless someone checks in'
        : 'A member is dropped in $d';
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
              msg,
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
