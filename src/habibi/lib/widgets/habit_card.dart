import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../screens/habit_detail_screen.dart';
import '../utils/date_key.dart';
import 'dot_grid.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    this.locked = false,
    this.onLockedTap,
  });

  final Habit habit;

  /// When true the card is greyed out and read-only (used for habits beyond the
  /// free limit). Tapping it calls [onLockedTap] instead of opening the detail.
  final bool locked;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(habit.colorValue);
    // Use the demo simulated clock so the "add day" button moves the habit's
    // "today" too (check-ins, the highlighted square, and the grid all follow).
    final today = simulatedTodayKey();
    final isDoneToday = habit.dateKeys.contains(today);

    final card = Container(
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
                child: Icon(
                  IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (locked)
                Icon(Icons.lock_outline,
                    size: 22, color: cs.onSurface.withValues(alpha: 0.5))
              else
                _CheckSquare(
                  color: color,
                  done: isDoneToday,
                  onTap: () =>
                      context.read<HabitProvider>().toggleDay(habit.id, today),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DotGrid(
            dateKeys: habit.dateKeys,
            color: color,
            asOf: fromEpochDay(simulatedTodayEpochDay()),
          ),
        ],
      ),
    );

    if (locked) {
      return Opacity(
        opacity: 0.55,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onLockedTap,
          child: card,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => HabitDetailScreen.show(context, habit.id),
      child: card,
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
          shape: BoxShape.circle,
        ),
        // Always show the check; it's white when done, and a dimmed habit
        // color when not, so the button reads as "tap to check" rather than
        // looking empty.
        child: Icon(
          Icons.check,
          size: 22,
          color: done ? Colors.white : color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
