import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart' as d;
import 'package:isar_community/isar.dart';

import 'track.dart';

part 'video.g.dart';

@embedded
class Video {
  String? url;
  String? quality;
  String? originalUrl;

  List<String>? headerKeys;
  List<String>? headerValues;

  List<Track>? subtitles;
  List<Track>? audios;

  Video({
    this.url,
    this.quality,
    this.originalUrl,
    this.headerKeys,
    this.headerValues,
    this.subtitles,
    this.audios,
  });

  factory Video.fromVideo(d.Video episode) {
    final video = Video(
      url: episode.url,
      quality: episode.title ?? episode.quality,
      originalUrl: episode.url,
      subtitles: episode.subtitles?.map((d.Track e) {
        return Track(file: e.file, label: e.label);
      }).toList(),
      headerValues: episode.headers?.values.toList() ?? [],
      headerKeys: episode.headers?.keys.toList() ?? [],
      audios: episode.audios?.map((e) {
        return Track(file: e.file, label: e.label);
      }).toList(),
    );
    return video;
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    final video = Video(
      url: json['url']?.toString().trim(),
      quality: json['quality']?.toString().trim(),
      originalUrl: json['originalUrl']?.toString().trim(),
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
      audios: json['audios'] != null
          ? (json['audios'] as List).map((e) => Track.fromJson(e)).toList()
          : [],
    );

    if (json['headers'] != null) {
      video.headers = (json['headers'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return video;
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

extension VideoExtension on Video {
  Map<String, String>? get headers {
    if (headerKeys == null || headerValues == null) return null;
    if (headerKeys!.length != headerValues!.length) return null;

    return Map.fromIterables(headerKeys!, headerValues!);
  }

  set headers(Map<String, String>? value) {
    if (value == null) {
      headerKeys = null;
      headerValues = null;
    } else {
      headerKeys = value.keys.toList();
      headerValues = value.values.toList();
    }
  }
}
