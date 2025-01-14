// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChapterAdapter extends TypeAdapter<Chapter> {
  @override
  final int typeId = 6;

  @override
  Chapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chapter(
        link: fields[0] as String?,
        title: fields[1] as String?,
        releaseDate: fields[2] as String?,
        number: fields[4] as double?,
        scanlator: fields[3] as String?,
        pageNumber: fields[5] as int?,
        lastReadTime: fields[7] as int?,
        totalPages: fields[6] as int?,
        currentOffset: fields[8] as double?,
        maxOffset: fields[9] as double?,
        sourceName: fields[10] as String?);
  }

  @override
  void write(BinaryWriter writer, Chapter obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.link)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.releaseDate)
      ..writeByte(3)
      ..write(obj.scanlator)
      ..writeByte(4)
      ..write(obj.number)
      ..writeByte(5)
      ..write(obj.pageNumber)
      ..writeByte(6)
      ..write(obj.totalPages)
      ..writeByte(7)
      ..write(obj.lastReadTime)
      ..writeByte(8)
      ..write(obj.currentOffset)
      ..writeByte(9)
      ..write(obj.maxOffset)
      ..writeByte(10)
      ..write(obj.sourceName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
