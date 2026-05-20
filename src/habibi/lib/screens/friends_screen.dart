import 'package:flutter/material.dart';

/// Tab 3: account + friends. Built out in a later phase.
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
      body: const Center(
        child: Text('Coming soon', style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}
