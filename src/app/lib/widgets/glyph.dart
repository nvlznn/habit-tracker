import 'package:flutter/material.dart';

/// Renders a habit/challenge symbol: the chosen [emoji] if one is set, otherwise
/// the Material icon for [codePoint]. Centralizes the emoji-vs-icon choice so
/// every card and detail screen stays consistent.
class Glyph extends StatelessWidget {
  const Glyph({
    super.key,
    required this.emoji,
    required this.codePoint,
    required this.size,
    this.color,
  });

  final String? emoji;
  final int codePoint;
  final double size;

  /// Tint for the Material icon. Ignored for emoji (they keep their own colors).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final e = emoji;
    if (e != null && e.isNotEmpty) {
      // The circular icon holders pass tight constraints; without Center the
      // emoji pins to the top-left and spills out of the circle. A slightly
      // smaller font keeps the glyph comfortably inside.
      return Center(
        child: Text(
          e,
          style: TextStyle(fontSize: size * 0.85, height: 1.0),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Icon(
      IconData(codePoint, fontFamily: 'MaterialIcons'),
      size: size,
      color: color,
    );
  }
}

/// The big tappable circle that shows the current glyph — the icon/emoji
/// selector at the top of the habit/challenge edit screens. Tapping it opens
/// the picker.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.emoji,
    required this.codePoint,
    required this.onTap,
  });

  final String? emoji;
  final int codePoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Glyph(emoji: emoji, codePoint: codePoint, size: 42),
        ),
      ),
    );
  }
}
