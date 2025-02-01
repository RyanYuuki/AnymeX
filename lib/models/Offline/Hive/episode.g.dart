// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpisodeAdapter extends TypeAdapter<Episode> {
  @override
  final int typeId = 5;

  @override
  Episode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Episode(
        number: fields[0] as String,
        link: fields[1] as String?,
        title: fields[2] as String?,
        desc: fields[3] as String?,
        thumbnail: fields[4] as String?,
        filler: fields[5] as bool?,
        timeStampInMilliseconds: fields[6] as int?,
        durationInMilliseconds: fields[7] as int?,
        lastWatchedTime: fields[8] as int?,
        currentTrack: (fields[9] as Video?),
        videoTracks: (fields[10] as List?)?.cast<Video>(),
        source: fields[11] as String?);
  }

  @override
  void write(BinaryWriter writer, Episode obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.link)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.desc)
      ..writeByte(4)
      ..write(obj.thumbnail)
      ..writeByte(5)
      ..write(obj.filler)
      ..writeByte(6)
      ..write(obj.timeStampInMilliseconds)
      ..writeByte(7)
      ..write(obj.durationInMilliseconds)
      ..writeByte(8)
      ..write(obj.lastWatchedTime)
      ..writeByte(9)
      ..write(obj.currentTrack)
      ..writeByte(10)
      ..write(obj.videoTracks)
      ..writeByte(11)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
