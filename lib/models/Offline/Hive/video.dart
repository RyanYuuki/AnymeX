import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart' as d;
import 'package:hive/hive.dart';

part 'video.g.dart';

@HiveType(typeId: 11)
class Video extends HiveObject {
  @HiveField(0)
  String url;

  @HiveField(1)
  String quality;

  @HiveField(2)
  String originalUrl;

  @HiveField(3)
  Map<String, String>? headers;

  @HiveField(4)
  List<Track>? subtitles;

  @HiveField(5)
  List<Track>? audios;

  Video(this.url, this.quality, this.originalUrl,
      {this.headers, this.subtitles, this.audios});

  factory Video.fromVideo(d.Video episode) {
    return Video(
      episode.url,
      episode.title ?? episode.quality ?? '',
      episode.url,
      headers: episode.headers,
      subtitles: episode.subtitles?.map((e) {
        return Track(file: e.file, label: e.label);
      }).toList(),
      audios: episode.audios?.map((e) {
        return Track(file: e.file, label: e.label);
      }).toList(),
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      json['url'].toString().trim(),
      json['quality'].toString().trim(),
      json['originalUrl'].toString().trim(),
      headers: (json['headers'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v.toString())),
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
      audios: json['audios'] != null
          ? (json['audios'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'quality': quality,
        'originalUrl': originalUrl,
        'headers': headers,
        'subtitles': subtitles?.map((e) => e.toJson()).toList(),
        'audios': audios?.map((e) => e.toJson()).toList(),
      };
}

@HiveType(typeId: 12)
class Track extends HiveObject {
  @HiveField(0)
  String? file;

  @HiveField(1)
  String? label;

  Track({this.file, this.label});

  Track.fromJson(Map<String, dynamic> json) {
    file = json['file']?.toString().trim();
    label = json['label']?.toString().trim();
  }

  Map<String, dynamic> toJson() => {'file': file, 'label': label};
}
