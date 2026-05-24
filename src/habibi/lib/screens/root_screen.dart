import 'package:flutter/material.dart';

import 'challenges_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';

/// App shell: three bottom tabs. An [IndexedStack] keeps each tab's state alive
/// when you switch away and back.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ChallengesScreen(),
    FriendsScreen(),
  ];

  static const _items = [
    _NavData(
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      label: 'Habits',
    ),
    _NavData(
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department,
      label: 'Challenges',
    ),
    _NavData(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Friends',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  data: _items[i],
                  selected: _index == i,
                  onTap: () => setState(() => _index = i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavData {
  const _NavData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A single tab. Unselected tabs show just the icon; the selected tab expands
/// into a translucent, rounded pill containing the icon and its label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          // Translucent tint so the pill reads as "glassy" rather than a solid
          // block; fully transparent when the tab isn't selected.
          color: selected ? cs.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? data.selectedIcon : data.icon,
              size: 24,
              color: selected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.55),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                data.label,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
