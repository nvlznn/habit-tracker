import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';
import '../utils/streak.dart';
import 'dot_grid.dart';

/// A challenge in the list: icon, name, the shared streak, and a dot grid of the
/// days *everyone* checked in (the set intersection).
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(challenge.colorValue);
    final mutual = mutualDays(challenge.allCheckins);
    final streak = mutualStreak(challenge.allCheckins);

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
          borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(10),
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
                        '${challenge.participantIds.length} people',
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
            const SizedBox(height: 16),
            DotGrid(dateKeys: mutual, color: color),
          ],
        ),
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
