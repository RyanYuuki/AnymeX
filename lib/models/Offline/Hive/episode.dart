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
}
