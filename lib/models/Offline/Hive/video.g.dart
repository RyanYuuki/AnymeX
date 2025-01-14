// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 1;

  @override
  Video read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Video(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      headers: (fields[3] as Map?)?.cast<String, String>(),
      subtitles: (fields[4] as List?)?.cast<Track>(),
      audios: (fields[5] as List?)?.cast<Track>(),
    );
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.quality)
      ..writeByte(2)
      ..write(obj.originalUrl)
      ..writeByte(3)
      ..write(obj.headers)
      ..writeByte(4)
      ..write(obj.subtitles)
      ..writeByte(5)
      ..write(obj.audios);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackAdapter extends TypeAdapter<Track> {
  @override
  final int typeId = 2;

  @override
  Track read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Track(
      file: fields[0] as String?,
      label: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Track obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.file)
      ..writeByte(1)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
