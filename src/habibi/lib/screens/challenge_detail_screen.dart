import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../utils/date_key.dart';
import '../utils/streak.dart';
import '../widgets/dot_grid.dart';

/// The heart of the feature. Shows the shared streak (the days *everyone*
/// checked in) plus each participant's own history, and lets you toggle today
/// for each person — so you can demo, live, how the set intersection drives the
/// streak: it grows only when all participants are checked in for the day.
class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChallengeProvider>(
      builder: (context, auth, social, _) {
        final challenge = social.byId(challengeId);
        if (challenge == null) {
          return const Scaffold(
            body: Center(child: Text('Challenge not found')),
          );
        }
        final meId = auth.currentUser?.id;
        final color = Color(challenge.colorValue);
        final mutual = mutualDays(challenge.allCheckins);
        final streak = mutualStreak(challenge.allCheckins);
        final friendsById = {
          for (final f in social.friends) f.id: f.displayName,
        };
        String labelFor(String id) =>
            id == meId ? 'You' : (friendsById[id] ?? 'Friend');

        return Scaffold(
          appBar: AppBar(
            title: Text(challenge.name),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, challenge),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(challenge: challenge),
                const SizedBox(height: 20),
                _SharedStreakCard(streak: streak, color: color),
                const SizedBox(height: 16),
                _Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DotGrid(
                      dateKeys: mutual,
                      color: color,
                      weeks: 26,
                      dotSize: 12,
                      spacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Today',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'The streak counts only on days everyone is checked in.',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 12),
                for (final id in challenge.participantIds)
                  _ParticipantRow(
                    challengeId: challenge.id,
                    participantId: id,
                    label: labelFor(id),
                    isMe: id == meId,
                    color: color,
                    dateKeys: challenge.checkinsFor(id),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Challenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete challenge?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ChallengeProvider>().deleteChallenge(challenge.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconData(challenge.iconCodePoint, fontFamily: 'MaterialIcons'),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (challenge.description.isNotEmpty)
                Text(
                  challenge.description,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SharedStreakCard extends StatelessWidget {
  const _SharedStreakCard({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              size: 40, color: streak > 0 ? color : Colors.white24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak',
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(height: 2),
              const Text(
                'shared day streak',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One participant's today-toggle + their own history grid. Tapping the square
/// toggles that person's check-in for today (for the friend this "simulates"
/// their device, so the demo can be driven from one screen).
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.challengeId,
    required this.participantId,
    required this.label,
    required this.isMe,
    required this.color,
    required this.dateKeys,
  });

  final String challengeId;
  final String participantId;
  final String label;
  final bool isMe;
  final Color color;
  final Set<String> dateKeys;

  @override
  Widget build(BuildContext context) {
    final today = todayKey();
    final doneToday = dateKeys.contains(today);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isMe ? 'tap to check in today' : 'tap to simulate today',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              _CheckSquare(
                color: color,
                done: doneToday,
                onTap: () => context
                    .read<ChallengeProvider>()
                    .toggleDay(challengeId, participantId, today),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DotGrid(dateKeys: dateKeys, color: color, weeks: 26),
          ),
        ],
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(10),
        ),
        child: done
            ? const Icon(Icons.check, size: 22, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
