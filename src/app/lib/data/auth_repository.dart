import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';

/// Where the account comes from. Swap [LocalAuthRepository] for a
/// `FirebaseAuthRepository` (same methods) to go from demo to real Google
/// sign-in without touching the providers or UI.
abstract class AuthRepository {
  UserProfile? currentUser();
  Future<UserProfile> signIn({required String displayName, String email});
  Future<void> signOut();
  Future<void> updateProfile(UserProfile profile);
}

/// Demo implementation: stores a single profile in a Hive box under a fixed key.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._box);

  final Box<UserProfile> _box;
  final _uuid = const Uuid();

  static const String _key = 'me';

  @override
  UserProfile? currentUser() => _box.get(_key);

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
