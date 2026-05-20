import 'package:hive/hive.dart';

/// A habit shared between participants ("me" + one or more friends). A day only
/// counts toward the shared streak when *every* participant checked in that day.
///
/// [checkins] maps a participant id -> the set of date-keys that person marked
/// done. The shared streak is computed by intersecting those sets — see
/// `mutualDays` / `mutualStreak` in `utils/streak.dart`.
class Challenge {
  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.iconCodePoint,
    required this.participantIds,
    required this.checkins,
    required this.createdAt,
  });

  final String id;
  String name;
  String description;
  int colorValue;
  int iconCodePoint;
  List<String> participantIds;
  Map<String, Set<String>> checkins;
  DateTime createdAt;

  /// Days [participantId] has marked done (empty set if they have none yet).
  Set<String> checkinsFor(String participantId) =>
      checkins[participantId] ?? <String>{};

  /// Each participant's done-days, in participant order. Drives the streak math;
  /// a participant with no entry contributes an empty set (so the streak is 0).
  Iterable<Set<String>> get allCheckins => participantIds.map(checkinsFor);

  Challenge copyWith({
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    List<String>? participantIds,
    Map<String, Set<String>>? checkins,
  }) {
    return Challenge(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      participantIds: participantIds ?? this.participantIds,
      checkins: checkins ?? this.checkins,
      createdAt: createdAt,
    );
  }
}

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 3;

  @override
  Challenge read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final description = reader.readString();
    final colorValue = reader.readInt();
    final iconCodePoint = reader.readInt();
    final participantCount = reader.readInt();
    final participantIds = <String>[
      for (var i = 0; i < participantCount; i++) reader.readString(),
    ];
    final mapCount = reader.readInt();
    final checkins = <String, Set<String>>{};
    for (var i = 0; i < mapCount; i++) {
      final participantId = reader.readString();
      final keyCount = reader.readInt();
      checkins[participantId] = <String>{
        for (var j = 0; j < keyCount; j++) reader.readString(),
      };
    }
    final createdAtMs = reader.readInt();
    return Challenge(
      id: id,
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      participantIds: participantIds,
      checkins: checkins,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeInt(obj.colorValue);
    writer.writeInt(obj.iconCodePoint);
    writer.writeInt(obj.participantIds.length);
    for (final p in obj.participantIds) {
      writer.writeString(p);
    }
    writer.writeInt(obj.checkins.length);
    obj.checkins.forEach((participantId, keys) {
      writer.writeString(participantId);
      writer.writeInt(keys.length);
      for (final k in keys) {
        writer.writeString(k);
      }
    });
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
