class Profile {
  String? id;
  String? name;
  String? userName;
  String? avatar;
  String? cover;
  ProfileStatistics? stats;
  int? followers;
  int? following;

  Profile({
    this.id,
    this.name,
    this.userName,
    this.avatar,
    this.cover,
    this.stats,
    this.followers,
    this.following,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString(),
      name: json['name'],
      avatar: json['avatar']?['large'],
      cover: json['bannerImage'],
      stats: json['statistics'] != null
          ? ProfileStatistics.fromJson(json['statistics'])
          : null,
      followers: json['followers']?['pageInfo']?['total'] as int?,
      following: json['following']?['pageInfo']?['total'] as int?,
    );
  }

  factory Profile.fromKitsu(Map<String, dynamic> json) {
    return Profile(
      id: json['data']?['mal_id']?.toString(),
      name: json['data']?['username'],
      avatar: json['picture'] ??
          json['data']?['images']?['jpg']?['image_url'] ??
          json['data']?['images']?['webp']?['image_url'],
      stats: ProfileStatistics.fromKitsu(json['data']?['statistics']),
      followers: null,
      following: null,
    );
  }
}

class ProfileStatistics {
  AnimeStats? animeStats;
  MangaStats? mangaStats;

  ProfileStatistics({this.animeStats, this.mangaStats});

  factory ProfileStatistics.fromJson(Map<String, dynamic> json) {
    return ProfileStatistics(
      animeStats:
          json['anime'] != null ? AnimeStats.fromJson(json['anime']) : null,
      mangaStats:
          json['manga'] != null ? MangaStats.fromJson(json['manga']) : null,
    );
  }

  factory ProfileStatistics.fromKitsu(Map<String, dynamic>? json) {
    return ProfileStatistics(
      animeStats:
          json?['anime'] != null ? AnimeStats.fromKitsu(json!['anime']) : null,
      mangaStats:
          json?['manga'] != null ? MangaStats.fromKitsu(json!['manga']) : null,
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

  factory AnimeStats.fromKitsu(Map<String, dynamic> json) {
    return AnimeStats(
        animeCount: json['total_entries']?.toString(),
        episodesWatched: json['episodes_watched']?.toString(),
        meanScore: json['mean_score']?.toString(),
        minutesWatched: '??');
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

  factory MangaStats.fromKitsu(Map<String, dynamic> json) {
    return MangaStats(
      mangaCount: json['total_entries']?.toString(),
      chaptersRead: json['chapters_read']?.toString(),
      volumesRead: json['volumes_read']?.toString(),
      meanScore: json['mean_score']?.toString(),
    );
  }
}
