import 'package:flutter/material.dart';

import '../utils/emoji_catalog.dart';
import '../utils/icon_catalog.dart';

/// What the picker returns: either a Material icon code point or an emoji string
/// (exactly one is non-null).
class IconChoice {
  const IconChoice.icon(this.codePoint) : emoji = null;
  const IconChoice.emoji(this.emoji) : codePoint = null;

  final int? codePoint;
  final String? emoji;
}

/// Full-screen picker with an "Icon / Emoji" toggle, a search box, and
/// categorized grids. Pops with an [IconChoice] when the user taps a cell.
class IconEmojiPickerScreen extends StatefulWidget {
  const IconEmojiPickerScreen({
    super.key,
    this.selectedCodePoint,
    this.selectedEmoji,
  });

  final int? selectedCodePoint;
  final String? selectedEmoji;

  @override
  State<IconEmojiPickerScreen> createState() => _IconEmojiPickerScreenState();
}

class _IconEmojiPickerScreenState extends State<IconEmojiPickerScreen> {
  // 0 = Icon, 1 = Emoji.
  late int _tab = widget.selectedEmoji != null ? 1 : 0;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: _SegToggle(
          tab: _tab,
          onChanged: (t) => setState(() {
            _tab = t;
            _searchCtrl.clear();
            _query = '';
          }),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: _tab == 0
                    ? 'Type a search term'
                    : 'Type a search term or emoji',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(child: _tab == 0 ? _buildIcons() : _buildEmojis()),
        ],
      ),
    );
  }

  // ---- Icon tab ----------------------------------------------------------

  Widget _buildIcons() {
    if (_query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          for (final cat in iconCatalog)
            ..._section(
                cat.name, [for (final e in cat.entries) _iconCell(e.icon)]),
        ],
      );
    }
    final matches = <Widget>[
      for (final cat in iconCatalog)
        for (final e in cat.entries)
          if (e.keywords.contains(_query)) _iconCell(e.icon),
    ];
    return _results(matches);
  }

  Widget _iconCell(IconData icon) {
    final selected =
        widget.selectedEmoji == null && icon.codePoint == widget.selectedCodePoint;
    return _Cell(
      selected: selected,
      onTap: () => Navigator.pop(context, IconChoice.icon(icon.codePoint)),
      child: Icon(icon, size: 24),
    );
  }

  // ---- Emoji tab ---------------------------------------------------------

  Widget _buildEmojis() {
    if (_query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          for (final cat in emojiCatalog)
            ..._section(
                cat.name, [for (final e in cat.entries) _emojiCell(e.emoji)]),
        ],
      );
    }
    final matches = <Widget>[
      for (final cat in emojiCatalog)
        for (final e in cat.entries)
          if (e.keywords.contains(_query) || e.emoji == _query)
            _emojiCell(e.emoji),
    ];
    return _results(matches);
  }

  Widget _emojiCell(String emoji) {
    final selected = widget.selectedEmoji == emoji;
    return _Cell(
      selected: selected,
      onTap: () => Navigator.pop(context, IconChoice.emoji(emoji)),
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  // ---- Shared layout -----------------------------------------------------

  List<Widget> _section(String name, List<Widget> cells) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
      GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: cells,
      ),
      const SizedBox(height: 18),
    ];
  }

  Widget _results(List<Widget> cells) {
    if (cells.isEmpty) {
      return Center(
        child: Text(
          'No results',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      crossAxisCount: 6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: cells,
    );
  }
}

/// The "Icon | Emoji" pill toggle shown in the app bar.
class _SegToggle extends StatelessWidget {
  const _SegToggle({required this.tab, required this.onChanged});

  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(context, 'Icon', 0),
          _seg(context, 'Emoji', 1),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, int value) {
    final cs = Theme.of(context).colorScheme;
    final selected = tab == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

/// A single grid cell: rounded square, highlighted with a border when selected.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: cs.onSurface, width: 1.6) : null,
        ),
        child: child,
      ),
    );
  }
}
