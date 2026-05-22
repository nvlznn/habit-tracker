import 'package:flutter/foundation.dart';

import '../data/social_repository.dart';
import '../models/challenge.dart';
import '../models/friend.dart';
import '../utils/challenge_lifecycle.dart';
import '../utils/date_key.dart';

/// Exposes friends + shared challenges to the UI. Delegates storage to a
/// [SocialRepository] so the same provider works for the local demo or Firebase.
class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider(this._repo) {
    _runLifecycle();
  }

  final SocialRepository _repo;

  List<Friend> get friends => _repo.friends();
  List<Challenge> get challenges => _repo.challenges();
  Challenge? byId(String id) => _repo.challengeById(id);

  /// Challenges still running that [myId] is still part of.
  List<Challenge> activeForMe(String myId) => _repo
      .challenges()
      .where((c) => c.status == ChallengeStatus.active && !c.isDropped(myId))
      .toList();

  /// Ended challenges, plus ones [myId] was dropped from — the "graveyard".
  List<Challenge> graveyardForMe(String myId) => _repo
      .challenges()
      .where((c) => c.status == ChallengeStatus.ended || c.isDropped(myId))
      .toList();

  /// Re-applies the lifecycle rules (e.g. after the demo clock advances).
  Future<void> refresh() async {
    _runLifecycle();
    notifyListeners();
  }

  /// Evaluates every challenge against "today" and persists any drops/endings.
  /// Mutations happen in place, so in-memory state updates immediately; the
  /// repository writes are best-effort persistence.
  void _runLifecycle() {
    final today = simulatedTodayEpochDay();
    for (final c in _repo.challenges()) {
      if (evaluateChallenge(c, today)) {
        _repo.updateChallenge(c);
      }
    }
  }

  Future<Friend> addFriend({required String displayName, String? email}) async {
    final friend = await _repo.addFriend(displayName: displayName, email: email);
    notifyListeners();
    return friend;
  }

  Future<void> removeFriend(String id) async {
    await _repo.removeFriend(id);
    notifyListeners();
  }

  Future<Challenge> createChallenge({
    required String name,
    required String description,
    required int colorValue,
    required int iconCodePoint,
    required List<String> participantIds,
  }) async {
    final challenge = await _repo.createChallenge(
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      participantIds: participantIds,
    );
    notifyListeners();
    return challenge;
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _repo.updateChallenge(challenge);
    notifyListeners();
  }

  Future<void> toggleDay(
      String challengeId, String participantId, String dateKey) async {
    await _repo.toggleDay(challengeId, participantId, dateKey);
    _runLifecycle();
    notifyListeners();
  }

  Future<void> deleteChallenge(String id) async {
    await _repo.deleteChallenge(id);
    notifyListeners();
  }
}
