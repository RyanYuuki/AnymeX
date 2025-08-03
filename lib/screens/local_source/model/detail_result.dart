import 'dart:convert';

import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

class DetailResult {
  final String title;
  final List<DetailSeasons> seasons;

  DetailResult({required this.title, required this.seasons});

  factory DetailResult.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? '';
    final String imdbId = json['external_ids']?['imdb_id']?.toString() ?? '';
    final String airDate = json['air_date']?.toString() ?? '';
    final String year = airDate.length >= 4 ? airDate.substring(0, 4) : '';
    final String posterPath = json['poster_path']?.toString() ?? '';
    final String backdropPath = json['backdrop_path']?.toString() ?? '';

    return DetailResult(
      title: json['title']?.toString() ?? json['name'] ?? '',
      seasons: (json['seasons'] as List<dynamic>?) != null
          ? (json['seasons'] as List<dynamic>)
              .where((e) => e['name'].toLowerCase().contains('season'))
              .toList()
              .map((e) => DetailSeasons.fromJson(e, json))
              .toList()
          : [
              DetailSeasons(
                [
                  DetailEpisode(
                    id: jsonEncode({
                      'id': id,
                      'imdbId': imdbId,
                      'year': year,
                    }),
                    poster: 'https://image.tmdb.org/t/p/w500$posterPath',
                    title: 'Movie',
                  )
                ],
                id: '',
                title: 'Movie',
                poster: 'https://image.tmdb.org/t/p/w500$backdropPath',
              ),
            ],
    );
  }

  factory DetailResult.froDMedia(DMedia m) {
    final manga = m..episodes = m.episodes!.reversed.toList();
    final Map<String, List<DEpisode>> seasonMap = {};

    final regex = RegExp(r'S(\d+)\s*·\s*E(\d+)', caseSensitive: false);

    for (final chapter in manga.episodes ?? []) {
      final match = regex.firstMatch(chapter.name ?? '');
      if (match != null) {
        final seasonNumber = match.group(1)!.padLeft(2, '0');
        final key = 'S$seasonNumber';
        seasonMap.putIfAbsent(key, () => []).add(chapter);
      }
    }

    final List<DetailSeasons> seasons = seasonMap.entries.map((entry) {
      final seasonId = entry.key;
      final chapters = entry.value;

      final episodes = chapters.map((chapter) {
        return DetailEpisode(
          id: chapter.url ?? '',
          title: chapter.name ?? '',
          poster: '',
        );
      }).toList();

      return DetailSeasons(
        episodes,
        id: seasonId,
        title: 'Season ${seasonId.substring(1)}',
        poster: '',
      );
    }).toList();

    seasons.sort((a, b) => a.id.compareTo(b.id));

    return DetailResult(
      title: manga.title ?? '',
      seasons: seasons,
    );
  }
}

class DetailSeasons {
  final String id;
  final String title;
  final String poster;
  final List<DetailEpisode> episodes;

  DetailSeasons(this.episodes,
      {required this.id, required this.title, required this.poster});

  factory DetailSeasons.fromJson(
      Map<String, dynamic> json, Map<String, dynamic> fullMap) {
    final String seasonId = json['id']?.toString() ?? '';
    final String seasonTitle = json['name']?.toString() ?? '';
    final String posterPath = json['poster_path']?.toString() ??
        fullMap['backdrop_path']?.toString() ??
        '';
    final String airDate = json['air_date']?.toString() ?? '';
    final String year = airDate.length >= 4 ? airDate.substring(0, 4) : '';
    final String imdbId = fullMap['external_ids']?['imdb_id']?.toString() ?? '';
    final int episodeCount = json['episode_count'] ?? 0;

    List<DetailEpisode> episodes = [];
    for (var i = 1; i <= episodeCount; i++) {
      episodes.add(DetailEpisode(
        id: jsonEncode({
          'id': fullMap['id']?.toString() ?? '',
          'imdbId': imdbId,
          'year': year,
          'season': json['season_number'] ?? '',
          'episode': i,
        }),
        title: 'Episode $i',
        poster: 'https://image.tmdb.org/t/p/w500$posterPath',
      ));
    }

    return DetailSeasons(
      episodes,
      id: seasonId,
      title: seasonTitle,
      poster: 'https://image.tmdb.org/t/p/w500$posterPath',
    );
  }
}

class DetailEpisode {
  final String id;
  final String title;
  final String poster;

  DetailEpisode({
    required this.id,
    required this.title,
    required this.poster,
  });
}
