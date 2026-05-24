import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../utils/palette.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';

class EditHabitScreen extends StatefulWidget {
  const EditHabitScreen({super.key, this.habitId});

  final String? habitId;

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late int _colorValue;
  late int _iconCodePoint;

  bool get _isNew => widget.habitId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.habitId == null
        ? null
        : context.read<HabitProvider>().byId(widget.habitId!);
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    // ignore: deprecated_member_use
    _colorValue = existing?.colorValue ?? habitColors[7].value;
    _iconCodePoint =
        existing?.iconCodePoint ?? habitIcons[0].codePoint;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    final provider = context.read<HabitProvider>();
    if (_isNew) {
      await provider.create(
        name: name,
        description: _descCtrl.text.trim(),
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
      );
    } else {
      final existing = provider.byId(widget.habitId!);
      if (existing != null) {
        await provider.update(existing.copyWith(
          name: name,
          description: _descCtrl.text.trim(),
          colorValue: _colorValue,
          iconCodePoint: _iconCodePoint,
        ));
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_isNew) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainer,
        title: const Text('Delete habit?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<HabitProvider>().delete(widget.habitId!);
    if (!mounted) return;
    // pop edit, then pop detail
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Habit' : 'Edit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Icon'),
            const SizedBox(height: 10),
            IconPicker(
              selectedCodePoint: _iconCodePoint,
              onSelect: (cp) => setState(() => _iconCodePoint = cp),
            ),
            const SizedBox(height: 20),
            _Label('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration(context, 'e.g. read 30 minutes'),
            ),
            const SizedBox(height: 16),
            _Label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: _inputDecoration(context, 'optional'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _Label('Color'),
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
                  'Save',
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
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
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

class _Label extends StatelessWidget {
  // ignore: unused_element_parameter
  const _Label(this.text, {super.key});
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
