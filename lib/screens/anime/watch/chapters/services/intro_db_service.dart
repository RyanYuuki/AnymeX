import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/screens/anime/watch/chapters/models/playback_chapter.dart';

class IntroDbService {
  static const String theIntroDbUrl = 'https://api.theintrodb.org/v4/media';
  static const String introDbAppUrl = 'https://api.introdb.app/segments';

  static Future<List<PlaybackSkipSegment>> fetchSegments({
    String? imdbId,
    int? tvdbId,
    int? tmdbId,
    int season = 1,
    required int episode,
    int? durationMs,
    bool isMovie = false,
  }) async {
    if (imdbId != null && imdbId.isNotEmpty) {
      final appStamps = await _fetchIntroDbApp(imdbId, season, episode);
      if (appStamps.isNotEmpty) return appStamps;
    }

    final queryList = <Map<String, String>>[
      if (tvdbId != null) {'tvdb_id': '$tvdbId'},
      if (tmdbId != null) {'tmdb_id': '$tmdbId'},
      if (imdbId != null && imdbId.isNotEmpty) {'imdb_id': imdbId},
    ];

    for (final idParam in queryList) {
      final theIntroDbStamps = await _fetchTheIntroDb(
        idParam,
        season,
        episode,
        durationMs,
        isMovie,
      );
      if (theIntroDbStamps.isNotEmpty) return theIntroDbStamps;
    }

    return const [];
  }

  static Future<List<PlaybackSkipSegment>> _fetchIntroDbApp(
    String imdbId,
    int season,
    int episode,
  ) async {
    try {
      final url = '$introDbAppUrl?imdb_id=$imdbId&season=$season&episode=$episode';
      final response = await NetworkManager.instance.compatibleClient
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return const [];
      final dynamic body = jsonDecode(response.body);
      if (body is! Map) return const [];

      final stamps = <PlaybackSkipSegment>[];

      void add(String key, PlaybackSegmentKind kind, String name) {
        final item = body[key];
        if (item is! Map) return;
        final start = (item['start_sec'] as num?)?.toDouble() ?? 0;
        final end = (item['end_sec'] as num?)?.toDouble();
        if (end == null || end <= start) return;
        stamps.add(PlaybackSkipSegment(
          title: name,
          kind: kind,
          startSeconds: start,
          endSeconds: end,
          source: 'IntroDB',
        ));
      }

      add('intro', PlaybackSegmentKind.opening, 'Opening');
      add('outro', PlaybackSegmentKind.ending, 'Ending');
      add('recap', PlaybackSegmentKind.recap, 'Recap');
      stamps.sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
      return stamps;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<PlaybackSkipSegment>> _fetchTheIntroDb(
    Map<String, String> idParam,
    int season,
    int episode,
    int? durationMs,
    bool isMovie,
  ) async {
    try {
      final query = <String, String>{
        ...idParam,
        if (!isMovie) 'season': '$season',
        if (!isMovie) 'episode': '$episode',
        if (durationMs != null && durationMs > 0) 'duration_ms': '$durationMs',
      };
      final uri = Uri.parse(theIntroDbUrl).replace(queryParameters: query);
      final response = await NetworkManager.instance.compatibleClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return const [];
      final dynamic body = jsonDecode(response.body);
      if (body is! Map) return const [];

      final stamps = <PlaybackSkipSegment>[];

      void add(String key, PlaybackSegmentKind kind, String name) {
        final list = body[key];
        if (list is! List) return;
        for (final item in list) {
          if (item is! Map) continue;
          final start = (item['start_ms'] as num?)?.toDouble() ?? 0;
          final end = (item['end_ms'] as num?)?.toDouble();
          if (end == null || end <= start) continue;
          stamps.add(PlaybackSkipSegment(
            title: name,
            kind: kind,
            startSeconds: start / 1000.0,
            endSeconds: end / 1000.0,
            source: 'TheIntroDB',
          ));
        }
      }

      add('intro', PlaybackSegmentKind.opening, 'Opening');
      add('credits', PlaybackSegmentKind.ending, 'Ending');
      add('recap', PlaybackSegmentKind.recap, 'Recap');
      add('preview', PlaybackSegmentKind.preview, 'Preview');
      stamps.sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
      return stamps;
    } catch (_) {
      return const [];
    }
  }
}
