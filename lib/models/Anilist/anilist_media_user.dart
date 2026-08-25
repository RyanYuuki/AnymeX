import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:get/get.dart';

class TrackedMedia {
  String? id;
  String? idMal;
  String? title;
  String? poster;
  String? episodeCount;
  String? chapterCount;
  String? rating;
  String? totalEpisodes;
  String? releasedEpisodes;
  String? watchingStatus;
  String? format;
  String? mediaStatus;
  String? score;
  String? type;
  String? mediaListId;
  ServicesType servicesType;
  String? userName;
  int? userId;
  DateTime? startedAt;
  DateTime? completedAt;
  bool? isPrivate;
  String? userAvatar;
  int? userProgress;
  double? userScore;
  List<String> genres;
  List<String> tags;
  int? startYear;
  int? updatedAt;

  String? romajiTitle;

  String get displayTitle {
    if (Get.isRegistered<Settings>() &&
        Get.find<Settings>().useAlternateTitle.value) {
      if (romajiTitle != null &&
          romajiTitle!.trim().isNotEmpty &&
          romajiTitle != '?') {
        return romajiTitle!;
      }
    }
    return title ?? '?';
  }

  TrackedMedia({
    this.id,
    this.idMal,
    this.title,
    this.romajiTitle,
    this.poster,
    this.episodeCount,
    this.chapterCount,
    this.rating,
    this.totalEpisodes,
    this.releasedEpisodes,
    this.watchingStatus,
    this.format,
    this.mediaStatus,
    this.score,
    this.type,
    this.mediaListId,
    this.servicesType = ServicesType.anilist,
    this.userName,
    this.userId,
    this.userAvatar,
    this.userProgress,
    this.userScore,
    this.genres = const [],
    this.tags = const [],
    this.startYear,
    this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.isPrivate,
  });

  factory TrackedMedia.fromJson(Map<String, dynamic> json) {
    final titleMap = json['media']?['title'];
    return TrackedMedia(
      id: json['media']['id']?.toString(),
      idMal: json['media']['idMal']?.toString(),
      title: titleMap?['userPreferred'] ??
          titleMap?['english'] ??
          titleMap?['romaji'] ??
          titleMap?['native'],
      romajiTitle: titleMap?['romaji'] ??
          titleMap?['userPreferred'] ??
          titleMap?['english'],
      poster: json['media']['coverImage']['large'],
      episodeCount: json['progress']?.toString(),
      chapterCount: json['media']['chapters']?.toString(),
      totalEpisodes: json['media']['episodes']?.toString(),
      releasedEpisodes: json['media']['nextAiringEpisode'] != null
          ? (json['media']['nextAiringEpisode']['episode'] - 1).toString()
          : null,
      rating:
          (double.tryParse(json['media']['averageScore']?.toString() ?? "0")! /
                  10)
              .toString(),
      watchingStatus: json['status'],
      format: json['media']['format'],
      mediaStatus: json['media']['status'],
      score: json['score']?.toString(),
      type: json['media']['type']?.toString(),
      servicesType: ServicesType.anilist,
      mediaListId: (json['id'] ??
              json['media']?['mediaListEntry']?['id'] ??
              json['media']?['id'])
          ?.toString(),
      genres: (json['media']['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags: (json['media']['tags'] as List<dynamic>?)
              ?.map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      startYear: json['media']['startDate']?['year'] as int?,
      updatedAt: json['updatedAt'] as int?,
      startedAt: _parseFuzzyDate(json['startedAt']),
      completedAt: _parseFuzzyDate(json['completedAt']),
      isPrivate: json['private'] as bool?,
    );
  }

  factory TrackedMedia.fromSocialJson(Map<String, dynamic> json) {
    return TrackedMedia(
      id: json['id']?.toString(),
      userName: json['user']['name'],
      userId: json['user']['id'] as int?,
      userAvatar: json['user']['avatar']['large'],
      userProgress: json['progress'],
      userScore: (json['score'] ?? 0).toDouble(),
      watchingStatus: json['status'],
      servicesType: ServicesType.anilist,
    );
  }

  factory TrackedMedia.fromSimklShow(Map<String, dynamic> json) {
    final show = json['show'] ?? {};
    final ids = show['ids'] ?? {};
    final rawDate = json['last_watched_at'] ?? json['user_updated_at'] ?? json['updated_at'];
    final updatedTime = rawDate != null
        ? (DateTime.tryParse(rawDate.toString())?.millisecondsSinceEpoch ?? 0)
        : 0;
    final year = int.tryParse(show['year']?.toString() ?? '') ?? 0;
    final rawScore = json['user_rating'] ?? show['ratings']?['simkl']?['rating'];
    final scoreStr = rawScore != null
        ? (double.tryParse(rawScore.toString()) != null
            ? (double.parse(rawScore.toString()) * 10).toString()
            : null)
        : null;

    return TrackedMedia(
      id: '${ids['simkl']}*SERIES',
      title: show['title'],
      poster: show['poster'] != null
          ? "https://wsrv.nl/?url=https://simkl.in/posters/${show['poster']}_m.jpg"
          : '?',
      episodeCount: json['watched_episodes_count']?.toString(),
      totalEpisodes: (json['total_episodes_count'] ??
              json['total_episodes'] ??
              json['episodes_count'] ??
              json['episodes'])
          ?.toString(),
      watchingStatus: Simkl.simklShowToAL(json['status']),
      type: "show",
      servicesType: ServicesType.simkl,
      mediaStatus:
          json['not_aired_episodes_count'] == 0 ? "completed" : "airing",
      rating: null,
      score: scoreStr,
      format: null,
      mediaListId: '${ids['simkl']}*SERIES',
      updatedAt: updatedTime,
      startYear: year,
    );
  }

  factory TrackedMedia.fromSimklMovie(Map<String, dynamic> json) {
    final show = json['movie'] ?? {};
    final ids = show['ids'] ?? {};
    final rawDate = json['last_watched_at'] ?? json['user_updated_at'] ?? json['updated_at'];
    final updatedTime = rawDate != null
        ? (DateTime.tryParse(rawDate.toString())?.millisecondsSinceEpoch ?? 0)
        : 0;
    final year = int.tryParse(show['year']?.toString() ?? '') ?? 0;
    final rawScore = json['user_rating'] ?? show['ratings']?['simkl']?['rating'];
    final scoreStr = rawScore != null
        ? (double.tryParse(rawScore.toString()) != null
            ? (double.parse(rawScore.toString()) * 10).toString()
            : null)
        : null;

    return TrackedMedia(
      id: '${ids['simkl']}*MOVIE',
      title: show['title'],
      servicesType: ServicesType.simkl,
      poster: show['poster'] != null
          ? "https://wsrv.nl/?url=https://simkl.in/posters/${show['poster']}_m.jpg"
          : '?',
      episodeCount:
          Simkl.simklMovieToAL(json['status']) != 'COMPLETED' ? "0" : '1',
      totalEpisodes: '1',
      watchingStatus: Simkl.simklMovieToAL(json['status']),
      type: "movie",
      mediaStatus:
          json['not_aired_episodes_count'] == 0 ? "COMPLETED" : "AIRING",
      rating: null,
      score: scoreStr,
      format: null,
      mediaListId: '${ids['simkl']}*MOVIE',
      updatedAt: updatedTime,
      startYear: year,
    );
  }

  factory TrackedMedia.fromMAL(Map<String, dynamic> json) {
    final isMangaResolved = json['node']?['num_chapters'] != null || json['list_status']?['num_chapters_read'] != null;
    return TrackedMedia(
      id: json['node']['id']?.toString(),
      idMal: json['node']['id']?.toString(),
      title: json['node']['title'],
      servicesType: ServicesType.mal,
      poster: json['node']['main_picture']?['large'] ?? json['node']['main_picture']?['medium'] ?? '',
      chapterCount:
          json['node']?['list_status']?['num_chapters_read']?.toString() ?? '?',
      episodeCount: json['list_status']?['num_chapters_read']?.toString() ??
          json['list_status']?['num_episodes_watched']?.toString() ??
          '?',
      totalEpisodes: json['node']?['num_episodes']?.toString() ??
          json['node']?['num_chapters']?.toString() ??
          '?',
      rating: json['node']?['mean']?.toString() ?? '?',
      watchingStatus: returnConvertedStatus(json['list_status']['status']),
      score: json['list_status']['score'] != null
          ? (json['list_status']['score'] * 10).toString()
          : null,
      type: isMangaResolved ? 'MANGA' : 'ANIME',
      mediaListId: json['node']['id']?.toString(),
      startedAt: _parseMalDate(json['list_status']?['start_date']),
      completedAt: _parseMalDate(json['list_status']?['finish_date']),
    );
  }
}

DateTime? _parseFuzzyDate(Map<String, dynamic>? date) {
  if (date == null) return null;
  final y = date['year'] as int?;
  final mo = date['month'] as int?;
  final d = date['day'] as int?;
  if (y == null || mo == null || d == null) return null;
  try { return DateTime(y, mo, d); } catch (_) { return null; }
}

DateTime? _parseMalDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try { return DateTime.parse(dateStr); } catch (_) { return null; }
}

class Simkl {
  static String simklShowToAL(String simklStatus) {
    switch (simklStatus) {
      case 'watching':
        return 'CURRENT';
      case 'completed':
        return 'COMPLETED';
      case 'hold':
        return 'PAUSED';
      case 'dropped':
        return 'DROPPED';
      case 'plantowatch':
        return 'PLANNING';
      default:
        return 'ALL';
    }
  }

  static String simklMovieToAL(String simklStatus) {
    switch (simklStatus) {
      case 'watching':
        return 'CURRENT';
      case 'completed':
        return 'COMPLETED';
      case 'hold':
        return 'PAUSED';
      case 'dropped':
        return 'DROPPED';
      case 'plantowatch':
        return 'PLANNING';
      default:
        return 'ALL';
    }
  }

  static String alToSimklShow(String anilistStatus) {
    switch (anilistStatus) {
      case 'CURRENT':
        return 'watching';
      case 'COMPLETED':
        return 'completed';
      case 'PAUSED':
        return 'hold';
      case 'DROPPED':
        return 'dropped';
      case 'PLANNING':
        return 'plantowatch';
      default:
        return 'all';
    }
  }

  static String alToSimklMovie(String anilistStatus) {
    switch (anilistStatus) {
      case 'CURRENT':
        return 'watching';
      case 'COMPLETED':
        return 'completed';
      case 'PAUSED':
        return 'hold';
      case 'DROPPED':
        return 'dropped';
      case 'PLANNING':
        return 'plantowatch';
      default:
        return 'all';
    }
  }
}

String getAniListStatusEquivalent(String status) {
  switch (status.toLowerCase()) {
    case 'watching':
      return 'CURRENT';
    case 'completed':
      return 'COMPLETED';
    case 'on_hold':
      return 'PAUSED';
    case 'dropped':
      return 'DROPPED';
    case 'plan_to_watch':
      return 'PLANNING';
    default:
      return 'UNKNOWN';
  }
}

String returnConvertedStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'watching':
    case 'reading':
      return 'CURRENT';
    case 'completed':
      return 'COMPLETED';
    case 'on_hold':
    case 'on-hold':
    case 'paused':
      return 'PAUSED';
    case 'dropped':
      return 'DROPPED';
    case 'plan_to_watch':
    case 'plan_to_read':
    case 'planning':
      return 'PLANNING';
    case 'repeating':
    case 'rewatching':
    case 'rereading':
      return 'REPEATING';
    default:
      return 'ALL';
  }
}

String getMALStatusEquivalent(String status, {bool isAnime = true}) {
  switch (status.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_')) {
    case 'CURRENT':
    case 'WATCHING':
    case 'READING':
    case 'REPEATING':
    case 'REWATCHING':
    case 'REREADING':
      return isAnime ? 'watching' : 'reading';
    case 'COMPLETED':
      return 'completed';
    case 'PAUSED':
    case 'ON_HOLD':
      return 'on_hold';
    case 'DROPPED':
      return 'dropped';
    case 'PLANNING':
    case 'PLAN_TO_WATCH':
    case 'PLAN_TO_READ':
      return isAnime ? 'plan_to_watch' : 'plan_to_read';
    default:
      return isAnime ? 'plan_to_watch' : 'plan_to_read';
  }
}
