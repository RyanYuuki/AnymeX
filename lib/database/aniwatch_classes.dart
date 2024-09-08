class AnimeData {
  final List<String> genres;
  final List<LatestEpisodeAnime> latestEpisodeAnimes;
  final List<SpotlightAnime> spotlightAnimes;
  final Top10Animes top10Animes;
  final List<Anime> topAiringAnimes;
  final List<UpcomingAnime> topUpcomingAnimes;
  final List<TrendingAnime> trendingAnimes;
  final List<PopularAnime> mostPopularAnimes;
  final List<FavoriteAnime> mostFavoriteAnimes;
  final List<CompletedAnime> latestCompletedAnimes;

  AnimeData({
    required this.genres,
    required this.latestEpisodeAnimes,
    required this.spotlightAnimes,
    required this.top10Animes,
    required this.topAiringAnimes,
    required this.topUpcomingAnimes,
    required this.trendingAnimes,
    required this.mostPopularAnimes,
    required this.mostFavoriteAnimes,
    required this.latestCompletedAnimes,
  });

  // Factory method for creating an instance from JSON
  factory AnimeData.fromJson(Map<String, dynamic> json) {
    return AnimeData(
      genres: List<String>.from(json['genres']),
      latestEpisodeAnimes: (json['latestEpisodeAnimes'] as List)
          .map((e) => LatestEpisodeAnime.fromJson(e))
          .toList(),
      spotlightAnimes: (json['spotlightAnimes'] as List)
          .map((e) => SpotlightAnime.fromJson(e))
          .toList(),
      top10Animes: Top10Animes.fromJson(json['top10Animes']),
      topAiringAnimes: (json['topAiringAnimes'] as List)
          .map((e) => Anime.fromJson(e))
          .toList(),
      topUpcomingAnimes: (json['topUpcomingAnimes'] as List)
          .map((e) => UpcomingAnime.fromJson(e))
          .toList(),
      trendingAnimes: (json['trendingAnimes'] as List)
          .map((e) => TrendingAnime.fromJson(e))
          .toList(),
      mostPopularAnimes: (json['mostPopularAnimes'] as List)
          .map((e) => PopularAnime.fromJson(e))
          .toList(),
      mostFavoriteAnimes: (json['mostFavoriteAnimes'] as List)
          .map((e) => FavoriteAnime.fromJson(e))
          .toList(),
      latestCompletedAnimes: (json['latestCompletedAnimes'] as List)
          .map((e) => CompletedAnime.fromJson(e))
          .toList(),
    );
  }
}

class LatestEpisodeAnime {
  final String id;
  final String name;
  final String poster;
  final String type;
  final Episodes episodes;

  LatestEpisodeAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.type,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory LatestEpisodeAnime.fromJson(Map<String, dynamic> json) {
    return LatestEpisodeAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      type: json['type'],
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class SpotlightAnime {
  final String id;
  final String name;
  final String jname;
  final String poster;
  final String description;
  final int rank;
  final List<String> otherInfo;
  final Episodes episodes;

  SpotlightAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.description,
    required this.rank,
    required this.otherInfo,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory SpotlightAnime.fromJson(Map<String, dynamic> json) {
    return SpotlightAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      description: json['description'],
      rank: json['rank'],
      otherInfo: List<String>.from(json['otherInfo']),
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class Top10Animes {
  final List<TopAnime> today;
  final List<TopAnime> month;
  final List<TopAnime> week;

  Top10Animes({
    required this.today,
    required this.month,
    required this.week,
  });

  // Factory method for creating an instance from JSON
  factory Top10Animes.fromJson(Map<String, dynamic> json) {
    return Top10Animes(
      today: (json['today'] as List).map((e) => TopAnime.fromJson(e)).toList(),
      month: (json['month'] as List).map((e) => TopAnime.fromJson(e)).toList(),
      week: (json['week'] as List).map((e) => TopAnime.fromJson(e)).toList(),
    );
  }
}

class TopAnime {
  final Episodes episodes;
  final String id;
  final String name;
  final String poster;
  final int rank;

  TopAnime({
    required this.episodes,
    required this.id,
    required this.name,
    required this.poster,
    required this.rank,
  });

  // Factory method for creating an instance from JSON
  factory TopAnime.fromJson(Map<String, dynamic> json) {
    return TopAnime(
      episodes: Episodes.fromJson(json['episodes']),
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      rank: json['rank'],
    );
  }
}

class Anime {
  final String id;
  final String name;
  final String jname;
  final String poster;

  Anime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
  });

  // Factory method for creating an instance from JSON
  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
    );
  }
}

class UpcomingAnime {
  final String id;
  final String name;
  final String poster;
  final String duration;
  final String type;
  final String rating;
  final Episodes episodes;

  UpcomingAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.duration,
    required this.type,
    required this.rating,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory UpcomingAnime.fromJson(Map<String, dynamic> json) {
    return UpcomingAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      duration: json['duration'],
      type: json['type'],
      rating: json['rating'],
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class TrendingAnime {
  final String id;
  final String name;
  final String poster;
  final int rank;

  TrendingAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.rank,
  });

  // Factory method for creating an instance from JSON
  factory TrendingAnime.fromJson(Map<String, dynamic> json) {
    return TrendingAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      rank: json['rank'],
    );
  }
}

class PopularAnime {
  final String id;
  final String name;
  final String poster;
  final String type;
  final Episodes episodes;

  PopularAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.type,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory PopularAnime.fromJson(Map<String, dynamic> json) {
    return PopularAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      type: json['type'],
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class FavoriteAnime {
  final String id;
  final String name;
  final String poster;
  final String type;
  final Episodes episodes;

  FavoriteAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.type,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory FavoriteAnime.fromJson(Map<String, dynamic> json) {
    return FavoriteAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      type: json['type'],
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class CompletedAnime {
  final String id;
  final String name;
  final String poster;
  final String type;
  final Episodes episodes;

  CompletedAnime({
    required this.id,
    required this.name,
    required this.poster,
    required this.type,
    required this.episodes,
  });

  // Factory method for creating an instance from JSON
  factory CompletedAnime.fromJson(Map<String, dynamic> json) {
    return CompletedAnime(
      id: json['id'],
      name: json['name'],
      poster: json['poster'],
      type: json['type'],
      episodes: Episodes.fromJson(json['episodes']),
    );
  }
}

class Episodes {
  final int count;
  final int total;
  final int progress;

  Episodes({
    required this.count,
    required this.total,
    required this.progress,
  });

  // Factory method for creating an instance from JSON
  factory Episodes.fromJson(Map<String, dynamic> json) {
    return Episodes(
      count: json['count'],
      total: json['total'],
      progress: json['progress'],
    );
  }
}
