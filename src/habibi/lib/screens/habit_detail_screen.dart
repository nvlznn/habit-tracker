import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../utils/date_key.dart';
import '../utils/streak.dart';
import '../widgets/dot_grid.dart';
import '../widgets/month_calendar.dart';
import 'edit_habit_screen.dart';

/// The habit detail view. Presented as a floating card (modal bottom sheet)
/// over a dimmed background via [show], rather than as a full page.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  /// Opens the detail card for [habitId]. Use this instead of pushing a route.
  static Future<void> show(BuildContext context, String habitId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitDetailScreen(habitId: habitId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final habit = provider.byId(habitId);
        // The habit can vanish while the sheet is closing (e.g. after delete).
        if (habit == null) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final color = Color(habit.colorValue);
        // Follow the demo simulated clock like the rest of the habit UI.
        final streak = currentStreak(
          habit.dateKeys,
          asOf: fromEpochDay(simulatedTodayEpochDay()),
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 40, 12, 12),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: icon + name/description + close.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconData(habit.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.description.isEmpty
                                ? 'No Description'
                                : habit.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SquareButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Year heatmap, opened scrolled to the most recent days.
                _Heatmap(dateKeys: habit.dateKeys, color: color),
                const SizedBox(height: 16),
                // Frequency + current streak, with edit on the right.
                Row(
                  children: [
                    const _Pill(label: 'Daily'),
                    const SizedBox(width: 10),
                    _StreakPill(streak: streak, color: color),
                    const Spacer(),
                    _SquareButton(
                      icon: Icons.edit_outlined,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditHabitScreen(habitId: habit.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: cs.onSurface.withValues(alpha: 0.08),
                  height: 1,
                ),
                const SizedBox(height: 16),
                // Month calendar (tap a day to toggle it).
                MonthCalendar(
                  dateKeys: habit.dateKeys,
                  color: color,
                  asOf: fromEpochDay(simulatedTodayEpochDay()),
                  onToggleDate: (date) =>
                      provider.toggleDay(habit.id, dateKey(date)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The year heatmap, which is wider than the card so it scrolls horizontally.
/// Opens scrolled to the right end so the most recent (active) days show first.
class _Heatmap extends StatefulWidget {
  const _Heatmap({required this.dateKeys, required this.color});

  final Set<String> dateKeys;
  final Color color;

  @override
  State<_Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<_Heatmap> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: DotGrid(
        dateKeys: widget.dateKeys,
        color: widget.color,
        weeks: 26,
        dotSize: 12,
        spacing: 4,
        asOf: fromEpochDay(simulatedTodayEpochDay()),
      ),
    );
  }
}

/// A small rounded square icon button (close, edit).
class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.8)),
      ),
    );
  }
}

/// A static label pill (e.g. the "Daily" frequency).
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A pill showing the current streak with a flame icon.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: streak > 0 ? color : cs.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
