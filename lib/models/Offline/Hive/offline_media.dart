import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:hive/hive.dart';

part 'offline_media.g.dart';

@HiveType(typeId: 7)
class OfflineMedia extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? jname;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? english;

  @HiveField(4)
  String? japanese;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? poster;

  @HiveField(7)
  String? cover;

  @HiveField(8)
  String? totalEpisodes;

  @HiveField(9)
  String? type;

  @HiveField(10)
  String? season;

  @HiveField(11)
  String? premiered;

  @HiveField(12)
  String? duration;

  @HiveField(13)
  String? status;

  @HiveField(14)
  String? rating;

  @HiveField(15)
  String? popularity;

  @HiveField(16)
  String? format;

  @HiveField(17)
  String? aired;

  @HiveField(18)
  String? totalChapters;

  @HiveField(19)
  List<String>? genres;

  @HiveField(20)
  List<String>? studios;

  @HiveField(21)
  List<Chapter>? chapters;

  @HiveField(22)
  List<Episode>? episodes;

  @HiveField(23)
  Episode? currentEpisode;

  @HiveField(24)
  Chapter? currentChapter;

  @HiveField(25)
  List<Episode>? watchedEpisodes;

  @HiveField(26)
  List<Chapter>? readChapters;

  @HiveField(27)
  int? serviceIndex;

  OfflineMedia(
      {this.id,
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
      this.serviceIndex = 0});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
  }

  factory OfflineMedia.fromJson(Map<String, dynamic> json) {
    return OfflineMedia(
      id: json['id'] as String?,
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
    );
  }
}
