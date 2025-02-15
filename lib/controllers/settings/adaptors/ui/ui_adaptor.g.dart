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
      glowMultiplier: fields[0] as double,
      radiusMultiplier: fields[1] as double,
      saikouLayout: fields[2] as bool,
      tabBarHeight: fields[3] as double,
      tabBarWidth: fields[4] as double,
      tabBarRoundness: fields[5] as double,
      compactCards: fields[6] as bool,
      cardRoundness: fields[7] as double,
      blurMultipler: fields[8] as double,
      animationDuration: fields[9] as int,
      glowDensity: fields[11] as double,
      translucentTabBar: fields[10] as bool,
      homePageCards: (fields[12] as Map).cast<String, bool>(),
      enableAnimation: fields[13] as bool,
      disableGradient: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UISettings obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.enableAnimation)
      ..writeByte(14)
      ..write(obj.disableGradient);
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
