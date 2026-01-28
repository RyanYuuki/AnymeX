import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';

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

  /// Get Estimated Next Chapter Release and Number
  static Future<NextRelease> getNextChapterPrediction(Media media) async {
    // 1. Basic Status Check (Case insensitive)
    if (media.status?.toUpperCase() != 'RELEASING') {
      return NextRelease(error: 'Series is not releasing');
    }

    try {
      // 2. Fetch MangaUpdates ID via MangaBaka
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

      // 3. Fetch Release Page
      final url =
          'https://www.mangaupdates.com/releases/archive?search=$muId&search_type=series';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load release info');
      }

      // 4. Regex to capture Date (Group 1) and Chapter (Group 2)
      // Pattern looks for the Date column, skips the volume column, and grabs the chapter column
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
            // Save the chapter from the very first (newest) match only
            if (latestChapterStr == null &&
                chapterStr != null &&
                chapterStr.isNotEmpty) {
              latestChapterStr = chapterStr;
            }
          } catch (e) {
            // skip invalid dates
          }
        }
      }

      if (releaseDates.length < 2) {
        return NextRelease(error: 'Insufficient data');
      }

      // 5. Calculate Prediction
      // Take only the last 7-10 releases for recency bias
      int sampleSize = releaseDates.length > 8 ? 8 : releaseDates.length;
      List<int> intervals = [];

      for (int i = 0; i < sampleSize - 1; i++) {
        final diff = releaseDates[i].difference(releaseDates[i + 1]).inDays;
        // Filter out anomalies (e.g., mass releases of 0 days or gaps > 1 year)
        if (diff > 0 && diff < 365) {
          intervals.add(diff);
        }
      }

      if (intervals.isEmpty) {
        return NextRelease(error: 'Irregular release schedule');
      }

      // Average Interval
      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      int roundedInterval = avgInterval.round();

      // Predict Date
      DateTime latestRelease = releaseDates[0];
      DateTime predictedDate =
          latestRelease.add(Duration(days: roundedInterval));

      // Predict Chapter Number
      String nextChapterName = "Next Chapter";
      if (latestChapterStr != null) {
        // Try to parse number from string like "106", "c.106", "106.5"
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

  // Private helper method to get series data from AniList or MAL ID
  static Future<List<dynamic>?> _getSeriesFromId(Media media) async {
    String endpoint;

    // Determine which endpoint to use based on service type
    switch (media.serviceType) {
      case ServicesType.anilist:
        endpoint = '$_baseUrl/source/anilist/${media.id}';
        break;
      case ServicesType.mal:
        endpoint = '$_baseUrl/source/my-anime-list/${media.idMal ?? media.id}';
        break;
      default:
        // For extensions or other services, try AniList ID if available
        if (media.id != null) {
          endpoint = '$_baseUrl/source/anilist/${media.id}';
        } else {
          return null;
        }
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
