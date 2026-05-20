import 'package:flutter/foundation.dart';

import '../data/social_repository.dart';
import '../models/challenge.dart';
import '../models/friend.dart';

/// Exposes friends + shared challenges to the UI. Delegates storage to a
/// [SocialRepository] so the same provider works for the local demo or Firebase.
class ChallengeProvider extends ChangeNotifier {
  ChallengeProvider(this._repo);

  final SocialRepository _repo;

  List<Friend> get friends => _repo.friends();
  List<Challenge> get challenges => _repo.challenges();
  Challenge? byId(String id) => _repo.challengeById(id);

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
    notifyListeners();
  }

  Future<void> deleteChallenge(String id) async {
    await _repo.deleteChallenge(id);
    notifyListeners();
  }
}
