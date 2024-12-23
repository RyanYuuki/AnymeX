// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MalToken.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResponseTokenAdapter extends TypeAdapter<ResponseToken> {
  @override
  final int typeId = 2;

  @override
  ResponseToken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResponseToken(
      tokenType: fields[0] as String,
      expiresIn: fields[1] as int,
      accessToken: fields[2] as String,
      refreshToken: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResponseToken obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tokenType)
      ..writeByte(1)
      ..write(obj.expiresIn)
      ..writeByte(2)
      ..write(obj.accessToken)
      ..writeByte(3)
      ..write(obj.refreshToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseTokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
