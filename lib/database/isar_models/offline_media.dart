import 'package:anymex/database/isar_models/track.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:isar_community/isar.dart';

import 'chapter.dart';
import 'episode.dart';

part 'offline_media.g.dart';

@collection
class OfflineMedia {
  Id id = Isar.autoIncrement;

  @Index()
  String? mediaId;

  String? jname;
  String? name;
  String? english;
  String? japanese;
  String? description;
  String? poster;
  String? cover;
  String? totalEpisodes;
  String? type;
  String? season;
  String? premiered;
  String? duration;
  String? status;
  String? rating;
  String? popularity;
  String? format;
  String? aired;
  String? totalChapters;

  List<String>? genres;
  List<String>? studios;

  List<Chapter>? chapters;
  List<Episode>? episodes;

  Episode? currentEpisode;
  Chapter? currentChapter;

  List<Episode>? watchedEpisodes;
  List<Chapter>? readChapters;

  int? serviceIndex;
  int? mediaTypeIndex;

  OfflineMedia({
    this.mediaId,
    this.jname,
    this.name,
    this.english,
    this.japanese,
    this.description,
    this.poster,
    this.cover,
    this.totalEpisodes,
    this.type,
    this.season,
    this.premiered,
    this.duration,
    this.status,
    this.rating,
    this.popularity,
    this.format,
    this.aired,
    this.totalChapters,
    this.genres,
    this.studios,
    this.chapters,
    this.episodes,
    this.currentEpisode,
    this.currentChapter,
    this.watchedEpisodes,
    this.readChapters,
    this.serviceIndex = 0,
    this.mediaTypeIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': mediaId,
      'jname': jname,
      'name': name,
      'english': english,
      'japanese': japanese,
      'description': description,
      'poster': poster,
      'cover': cover,
      'totalEpisodes': totalEpisodes,
      'type': type,
      'season': season,
      'premiered': premiered,
      'duration': duration,
      'status': status,
      'rating': rating,
      'popularity': popularity,
      'format': format,
      'aired': aired,
      'totalChapters': totalChapters,
      'genres': genres,
      'studios': studios,
      'chapters': chapters?.map((c) => c.toJson()).toList(),
      'episodes': episodes?.map((e) => e.toJson()).toList(),
      'currentEpisode': currentEpisode?.toJson(),
      'currentChapter': currentChapter?.toJson(),
      'watchedEpisodes': watchedEpisodes?.map((e) => e.toJson()).toList(),
      'readChapters': readChapters?.map((c) => c.toJson()).toList(),
      'serviceIndex': serviceIndex,
      'mediaTypeIndex': mediaTypeIndex,
    };
  }

  factory OfflineMedia.fromJson(Map<String, dynamic> json) {
    return OfflineMedia(
      mediaId: json['id'] as String?,
      jname: json['jname'] as String?,
      name: json['name'] as String?,
      english: json['english'] as String?,
      japanese: json['japanese'] as String?,
      description: json['description'] as String?,
      poster: json['poster'] as String?,
      cover: json['cover'] as String?,
      totalEpisodes: json['totalEpisodes'] as String?,
      type: json['type'] as String?,
      season: json['season'] as String?,
      premiered: json['premiered'] as String?,
      duration: json['duration'] as String?,
      status: json['status'] as String?,
      rating: json['rating'] as String?,
      popularity: json['popularity'] as String?,
      format: json['format'] as String?,
      aired: json['aired'] as String?,
      totalChapters: json['totalChapters'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      studios: (json['studios'] as List<dynamic>?)?.cast<String>(),
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentEpisode: json['currentEpisode'] != null
          ? Episode.fromJson(json['currentEpisode'] as Map<String, dynamic>)
          : null,
      currentChapter: json['currentChapter'] != null
          ? Chapter.fromJson(json['currentChapter'] as Map<String, dynamic>)
          : null,
      watchedEpisodes: (json['watchedEpisodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      readChapters: (json['readChapters'] as List<dynamic>?)
          ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      serviceIndex: json['serviceIndex'] as int? ?? 0,
      mediaTypeIndex: json['mediaTypeIndex'] as int? ?? 0,
    );
  }
}
