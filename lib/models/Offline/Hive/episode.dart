import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:hive/hive.dart';

part 'episode.g.dart';

@HiveType(typeId: 5)
class Episode extends HiveObject {
  @HiveField(0)
  String number;

  @HiveField(1)
  String? link;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? desc;

  @HiveField(4)
  String? thumbnail;

  @HiveField(5)
  bool? filler;

  @HiveField(6)
  int? timeStampInMilliseconds;

  @HiveField(7)
  int? durationInMilliseconds;

  @HiveField(8)
  int? lastWatchedTime;

  @HiveField(9)
  Video? currentTrack;

  @HiveField(10)
  List<Video>? videoTracks;

  @HiveField(11)
  String? source;

  Episode(
      {required this.number,
      this.link,
      this.title,
      this.desc,
      this.thumbnail,
      this.filler,
      this.timeStampInMilliseconds,
      this.durationInMilliseconds,
      this.lastWatchedTime,
      this.currentTrack,
      this.videoTracks,
      this.source});

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'link': link,
      'title': title,
      'desc': desc,
      'thumbnail': thumbnail,
      'filler': filler,
      'timeStampInMilliseconds': timeStampInMilliseconds,
      'durationInMilliseconds': durationInMilliseconds,
      'lastWatchedTime': lastWatchedTime,
      'currentTrack': currentTrack?.toJson(),
      'videoTracks': videoTracks?.map((v) => v.toJson()).toList(),
      'source': source,
    };
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      number: json['number'] as String,
      link: json['link'] as String?,
      title: json['title'] as String?,
      desc: json['desc'] as String?,
      thumbnail: json['thumbnail'] as String?,
      filler: json['filler'] as bool?,
      timeStampInMilliseconds: json['timeStampInMilliseconds'] as int?,
      durationInMilliseconds: json['durationInMilliseconds'] as int?,
      lastWatchedTime: json['lastWatchedTime'] as int?,
      currentTrack: json['currentTrack'] != null
          ? Video.fromJson(json['currentTrack'] as Map<String, dynamic>)
          : null,
      videoTracks: (json['videoTracks'] as List<dynamic>?)
          ?.map((v) => Video.fromJson(v as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String?,
    );
  }
}
