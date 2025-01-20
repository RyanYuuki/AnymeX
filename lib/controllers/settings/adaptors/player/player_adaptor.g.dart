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
        speed: fields[0] != null
            ? fields[0] as double
            : 1.0, // Default to 1.0 if null
        resizeMode:
            fields[1] as String? ?? 'Cover', // Default to 'Cover' if null
        showSubtitle: fields[2] as bool? ?? true, // Default to true if null
        subtitleSize:
            fields[3] != null ? fields[3] as int : 16, // Default to 16 if null
        subtitleColor:
            fields[4] as String? ?? 'White', // Default to 'White' if null
        subtitleFont:
            fields[5] as String? ?? 'Poppins', // Default to 'Poppins' if null
        subtitleBackgroundColor:
            fields[6] as String? ?? 'Black', // Default to 'Black' if null
        subtitleOutlineColor:
            fields[7] as String? ?? 'Black', // Default to 'Black' if null
        skipDuration:
            fields[8] != null ? fields[8] as int : 85, // Default to 85 if null
        seekDuration:
            fields[9] != null ? fields[9] as int : 10, // Default to 10 if null
        bottomMargin: fields[10] != null ? fields[10] as double : 5.0,
        transculentControls: fields[11] != null ? fields[11] as bool : true);
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.transculentControls);
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
