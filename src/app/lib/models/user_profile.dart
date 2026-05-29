import 'package:hive/hive.dart';

/// The signed-in account. In the local demo this is created by a placeholder
/// "sign in" flow; later it will be filled from real Google sign-in. The same
/// shape works for both, so swapping in Firebase touches nothing here.
class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String id;
  String displayName;
  String email;
  String? photoUrl;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    final id = reader.readString();
    final displayName = reader.readString();
    final email = reader.readString();
    final hasPhoto = reader.readBool();
    final photoUrl = hasPhoto ? reader.readString() : null;
    return UserProfile(
      id: id,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.displayName);
    writer.writeString(obj.email);
    writer.writeBool(obj.photoUrl != null);
    if (obj.photoUrl != null) {
      writer.writeString(obj.photoUrl!);
    }
  }
}
