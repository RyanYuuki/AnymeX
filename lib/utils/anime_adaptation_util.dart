import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangaupdates.com/v1';

  /// Get anime adaptation details for a manga title
  /// Returns AnimeAdaptation object with start/end dates
  static Future<AnimeAdaptation> getAnimeAdaptation(String mangaTitle) async {
    try {
      // Search for manga
      final searchResults = await _searchManga(mangaTitle);

      if (searchResults.isEmpty) {
        return AnimeAdaptation(
          hasAdaptation: false,
          error: 'No manga found with title: $mangaTitle',
        );
      }

      // Get series details
      final seriesId = searchResults[0]['record']['series_id'] as int;
      final seriesDetails = await _getSeriesDetails(seriesId);

      // Check for anime adaptation
      if (seriesDetails['anime'] != null) {
        final animeData = seriesDetails['anime'];
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

  // Private helper methods
  static Future<List<dynamic>> _searchManga(String title) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/series/search'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'search': title,
        'type': 'Manga',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Search failed with status: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> _getSeriesDetails(int seriesId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/series/$seriesId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get series details: ${response.statusCode}');
    }
  }
}
