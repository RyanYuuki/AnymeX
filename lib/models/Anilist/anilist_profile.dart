class AnilistProfile {
  String? id;
  String? name;
  String? avatar;
  AnilistProfileStatistics? stats;
  int? followers; // Count of followers
  int? following; // Count of following

  AnilistProfile({
    this.id,
    this.name,
    this.avatar,
    this.stats,
    this.followers,
    this.following,
  });

  factory AnilistProfile.fromJson(Map<String, dynamic> json) {
    return AnilistProfile(
      id: json['id']?.toString(),
      name: json['name'],
      avatar: json['avatar']?['large'],
      stats: json['statistics'] != null
          ? AnilistProfileStatistics.fromJson(json['statistics'])
          : null,
      followers: json['followers']?['pageInfo']?['total'] as int?,
      following: json['following']?['pageInfo']?['total'] as int?,
    );
  }
}

class AnilistProfileStatistics {
  AnimeStats? animeStats;
  MangaStats? mangaStats;

  AnilistProfileStatistics({this.animeStats, this.mangaStats});

  factory AnilistProfileStatistics.fromJson(Map<String, dynamic> json) {
    return AnilistProfileStatistics(
      animeStats:
          json['anime'] != null ? AnimeStats.fromJson(json['anime']) : null,
      mangaStats:
          json['manga'] != null ? MangaStats.fromJson(json['manga']) : null,
    );
  }
}

class AnimeStats {
  String? animeCount;
  String? episodesWatched;
  String? meanScore;
  String? minutesWatched;

  AnimeStats({
    this.animeCount,
    this.episodesWatched,
    this.meanScore,
    this.minutesWatched,
  });

  factory AnimeStats.fromJson(Map<String, dynamic> json) {
    return AnimeStats(
      animeCount: json['count']?.toString(),
      episodesWatched: json['episodesWatched']?.toString(),
      meanScore: json['meanScore']?.toString(),
      minutesWatched: json['minutesWatched']?.toString(),
    );
  }
}

class MangaStats {
  String? mangaCount;
  String? chaptersRead;
  String? volumesRead;
  String? meanScore;

  MangaStats({
    this.mangaCount,
    this.chaptersRead,
    this.volumesRead,
    this.meanScore,
  });

  factory MangaStats.fromJson(Map<String, dynamic> json) {
    return MangaStats(
      mangaCount: json['count']?.toString(),
      chaptersRead: json['chaptersRead']?.toString(),
      volumesRead: json['volumesRead']?.toString(),
      meanScore: json['meanScore']?.toString(),
    );
  }
}
