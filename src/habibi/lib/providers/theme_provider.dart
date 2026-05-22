import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Holds the chosen light/dark mode and remembers it across launches.
///
/// The preference lives in a small untyped Hive box (`settings`) so it survives
/// app restarts — same persistence approach as the rest of the app.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._box)
      : _isDark = _box.get(_key, defaultValue: true) as bool;

  static const _key = 'isDark';

  final Box _box;
  bool _isDark;

  /// Defaults to dark — that's how the app has always looked.
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => _isDark;

  Future<void> toggle() async {
    _isDark = !_isDark;
    await _box.put(_key, _isDark);
    notifyListeners();
  }
}
