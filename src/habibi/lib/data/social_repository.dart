import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/challenge.dart';
import '../models/friend.dart';
import '../utils/date_key.dart';

/// Friends + shared challenges. Swap [LocalSocialRepository] for a
/// `FirebaseSocialRepository` (same methods) to make challenges sync between two
/// real phones without touching the providers or UI.
abstract class SocialRepository {
  List<Friend> friends();
  Future<Friend> addFriend({required String displayName, String? email});
  Future<void> removeFriend(String id);

  List<Challenge> challenges();
  Challenge? challengeById(String id);
  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    required List<String> participantIds,
  });
  Future<void> updateChallenge(Challenge challenge);
  Future<void> toggleDay(String challengeId, String participantId, String dateKey);
  Future<void> deleteChallenge(String id);
}

/// Demo implementation backed by two Hive boxes.
class LocalSocialRepository implements SocialRepository {
  LocalSocialRepository(this._friendsBox, this._challengesBox);

  final Box<Friend> _friendsBox;
  final Box<Challenge> _challengesBox;
  final _uuid = const Uuid();

  @override
  List<Friend> friends() {
    final list = _friendsBox.values.toList();
    list.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  @override
  Future<Friend> addFriend({required String displayName, String? email}) async {
    final friend =
        Friend(id: _uuid.v4(), displayName: displayName, email: email);
    await _friendsBox.put(friend.id, friend);
    return friend;
  }

  @override
  Future<void> removeFriend(String id) => _friendsBox.delete(id);

  @override
  List<Challenge> challenges() {
    final list = _challengesBox.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Challenge? challengeById(String id) => _challengesBox.get(id);

  @override
  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    required List<String> participantIds,
  }) async {
    final challenge = Challenge(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      participantIds: participantIds,
      checkins: {for (final p in participantIds) p: <String>{}},
      // Stamp the birthday on the demo clock so a challenge created while the
      // simulated clock is advanced starts its 7-day timers from "today", not
      // from the real date (which would make it instantly overdue). 0 in
      // normal use, so this is just DateTime.now() for real users.
      createdAt: DateTime.now().add(Duration(days: demoDayOffset)),
    );
    await _challengesBox.put(challenge.id, challenge);
    return challenge;
  }

  @override
  Future<void> updateChallenge(Challenge challenge) =>
      _challengesBox.put(challenge.id, challenge);

  @override
  Future<void> toggleDay(
      String challengeId, String participantId, String dateKey) async {
    final challenge = _challengesBox.get(challengeId);
    if (challenge == null) return;
    final days = challenge.checkins.putIfAbsent(participantId, () => <String>{});
    if (days.contains(dateKey)) {
      days.remove(dateKey);
    } else {
      days.add(dateKey);
    }
    await _challengesBox.put(challenge.id, challenge);
  }

  @override
  Future<void> deleteChallenge(String id) => _challengesBox.delete(id);
}
