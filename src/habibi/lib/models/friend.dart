import 'package:hive/hive.dart';

/// Another person you can share a challenge with. In the local demo friends are
/// added by hand (including a one-tap "demo friend"); later they'll come from
/// the cloud. A friend's [id] is used as a participant id inside a [Challenge].
class Friend {
  Friend({
    required this.id,
    required this.displayName,
    this.email,
  });

  final String id;
  String displayName;
  String? email;
}

class FriendAdapter extends TypeAdapter<Friend> {
  @override
  final int typeId = 2;

  @override
  Friend read(BinaryReader reader) {
    final id = reader.readString();
    final displayName = reader.readString();
    final hasEmail = reader.readBool();
    final email = hasEmail ? reader.readString() : null;
    return Friend(id: id, displayName: displayName, email: email);
  }

  @override
  void write(BinaryWriter writer, Friend obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.displayName);
    writer.writeBool(obj.email != null);
    if (obj.email != null) {
      writer.writeString(obj.email!);
    }
  }
}
