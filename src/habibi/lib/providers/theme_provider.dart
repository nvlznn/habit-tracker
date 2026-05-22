import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Holds the chosen theme (System / Light / Dark) and remembers it across
/// launches.
///
/// The preference lives in a small untyped Hive box (`settings`) so it survives
/// app restarts — same persistence approach as the rest of the app. We store the
/// mode as a short string ('system' / 'light' / 'dark') because Hive can't save
/// the [ThemeMode] enum directly.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._box)
      : _mode = _decode(_box.get(_key, defaultValue: 'dark') as String);

  static const _key = 'themeMode';

  final Box _box;
  ThemeMode _mode;

  ThemeMode get themeMode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    await _box.put(_key, _encode(mode));
    notifyListeners();
  }

  static ThemeMode _decode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark; // the app's original look
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
