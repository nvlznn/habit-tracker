import 'package:flutter/material.dart';

import '../utils/date_key.dart';

class DotGrid extends StatelessWidget {
  const DotGrid({
    super.key,
    required this.dateKeys,
    required this.color,
    this.ringKeys,
    this.weeks = 24,
    this.dotSize = 8,
    this.spacing = 3,
    this.asOf,
  });

  /// Days drawn as a *filled* circle. For challenges these are the days everyone
  /// checked in (the set intersection).
  final Set<String> dateKeys;
  final Color color;

  /// Days drawn as a *hollow* ring when they aren't already in [dateKeys]. For
  /// challenges these are the days I personally checked in but not everyone did.
  /// Null (the default) means no rings — the plain habit grid.
  final Set<String>? ringKeys;

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
              final key = dateKey(cellDate);
              final isDone = !isFuture && dateKeys.contains(key);
              // A day I checked in but not everyone -> hollow ring.
              final isMine =
                  !isFuture && !isDone && (ringKeys?.contains(key) ?? false);
              return Padding(
                padding: EdgeInsets.only(left: col == 0 ? 0 : spacing),
                child: _Dot(
                  size: dotSize,
                  color: isFuture
                      ? Colors.transparent
                      : (isDone ? color : (isMine ? Colors.transparent : dimColor)),
                  borderColor: isMine ? color : null,
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
  const _Dot({required this.size, required this.color, this.borderColor});
  final double size;
  final Color color;

  /// When set, the dot is drawn as a hollow ring in this color.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor!,
                width: (size * 0.18).clamp(1.2, 3.0),
              ),
      ),
    );
  }
}
