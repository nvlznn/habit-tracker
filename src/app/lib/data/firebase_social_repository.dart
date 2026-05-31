import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/challenge.dart';
import '../models/friend.dart';
import '../utils/date_key.dart';
import 'social_repository.dart';

/// Cloud-backed friends + challenges, stored per user at
/// `users/{uid}/friends/{id}` and `users/{uid}/challenges/{id}`. This is the
/// prod swap for [LocalSocialRepository] — same interface, so the providers,
/// screens, and the mutual-streak math don't change.
///
/// Firestore reads are async, but the [SocialRepository] getters are
/// synchronous, so this keeps an in-memory cache that snapshot listeners keep
/// fresh, and pushes a [changes] event whenever it updates. It follows the
/// signed-in user via [FirebaseAuth.authStateChanges]: subscribing to that
/// user's collections on sign-in, and clearing the cache on sign-out.
///
/// Step 2 stores each user's own data (it syncs across that user's devices).
/// Sharing a single challenge between two different users is step 3 (invites).
class FirebaseSocialRepository implements SocialRepository {
  FirebaseSocialRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  late final StreamSubscription<User?> _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _challengesSub;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  // In-memory caches kept fresh by the snapshot listeners below; the
  // synchronous getters read from these.
  List<Friend> _friends = <Friend>[];
  final Map<String, Challenge> _challenges = <String, Challenge>{};

  String? _uid;

  @override
  Stream<void> changes() => _changes.stream;

  /// Tear down all listeners. The app keeps one instance for its whole life, so
  /// this isn't called today, but it keeps the resource ownership honest.
  void dispose() {
    _authSub.cancel();
    _friendsSub?.cancel();
    _challengesSub?.cancel();
    _changes.close();
  }

  // ---- Auth-driven (re)subscription ----------------------------------------
  // On sign-in, point the listeners at the new user's collections; on sign-out,
  // drop the cache. Each snapshot refreshes a cache and pushes a [changes] tick.
  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _uid) return;
    _uid = uid;

    _friendsSub?.cancel();
    _challengesSub?.cancel();
    _friends = <Friend>[];
    _challenges.clear();

    if (uid == null) {
      _changes.add(null); // signed out — UI empties out
      return;
    }

    final userDoc = _db.collection('users').doc(uid);
    _friendsSub = userDoc.collection('friends').snapshots().listen((snap) {
      _friends = snap.docs.map((d) => _friendFromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()));
      _changes.add(null);
    });
    _challengesSub = userDoc.collection('challenges').snapshots().listen((snap) {
      _challenges
        ..clear()
        ..addEntries(snap.docs
            .map((d) => MapEntry(d.id, _challengeFromMap(d.id, d.data()))));
      _changes.add(null);
    });
  }

  // ---- Reads (from cache) --------------------------------------------------
  @override
  List<Friend> friends() => _friends.toList();

  @override
  List<Challenge> challenges() {
    final list = _challenges.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Challenge? challengeById(String id) => _challenges[id];

  // ---- Writes --------------------------------------------------------------
  @override
  Future<Friend> addFriend({required String displayName, String? email}) async {
    final doc = _coll('friends').doc();
    final friend = Friend(id: doc.id, displayName: displayName, email: email);
    await doc.set(_friendToMap(friend));
    return friend;
  }

  @override
  Future<void> removeFriend(String id) async {
    if (_uid == null) return;
    await _coll('friends').doc(id).delete();
  }

  @override
  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    String? emoji,
    required List<String> participantIds,
  }) async {
    final doc = _coll('challenges').doc();
    final challenge = Challenge(
      id: doc.id,
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      emoji: emoji,
      participantIds: participantIds,
      checkins: {for (final p in participantIds) p: <String>{}},
      // demoDayOffset is 0 in prod, so this is just DateTime.now().
      createdAt: DateTime.now().add(Duration(days: demoDayOffset)),
    );
    await doc.set(_challengeToMap(challenge));
    return challenge;
  }

  @override
  Future<void> updateChallenge(Challenge challenge) async {
    if (_uid == null) return;
    await _coll('challenges').doc(challenge.id).set(_challengeToMap(challenge));
  }

  @override
  Future<void> toggleDay(
      String challengeId, String participantId, String dateKey) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) return;
    final days = challenge.checkins.putIfAbsent(participantId, () => <String>{});
    if (days.contains(dateKey)) {
      days.remove(dateKey);
    } else {
      days.add(dateKey);
    }
    await updateChallenge(challenge);
  }

  @override
  Future<void> deleteChallenge(String id) async {
    if (_uid == null) return;
    await _coll('challenges').doc(id).delete();
  }

  // ---- Helpers -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _coll(String name) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in — cannot access "$name".');
    }
    return _db.collection('users').doc(uid).collection(name);
  }

  Map<String, dynamic> _friendToMap(Friend f) => {
        'displayName': f.displayName,
        'email': f.email,
      };

  Friend _friendFromMap(String id, Map<String, dynamic> m) => Friend(
        id: id,
        displayName: (m['displayName'] as String?) ?? '',
        email: m['email'] as String?,
      );

  Map<String, dynamic> _challengeToMap(Challenge c) => {
        'name': c.name,
        'description': c.description,
        'colorValue': c.colorValue,
        'iconCodePoint': c.iconCodePoint,
        'emoji': c.emoji,
        'participantIds': c.participantIds,
        // Firestore has no Set type, so store each person's days as a list.
        'checkins': {
          for (final e in c.checkins.entries) e.key: e.value.toList(),
        },
        'createdAt': c.createdAt.millisecondsSinceEpoch,
        'status': c.status.index,
        'endedOn': c.endedOn,
        'dropped': [
          for (final d in c.dropped)
            {
              'participantId': d.participantId,
              'droppedOn': d.droppedOn,
              'daysPersisted': d.daysPersisted,
            },
        ],
      };

  Challenge _challengeFromMap(String id, Map<String, dynamic> m) {
    final rawCheckins = (m['checkins'] as Map?) ?? const {};
    final checkins = <String, Set<String>>{
      for (final e in rawCheckins.entries)
        e.key as String: {
          for (final k in (e.value as List? ?? const [])) k as String,
        },
    };
    final rawDropped = (m['dropped'] as List?) ?? const [];
    final dropped = [
      for (final d in rawDropped)
        DropRecord(
          participantId: (d as Map)['participantId'] as String,
          droppedOn: (d['droppedOn'] as num).toInt(),
          daysPersisted: (d['daysPersisted'] as num).toInt(),
        ),
    ];
    return Challenge(
      id: id,
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      colorValue: (m['colorValue'] as num).toInt(),
      iconCodePoint: (m['iconCodePoint'] as num).toInt(),
      emoji: m['emoji'] as String?,
      participantIds: [
        for (final p in (m['participantIds'] as List? ?? const [])) p as String,
      ],
      checkins: checkins,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
      status: ChallengeStatus.values[(m['status'] as num?)?.toInt() ?? 0],
      endedOn: (m['endedOn'] as num?)?.toInt(),
      dropped: dropped,
    );
  }
}
