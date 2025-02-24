// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_adaptor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerSettingsAdapter extends TypeAdapter<PlayerSettings> {
  @override
  final int typeId = 03;

  @override
  PlayerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerSettings(
      speed: fields[0] as double? ?? 1.0,
      resizeMode: fields[1] as String? ?? "Contain",
      subtitleSize: fields[3] as int? ?? 16,
      subtitleColor: fields[4] as String? ?? "White",
      subtitleFont: fields[5] as String? ?? "Poppins",
      subtitleBackgroundColor: fields[6] as String? ?? "Black",
      subtitleOutlineColor: fields[7] as String? ?? "Black",
      showSubtitle: fields[2] as bool? ?? true,
      skipDuration: fields[8] as int? ?? 85,
      seekDuration: fields[9] as int? ?? 10,
      bottomMargin: fields[10] as double? ?? 5.0,
      transculentControls: fields[11] as bool? ?? false,
      playerStyle: fields[13] as int? ?? 0,
      defaultPortraitMode: fields[12] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.skipDuration)
      ..writeByte(9)
      ..write(obj.seekDuration)
      ..writeByte(10)
      ..write(obj.bottomMargin)
      ..writeByte(11)
      ..write(obj.transculentControls)
      ..writeByte(12)
      ..write(obj.defaultPortraitMode)
      ..writeByte(13)
      ..write(obj.playerStyle);
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
