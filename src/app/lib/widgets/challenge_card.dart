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
import 'glyph.dart';

/// A challenge in the list, laid out like a habit card: icon, name + shared
/// streak, a check button (top-right) to mark *my* day, and a dot grid below.
/// In the grid a day I checked in shows as a hollow ring; a day *everyone*
/// checked in (the set intersection) shows as a filled circle.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(challenge.colorValue);
    final mutual = mutualDays(challenge.activeCheckins);
    final streak = mutualStreak(challenge.activeCheckins);

    final myId = context.read<AuthProvider>().currentUser?.id;
    final myDays = myId == null ? <String>{} : challenge.checkinsFor(myId);
    final todayKey = simulatedTodayKey();
    final doneToday = myDays.contains(todayKey);

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
                  child: Glyph(
                    emoji: challenge.emoji,
                    codePoint: challenge.iconCodePoint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              challenge.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StreakBadge(streak: streak, color: color),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${actives.length} people',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (myId != null)
                  _CheckSquare(
                    color: color,
                    done: doneToday,
                    onTap: () => context
                        .read<ChallengeProvider>()
                        .toggleDay(challenge.id, myId, todayKey),
                  ),
              ],
            ),
            if (showWarning) ...[
              const SizedBox(height: 12),
              _WarningBanner(text: warningText),
            ],
            const SizedBox(height: 16),
            DotGrid(
              dateKeys: mutual,
              ringKeys: myDays,
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

/// Small flame + shared-streak count shown right after the challenge name —
/// matches the habit card's streak badge.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = streak > 0 ? color : cs.onSurface.withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, size: 16, color: tint),
        const SizedBox(width: 3),
        Text(
          '$streak',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tint,
          ),
        ),
      ],
    );
  }
}

/// The tap-to-check button (top-right), identical to the habit card's: toggles
/// *my* check-in for today. White check when done, dimmed when not.
class _CheckSquare extends StatelessWidget {
  const _CheckSquare({
    required this.color,
    required this.done,
    required this.onTap,
  });

  final Color color;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: done ? color : color.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: 22,
          color: done ? Colors.white : color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
