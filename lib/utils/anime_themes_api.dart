import 'package:anymex/models/animethemes/anime_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimeThemesAPI {
  static const String baseUrl = 'https://api.animethemes.moe';

  // Searches for anime themes by AniList ID
  // Returns a list of AnimeTheme objects
  // Throws an Exception if the request fails or ID is invalid
  static Future<List<AnimeTheme>> searchAnimeThemes(String aniListId) async {
    try {
      // Parse AniList ID
      final int? aniId = int.tryParse(aniListId.trim());
      if (aniId == null) {
        throw Exception('Please enter a valid AniList ID (numbers only)');
      }

      // Build the API URL with parameters matching the JS implementation
      final uri = Uri.parse('$baseUrl/anime').replace(queryParameters: {
        'filter[has]': 'resources',
        'filter[site]': 'AniList',
        'filter[external_id]': aniId.toString(),
        'fields[video]': 'id,basename,link,tags',
        'fields[audio]': 'id,basename,link,size',
        'include':
            'animethemes.animethemeentries.videos,animethemes.animethemeentries.videos.audio,animethemes.song,animethemes.song.artists',
      });

      //print('API Request URL: $uri');

      final response = await http.get(uri);

      //print('API Response Status: ${response.statusCode}');
      //print('API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'API returned status code: ${response.statusCode}. Response: ${response.body}');
      }

      final data = json.decode(response.body);

      // Handle the anime endpoint response
      if (data['anime'] != null && data['anime'] is List) {
        final animeList = data['anime'] as List;
        if (animeList.isNotEmpty && animeList[0] is Map) {
          final anime = animeList[0] as Map<String, dynamic>;
          final themesData = anime['animethemes'];

          if (themesData != null && themesData is List) {
            final themes = themesData;
            return themes
                .where((theme) => theme is Map)
                .map((theme) =>
                    AnimeTheme.fromJson(theme as Map<String, dynamic>))
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      //print('Detailed error: $e');
      throw Exception('Error searching anime themes: $e');
    }
  }

  // Gets the anime title by AniList ID
  // Returns the anime title or a fallback string if not found
  static Future<String> getAnimeTitle(String aniListId) async {
    try {
      final int? aniId = int.tryParse(aniListId.trim());
      if (aniId == null) return 'Unknown Anime';

      final uri = Uri.parse('$baseUrl/anime').replace(queryParameters: {
        'filter[site]': 'AniList',
        'filter[external_id]': aniId.toString(),
        'fields[anime]': 'name',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['anime'] != null && data['anime'] is List) {
          final animeList = data['anime'] as List;
          if (animeList.isNotEmpty && animeList[0] is Map) {
            final anime = animeList[0] as Map<String, dynamic>;
            return anime['name']?.toString() ?? 'Unknown Anime';
          }
        }
      }

      return 'AniList ID: $aniListId';
    } catch (e) {
      //print('Error getting anime title: $e');
      return 'AniList ID: $aniListId';
    }
  }

  // Gets both anime title and themes in a single call for efficiency
  // Returns a map containing 'title' and 'themes' keys
  static Future<Map<String, dynamic>> getAnimeData(String aniListId) async {
    try {
      final int? aniId = int.tryParse(aniListId.trim());
      if (aniId == null) {
        throw Exception('Please enter a valid AniList ID (numbers only)');
      }

      final uri = Uri.parse('$baseUrl/anime').replace(queryParameters: {
        'filter[has]': 'resources',
        'filter[site]': 'AniList',
        'filter[external_id]': aniId.toString(),
        'fields[video]': 'id,basename,link,tags',
        'fields[audio]': 'id,basename,link,size',
        'fields[anime]': 'name',
        'include':
            'animethemes.animethemeentries.videos,animethemes.animethemeentries.videos.audio,animethemes.song,animethemes.song.artists',
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
            'API returned status code: ${response.statusCode}. Response: ${response.body}');
      }

      final data = json.decode(response.body);

      String title = 'AniList ID: $aniListId';
      List<AnimeTheme> themes = [];

      if (data['anime'] != null && data['anime'] is List) {
        final animeList = data['anime'] as List;
        if (animeList.isNotEmpty && animeList[0] is Map) {
          final anime = animeList[0] as Map<String, dynamic>;

          // Get title
          title = anime['name']?.toString() ?? title;

          // Get themes
          final themesData = anime['animethemes'];
          if (themesData != null && themesData is List) {
            final themesJsonList = themesData;
            themes = themesJsonList
                .where((theme) => theme is Map)
                .map((theme) =>
                    AnimeTheme.fromJson(theme as Map<String, dynamic>))
                .toList();
          }
        }
      }

      return {
        'title': title,
        'themes': themes,
      };
    } catch (e) {
      //print('Error getting anime data: $e');
      rethrow;
    }
  }
}
