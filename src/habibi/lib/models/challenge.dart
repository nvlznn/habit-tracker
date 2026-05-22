import 'package:hive/hive.dart';

import '../utils/date_key.dart';

/// Whether a challenge is still running or has permanently ended.
enum ChallengeStatus { active, ended }

/// A participant who was removed from a challenge because they stopped checking
/// in. Kept forever so the graveyard can show "you persisted N days".
class DropRecord {
  DropRecord({
    required this.participantId,
    required this.droppedOn,
    required this.daysPersisted,
  });

  final String participantId;

  /// Epoch day the participant was dropped.
  final int droppedOn;

  /// How many days they had checked in by the time they were dropped.
  final int daysPersisted;
}

/// A habit shared between participants ("me" + one or more friends). A day only
/// counts toward the shared streak when *every* active participant checked in
/// that day.
///
/// [checkins] maps a participant id -> the set of date-keys that person marked
/// done. The shared streak is computed by intersecting those sets — see
/// `mutualDays` / `mutualStreak` in `utils/streak.dart`.
///
/// Lifecycle: each participant must check in within 7 days. Whoever lapses is
/// recorded in [dropped] (while more than two remain); once only two are left
/// and one lapses, [status] becomes [ChallengeStatus.ended].
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
    this.status = ChallengeStatus.active,
    this.endedOn,
    List<DropRecord>? dropped,
  }) : dropped = dropped ?? <DropRecord>[];

  final String id;
  String name;
  String description;
  int colorValue;
  int iconCodePoint;
  List<String> participantIds;
  Map<String, Set<String>> checkins;
  DateTime createdAt;
  ChallengeStatus status;

  /// Epoch day the challenge ended, or null while it is still active.
  int? endedOn;
  List<DropRecord> dropped;

  /// Days [participantId] has marked done (empty set if they have none yet).
  Set<String> checkinsFor(String participantId) =>
      checkins[participantId] ?? <String>{};

  /// Each participant's done-days, in participant order. Drives the streak math;
  /// a participant with no entry contributes an empty set (so the streak is 0).
  Iterable<Set<String>> get allCheckins => participantIds.map(checkinsFor);

  /// The day this challenge began (epoch day).
  int get startEpochDay => epochDay(createdAt);

  bool isDropped(String participantId) =>
      dropped.any((d) => d.participantId == participantId);

  DropRecord? dropFor(String participantId) {
    for (final d in dropped) {
      if (d.participantId == participantId) return d;
    }
    return null;
  }

  /// Participants still in the challenge (not dropped).
  List<String> get activeParticipantIds =>
      participantIds.where((id) => !isDropped(id)).toList();

  /// How many days the challenge has lived: from creation to its end (or to
  /// [today] while it is still active).
  int lifespanDays(int today) => (endedOn ?? today) - startEpochDay;

  Challenge copyWith({
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    List<String>? participantIds,
    Map<String, Set<String>>? checkins,
    ChallengeStatus? status,
    int? endedOn,
    List<DropRecord>? dropped,
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
      status: status ?? this.status,
      endedOn: endedOn ?? this.endedOn,
      dropped: dropped ?? this.dropped,
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

    // Fields added later — default them for challenges saved before this
    // version, detected by there being no bytes left to read.
    var status = ChallengeStatus.active;
    int? endedOn;
    final dropped = <DropRecord>[];
    if (reader.availableBytes > 0) {
      status = ChallengeStatus.values[reader.readInt()];
      final hasEnded = reader.readBool();
      endedOn = hasEnded ? reader.readInt() : null;
      final dropCount = reader.readInt();
      for (var i = 0; i < dropCount; i++) {
        dropped.add(DropRecord(
          participantId: reader.readString(),
          droppedOn: reader.readInt(),
          daysPersisted: reader.readInt(),
        ));
      }
    }

    return Challenge(
      id: id,
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      participantIds: participantIds,
      checkins: checkins,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      status: status,
      endedOn: endedOn,
      dropped: dropped,
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
    // Newer fields (see read()'s availableBytes guard for back-compat).
    writer.writeInt(obj.status.index);
    writer.writeBool(obj.endedOn != null);
    if (obj.endedOn != null) {
      writer.writeInt(obj.endedOn!);
    }
    writer.writeInt(obj.dropped.length);
    for (final d in obj.dropped) {
      writer.writeString(d.participantId);
      writer.writeInt(d.droppedOn);
      writer.writeInt(d.daysPersisted);
    }
  }
}
