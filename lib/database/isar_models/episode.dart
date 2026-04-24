import 'package:isar_community/isar.dart';

import 'video.dart';

part 'episode.g.dart';

@embedded
class Episode {
  String number;
  String? link;
  String? title;
  String? desc;
  String? thumbnail;
  List<String>? sortKeys;
  List<String>? sortVals;
  bool? filler;
  int? timeStampInMilliseconds;
  int? durationInMilliseconds;
  int? lastWatchedTime;

  Video? currentTrack;
  List<Video>? videoTracks;

  String? source;

  Episode({
    this.number = "1",
    this.link,
    this.title,
    this.desc,
    this.thumbnail,
    this.filler,
    this.sortKeys,
    this.sortVals,
    this.timeStampInMilliseconds,
    this.durationInMilliseconds,
    this.lastWatchedTime,
    this.currentTrack,
    this.videoTracks,
    this.source,
  });

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
      'sortKeys': sortKeys,
      'sortVals': sortVals
    };
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    final rawSortKeys = json['sortKeys'] as List<dynamic>?;
    final rawSortVals = json['sortVals'] as List<dynamic>?;

    return Episode(
      number: (json['number'] ?? 1).toString(),
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
      sortKeys: rawSortKeys?.map((e) => e.toString()).toList(),
      sortVals: rawSortVals?.map((e) => e.toString()).toList(),
    );
  }
}

extension EpisodeMap on Episode {
  Map<String, String> get sortMap {
    if (sortKeys == null || sortVals == null) return {};
    if (sortKeys!.isEmpty || sortVals!.isEmpty) return {};

    final pairCount = sortKeys!.length < sortVals!.length
        ? sortKeys!.length
        : sortVals!.length;
    if (pairCount == 0) return {};

    return Map<String, String>.fromIterables(
      sortKeys!.take(pairCount),
      sortVals!.take(pairCount),
    );
  }
}
