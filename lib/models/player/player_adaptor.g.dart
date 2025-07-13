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
        speed: fields[0] != null ? fields[0] as double : 1.0,
        resizeMode: fields[1] != null ? fields[1] as String : "Contain",
        subtitleSize: fields[3] != null ? fields[3] as int : 16,
        subtitleColor: fields[4] != null ? fields[4] as String : "White",
        subtitleFont: fields[5] != null ? fields[5] as String : "Poppins",
        subtitleBackgroundColor:
            fields[6] != null ? fields[6] as String : "Black",
        subtitleOutlineColor: fields[7] != null ? fields[7] as String : "Black",
        showSubtitle: fields[2] != null ? fields[2] as bool : true,
        skipDuration: fields[8] != null ? fields[8] as int : 85,
        seekDuration: fields[9] != null ? fields[9] as int : 10,
        bottomMargin: fields[10] != null ? fields[10] as double : 5.0,
        transculentControls: fields[11] != null ? fields[11] as bool : false,
        playerStyle: fields[13] != null ? fields[13] as int : 0,
        defaultPortraitMode: fields[12] != null ? fields[12] as bool : false,
        subtitleOutlineWidth: fields[14] != null ? fields[14] as int : 1,
        autoSkipOP: fields[15] ?? false,
        autoSkipED: fields[16] ?? false,
        autoSkipOnce: fields[17] ?? false,
        enableSwipeControls: fields[18] ?? true,
        markAsCompleted: fields[19] ?? 90);
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(20)
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
      ..write(obj.playerStyle)
      ..writeByte(14)
      ..write(obj.subtitleOutlineWidth)
      ..writeByte(15)
      ..write(obj.autoSkipOP)
      ..writeByte(16)
      ..write(obj.autoSkipED)
      ..writeByte(17)
      ..write(obj.autoSkipOnce)
      ..writeByte(18)
      ..write(obj.enableSwipeControls)
      ..writeByte(19)
      ..write(obj.markAsCompleted);
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
