import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';

/// Solo habits + their checked days. Swap [LocalHabitRepository] for a
/// `FirebaseHabitRepository` (same methods) to make a user's habits sync across
/// their devices without touching [HabitProvider] or any screen.
abstract class HabitRepository {
  List<Habit> habits();
  Habit? byId(String id);
  Future<Habit> create({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    String? emoji,
  });
  Future<void> update(Habit habit);
  Future<void> delete(String id);
  Future<void> toggleDay(String habitId, String key);
  bool isChecked(String habitId, String key);

  /// Emits when the data changes underneath us — e.g. a Firestore snapshot
  /// arrives, or auth switches users. Lets the provider rebuild on async cloud
  /// updates. The local box mutates synchronously and has nothing to push, so
  /// it returns an empty stream.
  Stream<void> changes();
}

/// Demo / on-device implementation backed by a single Hive box.
class LocalHabitRepository implements HabitRepository {
  LocalHabitRepository(this._box);

  final Box<Habit> _box;
  final _uuid = const Uuid();

  @override
  List<Habit> habits() {
    final list = _box.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Habit? byId(String id) => _box.get(id);

  @override
  Future<Habit> create({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    String? emoji,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      emoji: emoji,
      dateKeys: <String>{},
      createdAt: DateTime.now(),
    );
    await _box.put(habit.id, habit);
    return habit;
  }

  @override
  Future<void> update(Habit habit) => _box.put(habit.id, habit);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> toggleDay(String habitId, String key) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    if (habit.dateKeys.contains(key)) {
      habit.dateKeys.remove(key);
    } else {
      habit.dateKeys.add(key);
    }
    await _box.put(habit.id, habit);
  }

  @override
  bool isChecked(String habitId, String key) =>
      _box.get(habitId)?.dateKeys.contains(key) ?? false;

  // Hive mutations are synchronous and the provider already notifies after each
  // call, so there's nothing async to push here.
  @override
  Stream<void> changes() => const Stream.empty();
}
