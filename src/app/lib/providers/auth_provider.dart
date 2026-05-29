import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../models/user_profile.dart';

/// Exposes the signed-in account to the UI. Delegates storage to an
/// [AuthRepository] so the same provider works for the local demo or Firebase.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  UserProfile? get currentUser => _repo.currentUser();
  bool get isSignedIn => currentUser != null;

  Future<void> signIn({required String displayName, String email = ''}) async {
    await _repo.signIn(displayName: displayName, email: email);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _repo.updateProfile(profile);
    notifyListeners();
  }
}
