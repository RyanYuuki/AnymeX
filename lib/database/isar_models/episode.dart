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

  @ignore
  Map<String, String> get headers {
    return sortMap;
  }

  set headers(Map<String, String> map) {
    sortKeys = map.keys.toList();
    sortVals = map.values.toList();
  }

  bool? filler;
  String? dateUpload;
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
    this.dateUpload,
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
      'dateUpload': dateUpload,
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
      dateUpload: json['dateUpload'] as String?,
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

  Episode clone() {
    return Episode(
      number: number,
      link: link,
      title: title,
      desc: desc,
      thumbnail: thumbnail,
      filler: filler,
      dateUpload: dateUpload,
      sortKeys: sortKeys != null ? List<String>.from(sortKeys!) : null,
      sortVals: sortVals != null ? List<String>.from(sortVals!) : null,
      timeStampInMilliseconds: timeStampInMilliseconds,
      durationInMilliseconds: durationInMilliseconds,
      lastWatchedTime: lastWatchedTime,
      currentTrack: currentTrack,
      videoTracks: videoTracks != null ? List<Video>.from(videoTracks!) : null,
      source: source,
    );
  }
}


extension EpisodeMap on Episode {
  Map<String, String> get sortMap {
    if (sortKeys == null || sortKeys!.isEmpty) return {};

    final result = <String, String>{};
    final vals = sortVals ?? [];
    for (int i = 0; i < sortKeys!.length; i++) {
      final k = sortKeys![i].trim();
      final v = i < vals.length ? vals[i].trim() : '';
      if (k.isNotEmpty && v.isNotEmpty && v.toLowerCase() != k.toLowerCase()) {
        result[k] = v;
      }
    }
    return result;
  }

  bool isSameEpisode(Episode? other) {
    if (other == null) return false;
    if (identical(this, other)) return true;
    if (link != null &&
        other.link != null &&
        link!.isNotEmpty &&
        other.link!.isNotEmpty &&
        link == other.link &&
        link != '#' &&
        link != '/') {
      return true;
    }
    final thisNum = double.tryParse(number.trim());
    final otherNum = double.tryParse(other.number.trim());
    if (thisNum != null && otherNum != null) {
      if (thisNum != otherNum) return false;
    } else if (number.trim() != other.number.trim()) {
      return false;
    }

    final thisSort = sortMap;
    final otherSort = other.sortMap;

    final thisSeason = _extractSeason(thisSort);
    final otherSeason = _extractSeason(otherSort);
    if (thisSeason != null && otherSeason != null && thisSeason != otherSeason) {
      return false;
    }

    for (final entry in thisSort.entries) {
      final key = entry.key.trim().toLowerCase();
      final thisVal = entry.value.trim().toLowerCase();
      if (thisVal.isEmpty || thisVal == key || key.contains('season')) continue;

      for (final otherEntry in otherSort.entries) {
        if (otherEntry.key.trim().toLowerCase() == key) {
          final otherVal = otherEntry.value.trim().toLowerCase();
          if (otherVal.isEmpty || otherVal == key) continue;
          if (thisVal != otherVal) {
            return false;
          }
        }
      }
    }
    return true;
  }

  int? _extractSeason(Map<String, String> map) {
    for (final entry in map.entries) {
      if (entry.key.trim().toLowerCase().contains('season')) {
        final val = entry.value.trim().toLowerCase();
        if (val.isEmpty || val == entry.key.trim().toLowerCase()) continue;
        final match = RegExp(r'\d+').firstMatch(val);
        if (match != null) {
          final parsed = int.tryParse(match.group(0)!);
          if (parsed != null && parsed > 0) return parsed;
        }
        final keyMatch = RegExp(r'\d+').firstMatch(entry.key);
        if (keyMatch != null) {
          final parsed = int.tryParse(keyMatch.group(0)!);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }
    return null;
  }
}
