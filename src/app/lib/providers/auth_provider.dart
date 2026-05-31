import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../models/user_profile.dart';

/// Exposes the signed-in account to the UI. Delegates storage to an
/// [AuthRepository] so the same provider works for the local demo or Firebase.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    // Rebuild the UI when the account changes underneath us — e.g. when
    // Firebase restores a saved session after a page reload. (No-op for the
    // local demo, whose stream is empty.)
    _sub = _repo.authStateChanges().listen((_) => notifyListeners());
  }

  final AuthRepository _repo;
  late final StreamSubscription<UserProfile?> _sub;

  UserProfile? get currentUser => _repo.currentUser();
  bool get isSignedIn => currentUser != null;

  /// Real Google sign-in (prod). No-arg — name/email/photo come from Google.
  Future<void> signInWithGoogle() async {
    await _repo.signInWithGoogle();
    notifyListeners();
  }

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

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
