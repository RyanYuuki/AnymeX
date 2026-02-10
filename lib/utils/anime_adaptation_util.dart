import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:http/http.dart' as http;

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';

  static Future<List<NewsItem>> getMangaNovelNews(Media media) async {
    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) return [];

      final int bakaId = seriesData[0]['id'];

      final response = await http.get(Uri.parse('$_baseUrl/series/$bakaId/news'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? newsData = data['data'];
        if (newsData == null) return [];
        
        return newsData.map((json) => NewsItem.fromMangaBaka(json)).toList();
      }
      return [];
    } catch (e) {
      print("MangaBaka News Error: $e");
      return [];
    }
  }

  static Future<List<NewsItem>> getAnimeNews(Media media) async {
    try {
      // kuroiru uses MAL ID
      final malId = media.idMal.isEmpty ? media.id : media.idMal;
      final response =
          await http.get(Uri.parse('https://kuroiru.co/api/anime/$malId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? newsData = data['news'];
        if (newsData == null) return [];
        final newsList = newsData.map((json) => NewsItem.fromKuroiru(json)).toList();
        newsList.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
        return newsList;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get anime adaptation details using AniList or MAL ID
  static Future<AnimeAdaptation> getAnimeAdaptation(Media media) async {
    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) {
        return AnimeAdaptation(
          hasAdaptation: false,
          error: 'No series found for this media',
        );
      }

      final series = seriesData[0];

      if (series['has_anime'] == true && series['anime'] != null) {
        final animeData = series['anime'];
        final start = animeData['start'] as String?;
        final end = animeData['end'] as String?;

        if (start != null || end != null) {
          return AnimeAdaptation(
            animeStart: start,
            animeEnd: end,
            hasAdaptation: true,
          );
        }
      }
      return AnimeAdaptation(hasAdaptation: false);
    } catch (error) {
      return AnimeAdaptation(
        hasAdaptation: false,
        error: error.toString(),
      );
    }
  }

  static Future<NextRelease> getNextChapterPrediction(Media media) async {
    if (media.status.toUpperCase() != 'RELEASING') {
      return NextRelease(error: 'Series is not releasing');
    }

    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) {
        return NextRelease(error: 'MangaUpdates ID not found');
      }

      final series = seriesData[0];
      final String? muId =
          series['source']?['manga_updates']?['id']?.toString();

      if (muId == null) {
        return NextRelease(error: 'MangaUpdates ID missing');
      }

      final url = 'https://www.mangaupdates.com/series/$muId/one-piece';
      final detailsResponse = await http.get(Uri.parse(url));

      if (detailsResponse.statusCode != 200) {
        throw Exception('Failed to load release info');
      }

      final archiveUrlRegex = RegExp(
        r'<a\s+[^>]*href="([^"]+)"[^>]*>\s*<i>\s*<u>Search for all releases of this series<\/u>\s*<\/i>\s*<\/a>',
        caseSensitive: false,
        multiLine: true,
      );

      final match = archiveUrlRegex.firstMatch(detailsResponse.body);

      String archiveUrl = match != null
          ? "https://www.mangaupdates.com${match.group(1)!.replaceAll('amp;', '')}"
          : "";
      final response = await http.get(Uri.parse(archiveUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load release info');
      }

      final RegExp rowRegExp = RegExp(
        r'class="col-2 text">\s*(\d{4}-\d{2}-\d{2})\s*</div>[\s\S]*?class="col-1 text text-center">[\s\S]*?</div>\s*<div class="col-1 text text-center">\s*(.*?)\s*</div>',
        caseSensitive: false,
      );

      final matches = rowRegExp.allMatches(response.body);
      List<DateTime> releaseDates = [];
      String? latestChapterStr;

      for (final match in matches) {
        final dateStr = match.group(1);
        final chapterStr = match.group(2);

        if (dateStr != null) {
          try {
            releaseDates.add(DateTime.parse(dateStr));
            if (latestChapterStr == null &&
                chapterStr != null &&
                chapterStr.isNotEmpty) {
              latestChapterStr = chapterStr;
            }
          } catch (e) {
            print(e);
          }
        }
      }

      if (releaseDates.length < 2) {
        return NextRelease(error: 'Insufficient data');
      }

      int sampleSize = releaseDates.length > 8 ? 8 : releaseDates.length;
      List<int> intervals = [];

      for (int i = 0; i < sampleSize - 1; i++) {
        final diff = releaseDates[i].difference(releaseDates[i + 1]).inDays;
        if (diff > 0 && diff < 365) {
          intervals.add(diff);
        }
      }

      if (intervals.isEmpty) {
        return NextRelease(error: 'Irregular release schedule');
      }

      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      int roundedInterval = avgInterval.round();

      DateTime latestRelease = releaseDates[0];
      DateTime predictedDate =
          latestRelease.add(Duration(days: roundedInterval));

      String nextChapterName = "Next Chapter";
      if (latestChapterStr != null) {
        final numericMatch =
            RegExp(r'(\d+(?:\.\d+)?)').firstMatch(latestChapterStr);
        if (numericMatch != null) {
          double? chNum = double.tryParse(numericMatch.group(1)!);
          if (chNum != null) {
            if (chNum % 1 == 0) {
              nextChapterName = "Chapter ${chNum.toInt() + 1}";
            } else {
              nextChapterName = "Chapter ${(chNum + 1).toStringAsFixed(1)}";
            }
          }
        }
      }

      return NextRelease(
        nextReleaseDate: predictedDate,
        averageIntervalDays: roundedInterval,
        nextChapter: nextChapterName,
      );
    } catch (e) {
      return NextRelease(error: e.toString());
    }
  }

  static Future<List<dynamic>?> _getSeriesFromId(Media media) async {
    String endpoint;

    switch (media.serviceType) {
      case ServicesType.anilist:
        endpoint = '$_baseUrl/source/anilist/${media.id}';
        break;
      case ServicesType.mal:
        endpoint = '$_baseUrl/source/my-anime-list/${media.idMal}';
        break;
      default:
        endpoint = '$_baseUrl/source/anilist/${media.id}';
    }

    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']?['series'] as List<dynamic>?;
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch series: ${response.statusCode}');
    }
  }
}
