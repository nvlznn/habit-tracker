import 'package:hive/hive.dart';

/// Sentinel so [Habit.copyWith] can tell "leave emoji unchanged" apart from
/// "set emoji to null" (clearing an emoji back to a plain icon).
const Object _undefined = Object();

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.iconCodePoint,
    required this.dateKeys,
    required this.createdAt,
    this.emoji,
  });

  final String id;
  String name;
  String description;
  int colorValue;
  int iconCodePoint;

  /// When set, this emoji is shown instead of the Material icon. Null = use the
  /// icon (the default).
  String? emoji;

  Set<String> dateKeys;
  DateTime createdAt;

  Habit copyWith({
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    Object? emoji = _undefined,
    Set<String>? dateKeys,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      emoji: identical(emoji, _undefined) ? this.emoji : emoji as String?,
      dateKeys: dateKeys ?? this.dateKeys,
      createdAt: createdAt,
    );
  }
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final description = reader.readString();
    final colorValue = reader.readInt();
    final iconCodePoint = reader.readInt();
    final keyCount = reader.readInt();
    final keys = <String>{
      for (var i = 0; i < keyCount; i++) reader.readString(),
    };
    final createdAtMs = reader.readInt();

    // emoji was added later — older records have no bytes left here.
    String? emoji;
    if (reader.availableBytes > 0) {
      emoji = reader.readBool() ? reader.readString() : null;
    }

    return Habit(
      id: id,
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      dateKeys: keys,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      emoji: emoji,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeInt(obj.colorValue);
    writer.writeInt(obj.iconCodePoint);
    writer.writeInt(obj.dateKeys.length);
    for (final k in obj.dateKeys) {
      writer.writeString(k);
    }
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    // Newer field (see read()'s availableBytes guard for back-compat).
    writer.writeBool(obj.emoji != null);
    if (obj.emoji != null) {
      writer.writeString(obj.emoji!);
    }
  }
}
