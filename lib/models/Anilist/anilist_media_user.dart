import 'package:anymex/controllers/service_handler/service_handler.dart';

class TrackedMedia {
  String? id;
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

  TrackedMedia(
      {this.id,
      this.title,
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
      this.servicesType = ServicesType.anilist});

  factory TrackedMedia.fromJson(Map<String, dynamic> json) {
    return TrackedMedia(
        id: json['media']['id']?.toString(),
        title: json['media']['title']['english'] ??
            json['media']['title']['romaji'] ??
            json['media']['title']['native'],
        poster: json['media']['coverImage']['large'],
        episodeCount: json['progress']?.toString(),
        chapterCount: json['media']['chapters']?.toString(),
        totalEpisodes: json['media']['episodes']?.toString(),
        releasedEpisodes: json['media']['nextAiringEpisode'] != null
            ? (json['media']['nextAiringEpisode']['episode'] - 1).toString()
            : null,
        rating: (double.tryParse(
                    json['media']['averageScore']?.toString() ?? "0")! /
                10)
            .toString(),
        watchingStatus: json['status'],
        format: json['media']['format'],
        mediaStatus: json['media']['status'],
        score: json['score']?.toString(),
        type: json['media']['type']?.toString(),
        servicesType: ServicesType.anilist,
        mediaListId:
            (json['media']['mediaListEntry']['id'] ?? json['media']['id'])
                .toString());
  }

  factory TrackedMedia.fromSimklShow(Map<String, dynamic> json) {
    final show = json['show'];
    final ids = show['ids'] ?? {};

    return TrackedMedia(
      id: '${ids['simkl']}*SERIES',
      title: show['title'],
      poster: show['poster'] != null
          ? "https://wsrv.nl/?url=https://simkl.in/posters/${show['poster']}_m.jpg"
          : '?',
      episodeCount: json['watched_episodes_count']?.toString(),
      totalEpisodes: json['total_episodes_count']?.toString(),
      watchingStatus: Simkl.simklShowToAL(json['status']),
      type: "show",
      servicesType: ServicesType.simkl,
      mediaStatus:
          json['not_aired_episodes_count'] == 0 ? "completed" : "airing",
      rating: null,
      score: null,
      format: null,
      mediaListId: '${ids['simkl']}*SERIES',
    );
  }

  factory TrackedMedia.fromSimklMovie(Map<String, dynamic> json) {
    final show = json['movie'];
    final ids = show['ids'] ?? {};
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
      score: null,
      format: null,
      mediaListId: '${ids['simkl']}*MOVIE',
    );
  }

  factory TrackedMedia.fromMAL(Map<String, dynamic> json) {
    return TrackedMedia(
      id: json['node']['id']?.toString(),
      title: json['node']['title'],
      servicesType: ServicesType.mal,
      poster: json['node']['main_picture']['large'],
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
      score: json['list_status']['score']?.toString(),
      type: null,
      mediaListId: json['node']['id']?.toString(),
    );
  }
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
  switch (status) {
    case 'watching' || 'reading':
      return 'CURRENT';
    case 'completed':
      return 'COMPLETED';
    case 'on_hold':
      return 'PAUSED';
    case 'dropped':
      return 'DROPPED';
    case 'plan_to_watch' || 'plan_to_read':
      return 'PLANNING';
    default:
      return 'ALL';
  }
}

String getMALStatusEquivalent(String status, {bool isAnime = true}) {
  switch (status.toUpperCase()) {
    case 'CURRENT':
      return isAnime ? 'watching' : 'reading';
    case 'COMPLETED':
      return 'completed';
    case 'PAUSED':
      return 'on_hold';
    case 'DROPPED':
      return 'dropped';
    case 'PLANNING':
      return isAnime ? 'plan_to_watch' : 'plan_to_read';
    default:
      return 'unknown';
  }
}
