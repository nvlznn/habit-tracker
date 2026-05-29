import 'package:flutter/material.dart';

import '../utils/palette.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selectedValue,
    required this.onSelect,
  });

  final int selectedValue;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurface;
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: habitColors.map((c) {
        // ignore: deprecated_member_use
        final value = c.value;
        final selected = value == selectedValue;
        return GestureDetector(
          onTap: () => onSelect(value),
          child: Container(
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: borderColor, width: 2.5)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
