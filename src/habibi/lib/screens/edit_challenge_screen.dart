import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../utils/palette.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';

/// Create a new challenge: pick details + one friend to share it with.
/// (Built for two people now; participantIds is a list so more can be added.)
class EditChallengeScreen extends StatefulWidget {
  const EditChallengeScreen({super.key});

  @override
  State<EditChallengeScreen> createState() => _EditChallengeScreenState();
}

class _EditChallengeScreenState extends State<EditChallengeScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  int _colorValue = habitColors[5].toARGB32();
  int _iconCodePoint = habitIcons[0].codePoint;
  String? _friendId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    final friends = context.read<ChallengeProvider>().friends;
    if (friends.isNotEmpty) _friendId = friends.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Name cannot be empty');
      return;
    }
    if (_friendId == null) {
      _snack('Pick a friend to challenge');
      return;
    }
    final me = context.read<AuthProvider>().currentUser;
    if (me == null) {
      _snack('Sign in first');
      return;
    }
    await context.read<ChallengeProvider>().createChallenge(
          name: name,
          description: _descCtrl.text.trim(),
          colorValue: _colorValue,
          iconCodePoint: _iconCodePoint,
          participantIds: [me.id, _friendId!],
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<ChallengeProvider>().friends;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Challenge with'),
            const SizedBox(height: 10),
            _FriendSelector(
              friends: friends,
              selectedId: _friendId,
              onSelect: (id) => setState(() => _friendId = id),
            ),
            const SizedBox(height: 20),
            const _Label('Icon'),
            const SizedBox(height: 10),
            IconPicker(
              selectedCodePoint: _iconCodePoint,
              onSelect: (cp) => setState(() => _iconCodePoint = cp),
            ),
            const SizedBox(height: 20),
            const _Label('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration(context, 'e.g. gym every day'),
            ),
            const SizedBox(height: 16),
            const _Label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: _inputDecoration(context, 'optional'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const _Label('Color'),
            const SizedBox(height: 10),
            ColorPicker(
              selectedValue: _colorValue,
              onSelect: (v) => setState(() => _colorValue = v),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_colorValue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _FriendSelector extends StatelessWidget {
  const _FriendSelector({
    required this.friends,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Friend> friends;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Text(
        'No friends yet — add one in the Friends tab first.',
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in friends)
          ChoiceChip(
            label: Text(f.displayName),
            selected: f.id == selectedId,
            onSelected: (_) => onSelect(f.id),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
