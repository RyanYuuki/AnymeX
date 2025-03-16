import 'dart:developer';

import 'package:anymex/core/Eval/dart/model/m_chapter.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';

enum MediaType { anime, manga, novel, unknown }

class Media {
  String id;
  String idMal;
  String title;
  String romajiTitle;
  String description;
  String poster;
  String? cover;
  String totalEpisodes;
  String type;
  String season;
  String premiered;
  String duration;
  String status;
  String rating;
  String popularity;
  String format;
  String aired;
  MediaType mediaType;
  List<MChapter>? mediaContent;
  String? totalChapters;
  List<String> genres;
  List<String>? studios;
  List<Character>? characters;
  List<Relation>? relations;
  List<Media> recommendations;
  NextAiringEpisode? nextAiringEpisode;
  List<Ranking> rankings;

  Media(
      {this.id = '0',
      this.idMal = '0',
      this.mediaType = MediaType.anime,
      this.title = '?',
      this.romajiTitle = '?',
      this.description = '?',
      this.poster = '?',
      this.cover,
      this.totalEpisodes = '?',
      this.type = '?',
      this.season = '?',
      this.premiered = '?',
      this.duration = '?',
      this.status = '?',
      this.rating = '?',
      this.popularity = '?',
      this.format = '?',
      this.aired = '?',
      this.totalChapters = '?',
      this.genres = const [],
      this.studios,
      this.characters,
      this.relations,
      this.recommendations = const [],
      this.nextAiringEpisode,
      this.rankings = const [],
      this.mediaContent});

  factory Media.fromMAL(Map<String, dynamic> json) {
    final node = json['node'] ?? {};

    return Media(
      id: node['id']?.toString() ?? '0',
      title: node['title'] ?? '??',
      romajiTitle: node['alternative_titles']?['en'] ?? '??',
      description: node['synopsis'] ?? '??',
      poster: node['main_picture']?['medium'] ?? '??',
      cover: node['main_picture']?['large'] ?? '??',
      totalEpisodes: node['num_episodes']?.toString() ?? '??',
      type: node['media_type'] ?? '??',
      season: node['start_season']?['season'] ?? '??',
      premiered: node['start_date'] ?? '??',
      duration: node['average_episode_duration']?.toString() ?? '??',
      status: node['status'] ?? '??',
      rating: node['mean']?.toString() ?? '??',
      popularity: node['popularity']?.toString() ?? '??',
      format: node['media_type'] ?? '??',
      aired: node['start_date'] ?? '??',
      totalChapters: node['num_chapters']?.toString() ?? '??',
      genres: (node['genres'] as List<dynamic>?)
              ?.map((genre) => genre['name']?.toString() ?? '??')
              .toList() ??
          [],
      studios: (node['studios'] as List<dynamic>?)
          ?.map((studio) => studio['name']?.toString() ?? '??')
          .toList(),
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: [],
      mediaType: node['media_type'] == 'tv' ? MediaType.anime : MediaType.manga,
    );
  }

  factory Media.fromFullMAL(Map<String, dynamic> json) {
    final node = json;

    return Media(
      id: node['id']?.toString() ?? '0',
      title: node['title'] ?? '??',
      romajiTitle: node['alternative_titles']?['en'] ?? '??',
      description: node['synopsis'] ?? '??',
      poster: node['main_picture']?['medium'] ?? '??',
      cover: node['main_picture']?['large'] ?? '??',
      totalEpisodes: node['num_episodes']?.toString() ?? '??',
      type: node['media_type']?.toUpperCase() ?? '??',
      season: node['start_season']?['season'] ?? '??',
      premiered: node['start_date'] ?? '??',
      duration: node['average_episode_duration']?.toString() ?? '??',
      status: node['status']?.replaceAll('_', ' ')?.toUpperCase() ?? '??',
      rating: node['mean']?.toString() ?? '??',
      popularity: node['popularity']?.toString() ?? '??',
      format: node['media_type'] ?? '??',
      aired: node['start_date'] ?? '??',
      totalChapters: node['num_chapters']?.toString() ?? '??',
      genres: (node['genres'] as List<dynamic>?)
              ?.map((genre) => genre['name']?.toString() ?? '??')
              .toList() ??
          [],
      studios: (node['studios'] as List<dynamic>?)
          ?.map((studio) => studio['name']?.toString() ?? '??')
          .toList(),
      characters: [],
      recommendations: (node['recommendations'] as List<dynamic>)
          .map((e) => Media.fromMAL(e))
          .toList(),
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: [],
      mediaType: node['media_type'] == 'tv' ? MediaType.anime : MediaType.manga,
    );
  }

  factory Media.fromSimkl(Map<String?, dynamic> json, bool isMovie) {
    MediaType type = MediaType.anime;

    return Media(
      id: '${json['ids']?['simkl_id']?.toString() ?? json['ids']?['simkl']?.toString()}*${isMovie ? "MOVIE" : "SERIES"}',
      title: json['title'] ?? 'Unknown Title',
      romajiTitle: json['title'] ?? 'Unknown Romaji Title',
      description: json['overview'] ?? 'No description available.',
      poster: json['poster'] != null
          ? 'https://wsrv.nl/?url=https://simkl.in/posters/${json['poster']}_m.jpg'
          : '',
      cover: json['fanart'] != null
          ? 'https://wsrv.nl/?url=https://simkl.in/fanart/${json['fanart']}_medium.jpg'
          : null,
      totalEpisodes: json['total_episodes']?.toString() ?? '1',
      type: json['country']?.toUpperCase() ?? 'UNKNOWN',
      premiered: json['released'] ?? 'Unknown release date',
      duration: json['runtime'] != null
          ? '${json['runtime']} minutes'
          : 'Unknown runtime',
      status: json['type']?.toUpperCase() ?? 'UNKNOWN',
      rating: json['ratings']?['simkl']?['rating']?.toString() ?? 'N/A',
      popularity: json['rank']?.toString() ?? '0',
      mediaType: type,
      aired: json['released'] ?? 'Unknown air date',
      totalChapters: '0',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((genre) => genre.toString())
              .toList() ??
          [],
      recommendations: (json['users_recommendations'] as List<dynamic>?)
              ?.map((e) {
                try {
                  return Media.fromSmallSimkl(e, isMovie);
                } catch (error) {
                  log('Error parsing recommendation: $error');
                  return null;
                }
              })
              .where((e) => e != null)
              .toList()
              .cast<Media>() ??
          [],
    );
  }

  factory Media.fromSmallSimkl(Map<String?, dynamic> json, bool isMovie) {
    MediaType type = MediaType.anime;
    return Media(
        id:
            '${json['ids']?['simkl']?.toString()}*${isMovie ? "MOVIE" : "SERIES"}',
        title: json['title'] ?? 'Unknown Title',
        poster: json['poster'] != null
            ? 'https://simkl.in/posters/${json['poster']}_m.jpg'
            : '',
        type: isMovie ? 'MOVIE' : 'SERIES',
        rating: '0.0',
        mediaType: type,
        aired: json['year']?.toString() ?? 'Unknown air date');
  }

  factory Media.fromManga(MManga manga, MediaType type) {
    return Media(
      id: manga.link ?? '',
      title: manga.name ?? "Unknown Title",
      romajiTitle: manga.name ?? "Unknown Title",
      description: manga.description ?? "No description available.",
      poster: manga.imageUrl ?? "",
      cover: manga.imageUrl,
      totalEpisodes: manga.chapters?.length.toString() ?? '??',
      status: manga.status?.name.toUpperCase() ?? 'Ongoing',
      mediaType: type,
      aired: manga.status?.name.toUpperCase() ?? 'Unknown',
      totalChapters: manga.chapters?.length.toString(),
      genres: manga.genre ?? [],
      studios: null,
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: manga.chapters,
    );
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    MediaType type = json['type'] == "ANIME"
        ? MediaType.anime
        : json['type'] == "MANGA"
            ? MediaType.manga
            : MediaType.unknown;
    return Media(
      id: json['id'].toString(),
      romajiTitle: json['title']['romaji'] ?? '?',
      title: json['title']['english'] ?? json['title']['romaji'] ?? '?',
      description: json['description'] ?? '?',
      poster: json['coverImage']['large'] ?? '?',
      cover: json['bannerImage'],
      totalEpisodes: (json['episodes'] as int?)?.toString() ?? '?',
      type: json['type'] ?? '?',
      season: json['season'] ?? '?',
      premiered: '${json['season'] ?? '?'} ${json['seasonYear'] ?? '?'}',
      duration: '${json['duration'] ?? '?'}m',
      status: json['status'] ?? '?',
      rating: ((json['averageScore'] ?? 0) / 10).toString(),
      popularity: json['popularity']?.toString() ?? '6900',
      format: json['format'] ?? '?',
      aired: _parseDateRange(json['startDate'], json['endDate']),
      totalChapters: json['chapters']?.toString() ?? '?',
      genres: List<String>.from(json['genres'] ?? []),
      studios: (json['studios']['nodes'] as List)
          .map((el) => el['name'].toString())
          .toList(),
      characters: (json['characters']['edges'] as List)
          .map((character) => Character.fromJson(character))
          .toList(),
      relations: (json['relations']['edges'] as List)
          .map((relation) => Relation.fromJson(relation))
          .toList(),
      recommendations: (json['recommendations']['edges'] as List)
          .map((recommendation) => Media.fromRecs(recommendation))
          .toList(),
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      rankings: (json['rankings'] as List)
          .map((ranking) => Ranking.fromJson(ranking))
          .toList(),
      mediaType: type,
    );
  }

  factory Media.fromSmallJson(Map<String, dynamic> json, bool isManga,
      {bool isMal = false}) {
    return Media(
      id: (isMal ? json['idMal']?.toString() : json['id'].toString()) ?? '',
      romajiTitle: json['title']['romaji'] ?? '?',
      title: json['title']['english'] ?? json['title']['romaji'] ?? '?',
      description: json['description'] ?? '',
      poster: json['coverImage']?['large'] ?? '?',
      cover: json['bannerImage'],
      rating: ((json['averageScore'] ?? 0) / 10).toStringAsFixed(1),
      type: isManga ? 'MANGA' : 'ANIME',
      mediaType: isManga ? MediaType.manga : MediaType.anime,
    );
  }
  factory Media.fromCarouselData(CarouselData data, MediaType type) {
    return Media(
      id: data.id!.toString(),
      romajiTitle: data.title ?? '?',
      title: data.title ?? '?',
      poster: data.poster ?? '?',
      rating: data.extraData ?? '0.0',
      mediaType: type,
    );
  }

  factory Media.fromRecs(Map<String, dynamic> json) {
    return Media(
      id: json['node']['mediaRecommendation']['id'].toString(),
      title: json['node']['mediaRecommendation']['title']['romaji'] ??
          json['node']['mediaRecommendation']['title']['english'],
      poster: json['node']['mediaRecommendation']['coverImage']['large'],
      rating:
          ((json['node']['mediaRecommendation']['averageScore'] ?? 0) / 10 ?? 0)
              .toString(),
    );
  }

  factory Media.fromOfflineMedia(OfflineMedia offline, MediaType type) {
    return Media(
        id: offline.id?.toString() ?? '0',
        title: offline.name ?? offline.english ?? offline.jname ?? '?',
        romajiTitle: offline.jname ?? '?',
        description: offline.description ?? '?',
        poster: offline.poster ?? '?',
        cover: offline.cover,
        totalEpisodes: offline.totalEpisodes?.toString() ?? '?',
        type: offline.type ?? '?',
        season: offline.season ?? '?',
        premiered: offline.premiered ?? '?',
        duration: offline.duration ?? '?',
        status: offline.status ?? '?',
        rating: offline.rating ?? '?',
        popularity: offline.popularity ?? '?',
        format: offline.format ?? '?',
        aired: offline.aired ?? '?',
        totalChapters: offline.totalChapters?.toString() ?? '?',
        genres: offline.genres ?? const [],
        studios: offline.studios,
        characters: null,
        relations: null,
        recommendations: const [],
        nextAiringEpisode: null,
        rankings: const [],
        mediaType: type);
  }

  static String _parseDateRange(
      Map<String, dynamic>? start, Map<String, dynamic>? end) {
    if (start == null && end == null) return 'Unknown';
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);
    return '$startDate to $endDate';
  }

  static String _formatDate(Map<String, dynamic>? date) {
    if (date == null) return '?';
    return '${date['year'] ?? '?'}-${date['month']?.toString().padLeft(2, '0') ?? '?'}-${date['day']?.toString().padLeft(2, '0') ?? '?'}';
  }
}

class NextAiringEpisode {
  final int airingAt;
  final int timeUntilAiring;
  final int episode;

  NextAiringEpisode({
    required this.airingAt,
    required this.timeUntilAiring,
    required this.episode,
  });

  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
        airingAt: json['airingAt'],
        timeUntilAiring: json['timeUntilAiring'],
        episode: json['episode']);
  }
}

class Ranking {
  final int rank;
  final String type;
  final int year;

  Ranking({required this.rank, required this.type, required this.year});

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      rank: json['rank'] ?? 0,
      type: json['type'] ?? '?',
      year: json['year'] ?? 0,
    );
  }
}
