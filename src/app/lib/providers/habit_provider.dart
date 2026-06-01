import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';

/// Exposes solo habits to the UI. Delegates storage to a [HabitRepository] so
/// the same provider works for the local box or Firebase.
class HabitProvider extends ChangeNotifier {
  HabitProvider(this._repo) {
    // Rebuild when the data changes underneath us — e.g. a Firestore snapshot
    // arrives or auth switches users. (No-op for the local box, whose stream is
    // empty.)
    _sub = _repo.changes().listen((_) => notifyListeners());
  }

  final HabitRepository _repo;
  late final StreamSubscription<void> _sub;

  List<Habit> get habits => _repo.habits();

  Habit? byId(String id) => _repo.byId(id);

  /// Force listeners to rebuild without changing any habit data. Used when the
  /// demo clock ("add day") moves "today", so the cards re-evaluate against the
  /// new simulated date.
  void refresh() => notifyListeners();

  Future<Habit> create({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    String? emoji,
  }) async {
    final habit = await _repo.create(
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      emoji: emoji,
    );
    notifyListeners();
    return habit;
  }

  Future<void> update(Habit habit) async {
    await _repo.update(habit);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    notifyListeners();
  }

  Future<void> toggleDay(String habitId, String key) async {
    await _repo.toggleDay(habitId, key);
    notifyListeners();
  }

  bool isChecked(String habitId, String key) => _repo.isChecked(habitId, key);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
