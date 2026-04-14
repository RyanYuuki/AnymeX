class SearchUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isFollowing;
  final bool isFollower;
  final String? about;
  final UserStats? animeStats;
  final UserStats? mangaStats;

  SearchUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    this.isFollowing = false,
    this.isFollower = false,
    this.about,
    this.animeStats,
    this.mangaStats,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] as Map<String, dynamic>?;
    final animeStats = stats?['anime'] as Map<String, dynamic>?;
    final mangaStats = stats?['manga'] as Map<String, dynamic>?;

    return SearchUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String?,
      bannerUrl: json['bannerImage'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollower: json['isFollower'] as bool? ?? false,
      about: json['about'] as String?,
      animeStats: animeStats != null
          ? UserStats(
              count: animeStats['count'] as int? ?? 0,
              progress: animeStats['episodesWatched'] as int? ?? 0,
              minutesWatched: animeStats['minutesWatched'] as int? ?? 0,
            )
          : null,
      mangaStats: mangaStats != null
          ? UserStats(
              count: mangaStats['count'] as int? ?? 0,
              progress: mangaStats['chaptersRead'] as int? ?? 0,
              volumesRead: mangaStats['volumesRead'] as int? ?? 0,
            )
          : null,
    );
  }
}

class UserStats {
  final int count;
  final int progress;
  final int? minutesWatched;
  final int? volumesRead;

  UserStats({
    required this.count,
    required this.progress,
    this.minutesWatched,
    this.volumesRead,
  });
}

class SearchStaff {
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final List<String> occupations;
  final String? gender;
  final int? birthYear;
  final int favourites;
  final bool isFavourite;

  SearchStaff({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.occupations = const [],
    this.gender,
    this.birthYear,
    this.favourites = 0,
    this.isFavourite = false,
  });

  factory SearchStaff.fromJson(Map<String, dynamic> json) {
    final occupations = json['primaryOccupations'] as List<dynamic>? ?? [];
    return SearchStaff(
      id: json['id'] as int,
      name: json['name']?['full'] as String? ?? '',
      nativeName: json['name']?['native'] as String?,
      imageUrl: json['image']?['large'] as String?,
      occupations: occupations.cast<String>(),
      gender: json['gender'] as String?,
      birthYear: json['dateOfBirth']?['year'] as int?,
      favourites: json['favourites'] as int? ?? 0,
      isFavourite: json['isFavourite'] as bool? ?? false,
    );
  }
}

class SearchCharacter {
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? gender;
  final String? age;
  final int favourites;
  final bool isFavourite;
  final List<CharacterMedia> media;

  SearchCharacter({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.gender,
    this.age,
    this.favourites = 0,
    this.isFavourite = false,
    this.media = const [],
  });

  factory SearchCharacter.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media']?['nodes'] as List<dynamic>? ?? [];
    return SearchCharacter(
      id: json['id'] as int,
      name: json['name']?['full'] as String? ?? '',
      nativeName: json['name']?['native'] as String?,
      imageUrl: json['image']?['large'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as String?,
      favourites: json['favourites'] as int? ?? 0,
      isFavourite: json['isFavourite'] as bool? ?? false,
      media: mediaJson
          .map((e) => CharacterMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CharacterMedia {
  final int id;
  final String? title;
  final String? coverUrl;
  final String? type;

  CharacterMedia({required this.id, this.title, this.coverUrl, this.type});

  factory CharacterMedia.fromJson(Map<String, dynamic> json) {
    return CharacterMedia(
      id: json['id'] as int,
      title: json['title']?['userPreferred'] as String?,
      coverUrl: json['coverImage']?['large'] as String?,
      type: json['type'] as String?,
    );
  }
}

class SearchMediaResult {
  final int id;
  final String title;
  final String? coverUrl;
  final String? posterColor;
  final String type;
  final String? format;
  final int? averageScore;
  final int? popularity;
  final int? episodes;
  final int? chapters;
  final String? status;
  final int? seasonYear;
  final List<String> genres;
  final bool isFavourite;

  SearchMediaResult({
    required this.id,
    required this.title,
    this.coverUrl,
    this.posterColor,
    this.type = 'ANIME',
    this.format,
    this.averageScore,
    this.popularity,
    this.episodes,
    this.chapters,
    this.status,
    this.seasonYear,
    this.genres = const [],
    this.isFavourite = false,
  });

  factory SearchMediaResult.fromJson(Map<String, dynamic> json) {
    return SearchMediaResult(
      id: json['id'] as int,
      title: json['title']?['userPreferred'] as String? ??
          json['title']?['english'] as String? ??
          json['title']?['romaji'] as String? ??
          '',
      coverUrl: json['coverImage']?['large'] as String?,
      posterColor: json['coverImage']?['color'] as String?,
      type: json['type'] as String? ?? 'ANIME',
      format: json['format'] as String?,
      averageScore: json['averageScore'] as int?,
      popularity: json['popularity'] as int?,
      episodes: json['episodes'] as int?,
      chapters: json['chapters'] as int?,
      status: json['status'] as String?,
      seasonYear: json['seasonYear'] as int?,
      genres: (json['genres'] as List<dynamic>? ?? []).cast<String>(),
      isFavourite: json['isFavourite'] as bool? ?? false,
    );
  }
}
