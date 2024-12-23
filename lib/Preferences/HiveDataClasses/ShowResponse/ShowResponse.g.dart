// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ShowResponse.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShowResponseAdapter extends TypeAdapter<ShowResponse> {
  @override
  final int typeId = 0;

  @override
  ShowResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShowResponse(
      name: fields[0] as String,
      link: fields[1] as String,
      coverUrl: fields[2] as String,
      otherNames: (fields[3] as List).cast<String>(),
      total: fields[4] as int?,
      extra: (fields[5] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ShowResponse obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.link)
      ..writeByte(2)
      ..write(obj.coverUrl)
      ..writeByte(3)
      ..write(obj.otherNames)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.extra);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
