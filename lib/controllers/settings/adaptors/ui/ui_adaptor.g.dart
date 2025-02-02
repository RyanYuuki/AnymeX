// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_adaptor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UISettingsAdapter extends TypeAdapter<UISettings> {
  @override
  final int typeId = 4;

  @override
  UISettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UISettings(
        glowMultiplier: fields[0] as double? ?? 1.0,
        radiusMultiplier: fields[1] as double? ?? 1.0,
        saikouLayout: fields[2] as bool? ?? false,
        tabBarHeight: fields[3] as double? ?? 50.0,
        tabBarWidth: fields[4] as double? ?? 180.0,
        tabBarRoundness: fields[5] as double? ?? 10.0,
        compactCards: fields[6] as bool? ?? false,
        cardRoundness: fields[7] as double? ?? 1.0,
        blurMultipler: fields[8] as double? ?? 1.0,
        animationDuration: fields[9] as int? ?? 200,
        translucentTabBar: fields[10] as bool? ?? true,
        glowDensity: fields[11] as double? ?? 0.3,
        homePageCards: (fields[12] as Map?)?.cast<String, bool>() ??
            {
              "Currently Watching": true,
              "Currently Reading": true,
            },
        enableAnimation: fields[13] as bool? ?? true);
  }

  @override
  void write(BinaryWriter writer, UISettings obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.glowMultiplier)
      ..writeByte(1)
      ..write(obj.radiusMultiplier)
      ..writeByte(2)
      ..write(obj.saikouLayout)
      ..writeByte(3)
      ..write(obj.tabBarHeight)
      ..writeByte(4)
      ..write(obj.tabBarWidth)
      ..writeByte(5)
      ..write(obj.tabBarRoundness)
      ..writeByte(6)
      ..write(obj.compactCards)
      ..writeByte(7)
      ..write(obj.cardRoundness)
      ..writeByte(8)
      ..write(obj.blurMultipler)
      ..writeByte(9)
      ..write(obj.animationDuration)
      ..writeByte(10)
      ..write(obj.translucentTabBar)
      ..writeByte(11)
      ..write(obj.glowDensity)
      ..writeByte(12)
      ..write(obj.homePageCards)
      ..writeByte(13)
      ..write(obj.enableAnimation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UISettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
