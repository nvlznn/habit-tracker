import 'package:flutter/material.dart';

import '../utils/date_key.dart';

class DotGrid extends StatelessWidget {
  const DotGrid({
    super.key,
    required this.dateKeys,
    required this.color,
    this.weeks = 24,
    this.dotSize = 8,
    this.spacing = 3,
    this.asOf,
  });

  final Set<String> dateKeys;
  final Color color;
  final int weeks;
  final double dotSize;
  final double spacing;

  /// The "today" the grid is anchored on (its last column). Defaults to the
  /// real today; challenge grids pass the demo simulated clock so check-ins
  /// stamped with that clock land in the visible range rather than the future.
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) {
    final today = asOf ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final currentWeekStart =
        todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final gridStart =
        currentWeekStart.subtract(Duration(days: (weeks - 1) * 7));
    final dimColor = color.withValues(alpha: 0.18);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (row) {
        return Padding(
          padding: EdgeInsets.only(top: row == 0 ? 0 : spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(weeks, (col) {
              final cellDate =
                  gridStart.add(Duration(days: col * 7 + row));
              final isFuture = cellDate.isAfter(todayDate);
              final isDone = !isFuture && dateKeys.contains(dateKey(cellDate));
              return Padding(
                padding: EdgeInsets.only(left: col == 0 ? 0 : spacing),
                child: _Dot(
                  size: dotSize,
                  color: isFuture
                      ? Colors.transparent
                      : (isDone ? color : dimColor),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
