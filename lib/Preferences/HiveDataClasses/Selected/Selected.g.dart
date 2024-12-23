// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Selected.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelectedAdapter extends TypeAdapter<Selected> {
  @override
  final int typeId = 1;

  @override
  Selected read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Selected(
      window: fields[0] as int,
      recyclerStyle: fields[1] as int?,
      recyclerReversed: fields[2] as bool,
      chip: fields[3] as int,
      sourceIndex: fields[4] as int,
      langIndex: fields[5] as int,
      preferDub: fields[6] as bool,
      server: fields[7] as String?,
      video: fields[8] as int,
      latest: fields[9] as double,
      scanlators: (fields[10] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Selected obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.window)
      ..writeByte(1)
      ..write(obj.recyclerStyle)
      ..writeByte(2)
      ..write(obj.recyclerReversed)
      ..writeByte(3)
      ..write(obj.chip)
      ..writeByte(4)
      ..write(obj.sourceIndex)
      ..writeByte(5)
      ..write(obj.langIndex)
      ..writeByte(6)
      ..write(obj.preferDub)
      ..writeByte(7)
      ..write(obj.server)
      ..writeByte(8)
      ..write(obj.video)
      ..writeByte(9)
      ..write(obj.latest)
      ..writeByte(10)
      ..write(obj.scanlators);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
