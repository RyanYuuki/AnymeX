import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/isar_models/track.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:isar_community/isar.dart';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:get/get.dart';
import 'chapter.dart';
import 'episode.dart';

part 'offline_media.g.dart';

@collection
class OfflineMedia {
  Id id = Isar.autoIncrement;

  @Index()
  String? mediaId;

  String? idMal;

  String? jname;
  String? name;
  String? english;
  String? japanese;

  @ignore
  String get displayTitle {
    if (Get.isRegistered<Settings>() &&
        Get.find<Settings>().useAlternateTitle.value) {
      final alt = (jname?.isNotEmpty ?? false)
          ? jname
          : ((japanese?.isNotEmpty ?? false)
              ? japanese
              : english);
      if (alt != null && alt.trim().isNotEmpty && alt != '?') {
        return alt;
      }
    }
    if (Get.isRegistered<AnilistAuth>() &&
        Get.find<AnilistAuth>().isLoggedIn.value) {
      final lang =
          Get.find<AnilistAuth>().cachedSettings?.titleLanguage?.toUpperCase();
      if (lang == 'ROMAJI' && (jname?.isNotEmpty ?? false)) {
        return jname!;
      } else if (lang == 'NATIVE' && (japanese?.isNotEmpty ?? false)) {
        return japanese!;
      } else if (lang == 'ENGLISH' && (english?.isNotEmpty ?? false)) {
        return english!;
      }
    }
    return english ?? name ?? '?';
  }

  @ignore
  ItemType get itemType => ItemType.values[mediaTypeIndex ?? 0];

  @ignore
  int get episodeCountInt => int.tryParse(totalEpisodes ?? '') ?? 0;

  @ignore
  int get chapterCountInt => int.tryParse(totalChapters ?? '') ?? 0;

  bool hasRequiredHistoryMedia([ItemType? type]) {
    final t = type ?? itemType;
    switch (t) {
      case ItemType.anime:
        return currentEpisode != null &&
            currentEpisode!.currentTrack != null &&
            episodes != null;
      case ItemType.manga:
        return currentChapter != null;
      case ItemType.novel:
        return currentChapter != null && chapters != null;
    }
  }

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

  @Index(composite: [CompositeIndex('mediaId')])
  int? mediaTypeIndex;

  OfflineMedia({
    this.mediaId,
    this.idMal,
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
      'idMal': idMal,
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
      mediaId: (json['id'] ?? json['mediaId'])?.toString(),
      idMal: json['idMal']?.toString(),
      jname: json['jname']?.toString(),
      name: json['name']?.toString(),
      english: json['english']?.toString(),
      japanese: json['japanese']?.toString(),
      description: json['description']?.toString(),
      poster: json['poster']?.toString(),
      cover: json['cover']?.toString(),
      totalEpisodes: json['totalEpisodes']?.toString(),
      type: json['type']?.toString(),
      season: json['season']?.toString(),
      premiered: json['premiered']?.toString(),
      duration: json['duration']?.toString(),
      status: json['status']?.toString(),
      rating: json['rating']?.toString(),
      popularity: json['popularity']?.toString(),
      format: json['format']?.toString(),
      aired: json['aired']?.toString(),
      totalChapters: json['totalChapters']?.toString(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      studios: (json['studios'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
      serviceIndex: (json['serviceIndex'] as num?)?.toInt() ?? 0,
      mediaTypeIndex: (json['mediaTypeIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Media toMedia() {
    return Media(
      id: mediaId ?? '',
      idMal: idMal ?? '',
      title: displayTitle,
      englishTitle: english ?? name,
      romajiTitle: jname ?? japanese ?? name ?? '',
      nativeTitle: japanese,
      description: description ?? '',
      poster: poster ?? '',
      cover: cover,
      totalEpisodes: totalEpisodes ?? '0',
      type: type ?? '',
      season: season ?? '',
      premiered: premiered ?? '',
      duration: duration ?? '',
      status: status ?? '',
      rating: rating ?? '',
      popularity: popularity ?? '',
      format: format ?? '',
      aired: aired ?? '',
      totalChapters: totalChapters ?? '0',
      genres: genres ?? [],
      studios: studios ?? [],
      mediaType: itemType,
      mediaContent: (episodes ?? [])
          .map((e) => DEpisode(
                episodeNumber: e.number,
                url: e.link,
                name: e.title,
                description: e.desc,
                thumbnail: e.thumbnail,
                filler: e.filler,
                dateUpload: e.dateUpload,
              ))
          .toList(),
      altMediaContent: chapters,
      serviceType: ServicesType.values[serviceIndex ?? 0],
    );
  }
}
