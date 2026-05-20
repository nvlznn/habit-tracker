import 'package:flutter/material.dart';

/// Tab 2: shared "challenge" habits. Built out in a later phase.
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
      ),
      body: const Center(
        child: Text('Coming soon', style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}
