// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_adaptor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerSettingsAdapter extends TypeAdapter<PlayerSettings> {
  @override
  final int typeId = 3;

  @override
  PlayerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerSettings(
      speed: fields[0] as String,
      resizeMode: fields[1] as String,
      subtitleSize: fields[3] as int,
      subtitleColor: fields[4] as int,
      subtitleFont: fields[5] as String,
      subtitleBackgroundColor: fields[6] as int,
      subtitleOutlineColor: fields[7] as int,
      showSubtitle: fields[2] as bool,
      skipDuration: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.speed)
      ..writeByte(1)
      ..write(obj.resizeMode)
      ..writeByte(2)
      ..write(obj.showSubtitle)
      ..writeByte(3)
      ..write(obj.subtitleSize)
      ..writeByte(4)
      ..write(obj.subtitleColor)
      ..writeByte(5)
      ..write(obj.subtitleFont)
      ..writeByte(6)
      ..write(obj.subtitleBackgroundColor)
      ..writeByte(7)
      ..write(obj.subtitleOutlineColor)
      ..writeByte(8)
      ..write(obj.skipDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
