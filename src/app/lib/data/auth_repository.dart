import 'dart:async';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';

/// Where the account comes from. Swap [LocalAuthRepository] for a
/// `FirebaseAuthRepository` (same methods) to go from demo to real Google
/// sign-in without touching the providers or UI.
abstract class AuthRepository {
  UserProfile? currentUser();

  /// Real Google sign-in. Returns the signed-in profile, or null if the user
  /// cancelled. Used by the prod build; dev uses [signIn] instead.
  Future<UserProfile?> signInWithGoogle();

  /// The demo name-prompt sign-in. Dev-only; prod uses [signInWithGoogle].
  Future<UserProfile> signIn({required String displayName, String email});
  Future<void> signOut();
  Future<void> updateProfile(UserProfile profile);

  /// Emits when the signed-in user changes — e.g. when Firebase restores a
  /// session after a reload. The local demo has no async restore, so it returns
  /// an empty stream.
  Stream<UserProfile?> authStateChanges();
}

/// Demo implementation: stores a single profile in a Hive box under a fixed key.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._box);

  final Box<UserProfile> _box;
  final _uuid = const Uuid();

  static const String _key = 'me';

  @override
  UserProfile? currentUser() => _box.get(_key);

  // Dev never calls this (the dev UI uses the name prompt), but the interface
  // requires it — hand back a canned demo profile so it's harmless if hit.
  @override
  Future<UserProfile?> signInWithGoogle() =>
      signIn(displayName: 'Demo User', email: 'demo@gmail.com');

  @override
  Stream<UserProfile?> authStateChanges() => const Stream.empty();

  @override
  Future<UserProfile> signIn({
    required String displayName,
    String email = '',
  }) async {
    final existing = _box.get(_key);
    final profile = UserProfile(
      // Keep the same id across re-sign-ins so existing challenges still match.
      id: existing?.id ?? _uuid.v4(),
      displayName: displayName,
      email: email,
      photoUrl: existing?.photoUrl,
    );
    await _box.put(_key, profile);
    return profile;
  }

  @override
  Future<void> signOut() => _box.delete(_key);

  @override
  Future<void> updateProfile(UserProfile profile) => _box.put(_key, profile);
}
