import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge_card.dart';
import 'edit_challenge_screen.dart';

/// Tab 2: shared "challenge" habits between you and a friend.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _startCreate(context),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ChallengeProvider>(
        builder: (context, auth, social, _) {
          if (!auth.isSignedIn) {
            return const _Hint(
              icon: Icons.account_circle_outlined,
              text: 'Sign in on the Friends tab\nto create challenges',
            );
          }
          final challenges = social.challenges;
          if (challenges.isEmpty) {
            return const _Hint(
              icon: Icons.local_fire_department_outlined,
              text: 'No challenges yet.\nTap + to start one with a friend.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: challenges.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => ChallengeCard(challenge: challenges[i]),
          );
        },
      ),
    );
  }

  void _startCreate(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final social = context.read<ChallengeProvider>();
    if (!auth.isSignedIn) {
      _snack(context, 'Sign in on the Friends tab first');
      return;
    }
    if (social.friends.isEmpty) {
      _snack(context, 'Add a friend on the Friends tab first');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditChallengeScreen()),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
