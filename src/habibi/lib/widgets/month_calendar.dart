import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/date_key.dart';

class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.dateKeys,
    required this.color,
    required this.onToggleDate,
    this.asOf,
  });

  final Set<String> dateKeys;
  final Color color;
  final void Function(DateTime date) onToggleDate;

  /// The "today" the calendar opens on and uses to disable future days.
  /// Defaults to the real today; pass the demo simulated clock so the "add day"
  /// button moves "today" here too.
  final DateTime? asOf;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.asOf ?? DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.asOf ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstOfMonth = _visibleMonth;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final cells = List<DateTime?>.generate(
      leadingBlanks + daysInMonth,
      (i) => i < leadingBlanks
          ? null
          : DateTime(firstOfMonth.year, firstOfMonth.month, i - leadingBlanks + 1),
    );
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WeekHeader(),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: cells.map((d) {
            if (d == null) return const SizedBox.shrink();
            final isToday = d == todayDate;
            final isFuture = d.isAfter(todayDate);
            final isDone = widget.dateKeys.contains(dateKey(d));
            return _DayCell(
              date: d,
              isToday: isToday,
              isFuture: isFuture,
              isDone: isDone,
              color: widget.color,
              onTap: isFuture ? null : () => widget.onToggleDate(d),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_visibleMonth),
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.70)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => _shift(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => _shift(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54);
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool isDone;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = isDone
        ? color.withValues(alpha: 0.85)
        : (isToday ? color.withValues(alpha: 0.18) : Colors.transparent);
    // Done cells sit on the habit color, so keep their text white for contrast.
    final fg = isDone
        ? Colors.white
        : (isFuture ? onSurface.withValues(alpha: 0.24) : onSurface);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 14,
            color: fg,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
