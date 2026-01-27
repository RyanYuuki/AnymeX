import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart'; // Import the new model
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';

  /// Get anime adaptation details
  static Future<AnimeAdaptation> getAnimeAdaptation(Media media) async {
    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) {
        return AnimeAdaptation(hasAdaptation: false, error: 'No series found');
      }

      final series = seriesData[0];
      if (series['has_anime'] == true && series['anime'] != null) {
        final animeData = series['anime'];
        return AnimeAdaptation(
          animeStart: animeData['start'] as String?,
          animeEnd: animeData['end'] as String?,
          hasAdaptation: true,
        );
      }
      return AnimeAdaptation(hasAdaptation: false);
    } catch (error) {
      return AnimeAdaptation(hasAdaptation: false, error: error.toString());
    }
  }

  /// NEW: Get Estimated Next Chapter Release
  static Future<NextRelease> getNextChapterPrediction(Media media) async {
    // 1. Basic Status Check: Only predict for Releasing media
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
      final String? muId = series['source']?['manga_updates']?['id']?.toString();

      if (muId == null) {
        return NextRelease(error: 'MangaUpdates ID missing');
      }

      // 3. Fetch Release Page
      // We look at the series archive page
      final url = 'https://www.mangaupdates.com/releases/archive?search=$muId&search_type=series';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load release info');
      }

      // 4. Parse Dates using Regex (Scraping)
      // Looking for pattern: <div class="col-2 text">2023-12-30</div>
      final RegExp dateRegExp = RegExp(r'class="col-2 text">\s*(\d{4}-\d{2}-\d{2})\s*</div>');
      final matches = dateRegExp.allMatches(response.body);

      List<DateTime> releaseDates = [];
      for (final match in matches) {
        final dateStr = match.group(1);
        if (dateStr != null) {
          try {
            releaseDates.add(DateTime.parse(dateStr));
          } catch (e) {
            // ignore invalid dates
          }
        }
      }

      // Sort Descending (Newest first)
      releaseDates.sort((a, b) => b.compareTo(a));

      // 5. Calculate Prediction
      // We need at least 2 dates to calculate an interval
      if (releaseDates.length < 2) {
        return NextRelease(error: 'Insufficient data');
      }

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

      // Calculate Average Interval
      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      int roundedInterval = avgInterval.round();

      // Next Date = Latest Date + Average Interval
      DateTime latestRelease = releaseDates[0];
      DateTime predictedDate = latestRelease.add(Duration(days: roundedInterval));

      return NextRelease(
        nextReleaseDate: predictedDate,
        averageIntervalDays: roundedInterval,
        lastReleaseDate: "${latestRelease.year}-${latestRelease.month}-${latestRelease.day}",
      );

    } catch (e) {
      return NextRelease(error: e.toString());
    }
  }

  // Helper from previous file (unchanged logic)
  static Future<List<dynamic>?> _getSeriesFromId(Media media) async {
    String endpoint;
    switch (media.serviceType) {
      case ServicesType.anilist:
        endpoint = '$_baseUrl/source/anilist/${media.id}';
        break;
      case ServicesType.mal:
        endpoint = '$_baseUrl/source/my-anime-list/${media.idMal ?? media.id}';
        break;
      default:
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
