// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineStorageAdapter extends TypeAdapter<OfflineStorage> {
  @override
  final int typeId = 8;

  @override
  OfflineStorage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineStorage(
      animeLibrary: (fields[0] as List?)?.cast<OfflineMedia>(),
      mangaLibrary: (fields[1] as List?)?.cast<OfflineMedia>(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineStorage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.animeLibrary)
      ..writeByte(1)
      ..write(obj.mangaLibrary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineStorageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
