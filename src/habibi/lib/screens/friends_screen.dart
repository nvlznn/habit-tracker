import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';

/// Tab 3: account + friends.
///
/// The "sign in" here is a local placeholder that stands in for real Google
/// sign-in — it creates a local profile so the rest of the demo can work
/// offline. Swapping in `firebase_auth` later only changes the repository.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final profile = auth.currentUser;
          if (profile == null) return const _SignedOutView();
          return _SignedInView(displayName: profile.displayName, email: profile.email);
        },
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 56, color: cs.onSurface.withValues(alpha: 0.24)),
            const SizedBox(height: 16),
            Text(
              'Sign in to add friends\nand build streaks together',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: cs.onSurface.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _signIn(context),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Demo sign-in — no real Google account needed yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.38)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final name = await _promptName(context, title: 'Your name');
    if (name == null || !context.mounted) return;
    await context.read<AuthProvider>().signIn(
          displayName: name,
          email: _fauxEmail(name),
        );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ProfileHeader(displayName: displayName, email: email),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => _addFriend(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Consumer<ChallengeProvider>(
          builder: (context, social, _) {
            final friends = social.friends;
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No friends yet.\nAdd one to start a challenge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38)),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final f in friends) _FriendTile(friend: f),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
          label: const Text('Sign out',
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Future<void> _addFriend(BuildContext context) async {
    final name = await _promptName(context, title: "Friend's name");
    if (name == null || !context.mounted) return;
    await context.read<ChallengeProvider>().addFriend(
          displayName: name,
          email: _fauxEmail(name),
        );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainer,
        title: const Text('Sign out?'),
        content: const Text('Your friends and challenges stay on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(name: displayName, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.60),
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Avatar(name: friend.displayName, size: 40),
      title: Text(friend.displayName),
      subtitle: friend.email == null ? null : Text(friend.email!),
      trailing: IconButton(
        icon: Icon(Icons.close,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
        onPressed: () =>
            context.read<ChallengeProvider>().removeFriend(friend.id),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Faux email so the demo profile looks Google-ish without a real account.
String _fauxEmail(String name) =>
    '${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.')}@gmail.com';

/// Shared single-field text prompt. Returns the trimmed text, or null if
/// cancelled / empty.
Future<String?> _promptName(BuildContext context, {required String title}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).colorScheme.surfaceContainer,
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Name'),
        onSubmitted: (_) =>
            Navigator.pop(ctx, controller.text.trim().isEmpty ? null : controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
              ctx, controller.text.trim().isEmpty ? null : controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
