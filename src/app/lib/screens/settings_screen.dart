import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../data/billing_repository.dart';
import '../providers/challenge_provider.dart';
import '../providers/entitlement_provider.dart';
import '../providers/habit_provider.dart';
import '../utils/date_key.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The simulated clock is a developer tool — show it only in the dev build,
    // never to real users in the prod build.
    final isDev = context.watch<AppConfig>().isDev;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Nokapp Pro'),
          const _ProSection(),
          const Divider(height: 32),
          if (isDev) ...[
            _SectionLabel('Developer (demo)'),
            const _DemoClockSection(),
            const Divider(height: 32),
          ],
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Nokapp'),
            subtitle: Text(
                'A minimal habit tracker. School project for the DSAP course.'),
          ),
          const ListTile(
            leading: Icon(Icons.tag),
            title: Text('Version'),
            subtitle: Text('0.1.0 (prototype)'),
          ),
        ],
      ),
    );
  }
}

/// Small grey heading above each settings group.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

/// Shows an "Upgrade to Pro" card for free users, or the active plan plus
/// Restore / (demo) Reset actions for Pro users.
class _ProSection extends StatelessWidget {
  const _ProSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<EntitlementProvider>(
      builder: (context, ent, _) {
        if (ent.isPro) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.workspace_premium, color: cs.primary),
                title: const Text('Pro active'),
                subtitle: Text('${ent.currentPlan!.label} plan'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ent.restore();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases restored')),
                      );
                    },
                    child: const Text('Restore purchases'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: ent.resetToFree,
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Reset to Free (testing)'),
                  ),
                ],
              ),
            ],
          );
        }
        return Material(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlimited habits, charts, import/export & more',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Demo-only: advance a simulated clock so the 7-day challenge lifecycle can be
/// tested without waiting. Refreshes challenges so drops/endings apply at once.
class _DemoClockSection extends StatefulWidget {
  const _DemoClockSection();

  @override
  State<_DemoClockSection> createState() => _DemoClockSectionState();
}

class _DemoClockSectionState extends State<_DemoClockSection> {
  void _add(int days) {
    setState(() => demoDayOffset += days);
    context.read<ChallengeProvider>().refresh();
    context.read<HabitProvider>().refresh();
  }

  void _reset() {
    setState(() => demoDayOffset = 0);
    context.read<ChallengeProvider>().refresh();
    context.read<HabitProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulated clock: +$demoDayOffset days',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
                onPressed: () => _add(1), child: const Text('+1 day')),
            OutlinedButton(
                onPressed: () => _add(7), child: const Text('+7 days')),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Moves "today" forward for habit check-ins, challenge check-ins, and '
          'the 7-day rule. To demo a kick, keep the members you want to survive '
          'checked in within the last 7 days, leave one member idle, then '
          'advance past their 7th silent day — only that member is dropped.',
          style:
              TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
      ],
    );
  }
}
