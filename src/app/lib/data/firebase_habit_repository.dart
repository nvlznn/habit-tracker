import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../models/habit.dart';
import 'habit_repository.dart';

/// Cloud-backed habits, stored per user at `users/{uid}/habits/{id}`. This is
/// the prod swap for [LocalHabitRepository] — same interface, so [HabitProvider]
/// and every habit screen are untouched.
///
/// Offline-first by design:
///   * **Signed out** — reads/writes go to the on-device Hive box (via a wrapped
///     [LocalHabitRepository]), so habits always work without an account.
///   * **Signed in** — reads/writes go to the user's cloud collection, which
///     syncs across their devices.
///   * **On first sign-in (per device)** — any habits sitting only in the local
///     box are pushed up to the cloud once (see [_maybeMigrateLocal]), so the
///     transition from offline to signed-in loses nothing.
///
/// Firestore reads are async, but the [HabitRepository] getters are
/// synchronous, so the signed-in path keeps an in-memory cache that a snapshot
/// listener keeps fresh, and pushes a [changes] event whenever it updates. It
/// follows the signed-in user via [FirebaseAuth.authStateChanges].
class FirebaseHabitRepository implements HabitRepository {
  FirebaseHabitRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Box<Habit>? localBox,
    Box? migrationFlags,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _local = localBox == null ? null : LocalHabitRepository(localBox),
        _migrationFlags = migrationFlags {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // The on-device store. Used directly while signed out, and as the source for
  // the one-time "push my local habits to the cloud" migration on first
  // sign-in. Null disables the local fallback (and migration).
  final LocalHabitRepository? _local;
  final Box? _migrationFlags;

  late final StreamSubscription<User?> _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _habitsSub;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  // In-memory cache of the signed-in user's cloud habits, kept fresh by the
  // snapshot listener below; the synchronous getters read from this.
  final Map<String, Habit> _habits = <String, Habit>{};

  String? _uid;
  // Guards the one-shot migration check so it runs only on the first snapshot
  // after a sign-in, not on every later snapshot.
  bool _migrationChecked = false;

  @override
  Stream<void> changes() => _changes.stream;

  /// Tear down all listeners. The app keeps one instance for its whole life, so
  /// this isn't called today, but it keeps the resource ownership honest.
  void dispose() {
    _authSub.cancel();
    _habitsSub?.cancel();
    _changes.close();
  }

  // ---- Auth-driven (re)subscription ----------------------------------------
  // On sign-in, point the listener at the new user's habits; on sign-out, drop
  // the cloud cache (the UI then falls back to the local box). Each snapshot
  // refreshes the cache and pushes a [changes] tick.
  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _uid) return;
    _uid = uid;

    _habitsSub?.cancel();
    _habits.clear();
    _migrationChecked = false;

    if (uid == null) {
      _changes.add(null); // signed out — UI falls back to the local box
      return;
    }

    _habitsSub = _coll().snapshots().listen((snap) {
      _habits
        ..clear()
        ..addEntries(
            snap.docs.map((d) => MapEntry(d.id, _habitFromMap(d.id, d.data()))));
      _changes.add(null);

      // First snapshot for this user decides whether to migrate local habits.
      if (!_migrationChecked) {
        _migrationChecked = true;
        _maybeMigrateLocal(uid, cloudWasEmpty: snap.docs.isEmpty);
      }
    });
  }

  // ---- One-time local→cloud migration --------------------------------------
  // The first time a user signs in on this device, copy any habits that only
  // exist in the local Hive box up to their cloud collection, preserving ids.
  // Guarded by a persisted per-uid flag so it never runs twice (so habits the
  // user later deletes in the cloud don't get resurrected), and skipped if the
  // cloud already has habits (the cloud wins on an already-synced device).
  Future<void> _maybeMigrateLocal(String uid,
      {required bool cloudWasEmpty}) async {
    final local = _local;
    final flags = _migrationFlags;
    if (local == null || flags == null) return;

    final flagKey = 'habits_migrated_$uid';
    if (flags.get(flagKey) == true) return;
    await flags.put(flagKey, true); // one-shot, whatever the outcome

    if (!cloudWasEmpty) return; // already-synced device — leave the cloud alone
    final locals = local.habits();
    if (locals.isEmpty) return;

    final coll = _coll();
    for (final habit in locals) {
      await coll.doc(habit.id).set(_habitToMap(habit));
    }
  }

  // ---- Reads ---------------------------------------------------------------
  // Signed out → read the local box; signed in → read the cloud cache.
  @override
  List<Habit> habits() {
    if (_uid == null) return _local?.habits() ?? const <Habit>[];
    final list = _habits.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Habit? byId(String id) =>
      _uid == null ? _local?.byId(id) : _habits[id];

  @override
  bool isChecked(String habitId, String key) => _uid == null
      ? (_local?.isChecked(habitId, key) ?? false)
      : (_habits[habitId]?.dateKeys.contains(key) ?? false);

  // ---- Writes --------------------------------------------------------------
  // Signed out → write the local box; signed in → write the cloud.
  @override
  Future<Habit> create({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    String? emoji,
  }) async {
    if (_uid == null) {
      final local = _local;
      if (local == null) {
        throw StateError('No local store available and not signed in.');
      }
      return local.create(
        name: name,
        description: description,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
        emoji: emoji,
      );
    }
    final doc = _coll().doc();
    final habit = Habit(
      id: doc.id,
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      emoji: emoji,
      dateKeys: <String>{},
      createdAt: DateTime.now(),
    );
    await doc.set(_habitToMap(habit));
    return habit;
  }

  @override
  Future<void> update(Habit habit) async {
    if (_uid == null) {
      await _local?.update(habit);
      return;
    }
    await _coll().doc(habit.id).set(_habitToMap(habit));
  }

  @override
  Future<void> delete(String id) async {
    if (_uid == null) {
      await _local?.delete(id);
      return;
    }
    await _coll().doc(id).delete();
  }

  @override
  Future<void> toggleDay(String habitId, String key) async {
    if (_uid == null) {
      await _local?.toggleDay(habitId, key);
      return;
    }
    final habit = _habits[habitId];
    if (habit == null) return;
    if (habit.dateKeys.contains(key)) {
      habit.dateKeys.remove(key);
    } else {
      habit.dateKeys.add(key);
    }
    await update(habit);
  }

  // ---- Helpers -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _coll() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in — cannot access cloud habits.');
    }
    return _db.collection('users').doc(uid).collection('habits');
  }

  Map<String, dynamic> _habitToMap(Habit h) => {
        'name': h.name,
        'description': h.description,
        'colorValue': h.colorValue,
        'iconCodePoint': h.iconCodePoint,
        'emoji': h.emoji,
        // Firestore has no Set type, so store the checked days as a list.
        'dateKeys': h.dateKeys.toList(),
        'createdAt': h.createdAt.millisecondsSinceEpoch,
      };

  Habit _habitFromMap(String id, Map<String, dynamic> m) => Habit(
        id: id,
        name: (m['name'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        colorValue: (m['colorValue'] as num).toInt(),
        iconCodePoint: (m['iconCodePoint'] as num).toInt(),
        emoji: m['emoji'] as String?,
        dateKeys: {
          for (final k in (m['dateKeys'] as List? ?? const [])) k as String,
        },
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
      );
}
