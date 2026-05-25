import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/entitlement_provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import 'edit_habit_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nokapp',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.add),
            onPressed: () => _onAdd(context),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, _) {
          final all = provider.habits;
          final isPro = context.watch<EntitlementProvider>().isPro;
          const limit = EntitlementProvider.freeHabitLimit;
          // Free users keep their oldest [limit] habits active; any extra are
          // locked (read-only) until they go Pro. Pro users see everything.
          final active = isPro ? all : all.take(limit).toList();
          final locked = isPro ? const <Habit>[] : all.skip(limit).toList();

          return Column(
            children: [
              if (!isPro) _CapacityBar(used: active.length),
              Expanded(
                child: all.isEmpty
                    ? const _EmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          for (final h in active) ...[
                            HabitCard(habit: h),
                            const SizedBox(height: 12),
                          ],
                          if (locked.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _LockedHeader(count: locked.length),
                            const SizedBox(height: 12),
                            for (final h in locked) ...[
                              HabitCard(
                                habit: h,
                                locked: true,
                                onLockedTap: () => _openPaywall(context),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Tapping + : free users at the 3-habit limit see the paywall first. If they
  /// upgrade there (or are already Pro), continue to the new-habit screen.
  Future<void> _onAdd(BuildContext context) async {
    final ent = context.read<EntitlementProvider>();
    final count = context.read<HabitProvider>().habits.length;
    if (!ent.isPro && count >= EntitlementProvider.freeHabitLimit) {
      final unlocked = await _openPaywall(context);
      if (unlocked != true) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditHabitScreen()),
    );
  }

  Future<bool?> _openPaywall(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }
}

/// Slim banner for free users: how many of the 3 free habit slots are used,
/// with a shortcut to Pro once the limit is reached.
class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.used});

  final int used;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const limit = EntitlementProvider.freeHabitLimit;
    final atLimit = used >= limit;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            atLimit ? Icons.lock_outline : Icons.bolt_outlined,
            size: 18,
            color: atLimit ? cs.primary : cs.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              atLimit
                  ? 'Free limit reached · $used/$limit habits'
                  : 'Free plan · $used/$limit habits',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (atLimit)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
              child: const Text('Go Pro'),
            ),
        ],
      ),
    );
  }
}

/// Heading above the locked-habits section shown to free users with extras.
class _LockedHeader extends StatelessWidget {
  const _LockedHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.lock_outline,
            size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          '$count locked · restore with Pro',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 56, color: cs.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
                fontSize: 16, color: cs.onSurface.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first',
            style: TextStyle(
                fontSize: 13, color: cs.onSurface.withValues(alpha: 0.38)),
          ),
        ],
      ),
    );
  }
}
