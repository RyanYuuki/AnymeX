class Profile {
  String? id;
  String? name;
  String? userName;
  String? avatar;
  String? cover;
  String? about;
  ProfileStatistics? stats;
  int? followers;
  int? following;
  DateTime? tokenExpiry;
  ProfileFavourites? favourites;

  Profile({
    this.id,
    this.name,
    this.userName,
    this.avatar,
    this.cover,
    this.about,
    this.stats,
    this.followers,
    this.following,
    this.tokenExpiry,
    this.favourites,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString(),
      name: json['name'],
      avatar: json['avatar']?['large'],
      cover: json['bannerImage'],
      about: json['about'],
      stats: json['statistics'] != null
          ? ProfileStatistics.fromJson(json['statistics'])
          : null,
      followers: json['followers']?['pageInfo']?['total'] as int?,
      following: json['following']?['pageInfo']?['total'] as int?,
      favourites: json['favourites'] != null
          ? ProfileFavourites.fromJson(json['favourites'])
          : null,
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

class ProfileFavourites {
  List<FavouriteMedia> anime;
  List<FavouriteMedia> manga;
  List<FavouriteCharacter> characters;
  List<FavouriteStaff> staff;
  List<FavouriteStudio> studios;

  ProfileFavourites({
    this.anime = const [],
    this.manga = const [],
    this.characters = const [],
    this.staff = const [],
    this.studios = const [],
  });

  factory ProfileFavourites.fromJson(Map<String, dynamic> json) {
    List<T> parseNodes<T>(
        dynamic data, T Function(Map<String, dynamic>) fromJson) {
      if (data == null) return [];
      final nodes = data['nodes'] as List<dynamic>?;
      if (nodes == null) return [];
      return nodes
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ProfileFavourites(
      anime: parseNodes(json['anime'], FavouriteMedia.fromJson),
      manga: parseNodes(json['manga'], FavouriteMedia.fromJson),
      characters: parseNodes(json['characters'], FavouriteCharacter.fromJson),
      staff: parseNodes(json['staff'], FavouriteStaff.fromJson),
      studios: parseNodes(json['studios'], FavouriteStudio.fromJson),
    );
  }
}

class FavouriteMedia {
  String? id;
  String? title;
  String? cover;

  FavouriteMedia({this.id, this.title, this.cover});

  factory FavouriteMedia.fromJson(Map<String, dynamic> json) {
    return FavouriteMedia(
      id: json['id']?.toString(),
      title: json['title']?['english'] ??
          json['title']?['romaji'] ??
          json['title']?['userPreferred'],
      cover: json['coverImage']?['large'],
    );
  }
}

class FavouriteCharacter {
  String? id;
  String? name;
  String? image;

  FavouriteCharacter({this.id, this.name, this.image});

  factory FavouriteCharacter.fromJson(Map<String, dynamic> json) {
    return FavouriteCharacter(
      id: json['id']?.toString(),
      name: json['name']?['full'] ?? json['name']?['userPreferred'],
      image: json['image']?['large'],
    );
  }
}

class FavouriteStaff {
  String? id;
  String? name;
  String? image;

  FavouriteStaff({this.id, this.name, this.image});

  factory FavouriteStaff.fromJson(Map<String, dynamic> json) {
    return FavouriteStaff(
      id: json['id']?.toString(),
      name: json['name']?['full'] ?? json['name']?['userPreferred'],
      image: json['image']?['large'],
    );
  }
}

class FavouriteStudio {
  String? id;
  String? name;

  FavouriteStudio({this.id, this.name});

  factory FavouriteStudio.fromJson(Map<String, dynamic> json) {
    return FavouriteStudio(
      id: json['id']?.toString(),
      name: json['name'],
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
