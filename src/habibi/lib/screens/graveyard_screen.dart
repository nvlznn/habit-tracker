import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../utils/date_key.dart';

/// Read-only history of challenges that ended, or that the current user was
/// dropped from. Records are kept forever and cannot be revived.
class GraveyardScreen extends StatelessWidget {
  const GraveyardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graveyard'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<AuthProvider, ChallengeProvider>(
        builder: (context, auth, social, _) {
          final cs = Theme.of(context).colorScheme;
          final myId = auth.currentUser?.id;
          if (myId == null) {
            return _centerHint(cs, 'Sign in to see past challenges');
          }
          final items = social.graveyardForMe(myId);
          if (items.isEmpty) {
            return _centerHint(
              cs,
              'No challenges have ended yet.\nOnes that fizzle out will rest here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GraveTile(challenge: items[i], myId: myId),
          );
        },
      ),
    );
  }

  Widget _centerHint(ColorScheme cs, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: cs.onSurface.withValues(alpha: 0.54)),
          ),
        ),
      );
}

class _GraveTile extends StatelessWidget {
  const _GraveTile({required this.challenge, required this.myId});

  final Challenge challenge;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(challenge.colorValue);
    final ended = challenge.status == ChallengeStatus.ended;
    final today = simulatedTodayEpochDay();
    final lifespan =
        challenge.lifespanDays(ended ? challenge.endedOn! : today);
    final myDrop = challenge.dropFor(myId);
    final myDays = myDrop?.daysPersisted ?? challenge.checkinsFor(myId).length;
    final lifeLine =
        ended ? 'Lived $lifespan days' : 'Still going · $lifespan days';
    final tag = ended ? 'ENDED' : 'YOU LEFT';

    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(challenge.iconCodePoint, fontFamily: 'MaterialIcons'),
                size: 22,
                color: color,
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
                  const SizedBox(height: 2),
                  Text(
                    'You persisted $myDays days · $lifeLine',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Tag(text: tag),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
