import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider(this._box);

  final Box<Habit> _box;
  final _uuid = const Uuid();

  List<Habit> get habits {
    final list = _box.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Habit? byId(String id) => _box.get(id);

  /// Force listeners to rebuild without changing any habit data. Used when the
  /// demo clock ("add day") moves "today", so the cards re-evaluate against the
  /// new simulated date.
  void refresh() => notifyListeners();

  Future<Habit> create({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      dateKeys: <String>{},
      createdAt: DateTime.now(),
    );
    await _box.put(habit.id, habit);
    notifyListeners();
    return habit;
  }

  Future<void> update(Habit habit) async {
    await _box.put(habit.id, habit);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> toggleDay(String habitId, String key) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    if (habit.dateKeys.contains(key)) {
      habit.dateKeys.remove(key);
    } else {
      habit.dateKeys.add(key);
    }
    await _box.put(habit.id, habit);
    notifyListeners();
  }

  bool isChecked(String habitId, String key) {
    return _box.get(habitId)?.dateKeys.contains(key) ?? false;
  }
}
