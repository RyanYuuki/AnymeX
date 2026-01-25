import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';

  /// Get anime adaptation details using AniList or MAL ID
  /// Returns AnimeAdaptation object with start/end dates
  static Future<AnimeAdaptation> getAnimeAdaptation(Media media) async {
    try {
      // Determine which ID to use based on service type
      final seriesData = await _getSeriesFromId(media);

      if (seriesData == null || seriesData.isEmpty) {
        return AnimeAdaptation(
          hasAdaptation: false,
          error: 'No series found for this media',
        );
      }

      // Get the first series result
      final series = seriesData[0];

      // Check for anime adaptation
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
      // Not found, return empty list
      return [];
    } else {
      throw Exception('Failed to fetch series: ${response.statusCode}');
    }
  }
}
