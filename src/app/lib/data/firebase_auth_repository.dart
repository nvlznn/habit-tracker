import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'auth_repository.dart';

/// Real Google sign-in, backed by Firebase Auth. This is the prod swap for
/// [LocalAuthRepository] — same interface, so providers and UI don't change.
///
/// On web, [signInWithGoogle] uses a popup and needs no extra packages. The
/// Android/iOS native flow (which needs `google_sign_in` + a SHA-1 fingerprint
/// registered in the Firebase console) can be added later without changing this
/// class's public surface.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  UserProfile? currentUser() => _toProfile(_auth.currentUser);

  @override
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final cred = await _auth.signInWithPopup(GoogleAuthProvider());
      return _toProfile(cred.user);
    } on FirebaseAuthException catch (e) {
      // User closed / cancelled the popup — not a real error.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-canceled') {
        return null;
      }
      rethrow;
    }
  }

  // The demo name-prompt flow is dev-only; prod always signs in with Google.
  @override
  Future<UserProfile> signIn({
    required String displayName,
    String email = '',
  }) =>
      throw UnsupportedError('Prod uses signInWithGoogle().');

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(profile.displayName);
    if (profile.photoUrl != null) {
      await user.updatePhotoURL(profile.photoUrl);
    }
  }

  @override
  Stream<UserProfile?> authStateChanges() =>
      _auth.authStateChanges().map(_toProfile);

  /// Maps a Firebase [User] to the app's [UserProfile]. The Firebase `uid` is
  /// the stable per-user id the cloud database will key everything on.
  UserProfile? _toProfile(User? user) {
    if (user == null) return null;
    return UserProfile(
      id: user.uid,
      displayName: user.displayName ?? user.email ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }
}
