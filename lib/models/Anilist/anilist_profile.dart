class AnilistProfile {
  String? id;
  String? name;
  String? avatar;
  AnilistProfileStatistics? stats;

  AnilistProfile({this.id, this.name, this.avatar, this.stats});
}

class AnilistProfileStatistics {
  AnimeStats? animeStats;
  MangaStats? mangaStats;

  AnilistProfileStatistics({this.animeStats, this.mangaStats});
}

class AnimeStats {
  String? animeCount;
  String? episodesWatched;
  String? meanScore;
  String? minutesWatched;

  AnimeStats(
      {this.animeCount,
      this.episodesWatched,
      this.meanScore,
      this.minutesWatched});
}

class MangaStats {
  String? mangaCount;
  String? chaptersRead;
  String? volumesRead;
  String? meanScore;

  MangaStats(
      {this.mangaCount, this.chaptersRead, this.volumesRead, this.meanScore});
}
