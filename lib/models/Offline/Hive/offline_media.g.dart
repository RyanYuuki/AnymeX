// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineMediaAdapter extends TypeAdapter<OfflineMedia> {
  @override
  final int typeId = 7;

  @override
  OfflineMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineMedia(
      id: fields[0] as String?,
      jname: fields[1] as String?,
      name: fields[2] as String?,
      english: fields[3] as String?,
      japanese: fields[4] as String?,
      description: fields[5] as String?,
      poster: fields[6] as String?,
      cover: fields[7] as String?,
      totalEpisodes: fields[8] as String?,
      type: fields[9] as String?,
      season: fields[10] as String?,
      premiered: fields[11] as String?,
      duration: fields[12] as String?,
      status: fields[13] as String?,
      rating: fields[14] as String?,
      popularity: fields[15] as String?,
      format: fields[16] as String?,
      aired: fields[17] as String?,
      totalChapters: fields[18] as String?,
      genres: (fields[19] as List?)?.cast<String>(),
      studios: (fields[20] as List?)?.cast<String>(),
      chapters: (fields[21] as List?)?.cast<Chapter>(),
      episodes: (fields[22] as List?)?.cast<Episode>(),
      currentEpisode: fields[23] as Episode?,
      currentChapter: fields[24] as Chapter?,
      watchedEpisodes: (fields[25] as List?)?.cast<Episode>(),
      readChapters: (fields[26] as List?)?.cast<Chapter>(),
      serviceIndex: (fields[27] as int),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineMedia obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jname)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.english)
      ..writeByte(4)
      ..write(obj.japanese)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.poster)
      ..writeByte(7)
      ..write(obj.cover)
      ..writeByte(8)
      ..write(obj.totalEpisodes)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.season)
      ..writeByte(11)
      ..write(obj.premiered)
      ..writeByte(12)
      ..write(obj.duration)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.rating)
      ..writeByte(15)
      ..write(obj.popularity)
      ..writeByte(16)
      ..write(obj.format)
      ..writeByte(17)
      ..write(obj.aired)
      ..writeByte(18)
      ..write(obj.totalChapters)
      ..writeByte(19)
      ..write(obj.genres)
      ..writeByte(20)
      ..write(obj.studios)
      ..writeByte(21)
      ..write(obj.chapters)
      ..writeByte(22)
      ..write(obj.episodes)
      ..writeByte(23)
      ..write(obj.currentEpisode)
      ..writeByte(24)
      ..write(obj.currentChapter)
      ..writeByte(25)
      ..write(obj.watchedEpisodes)
      ..writeByte(26)
      ..write(obj.readChapters)
      ..writeByte(27)
      ..write(obj.serviceIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
