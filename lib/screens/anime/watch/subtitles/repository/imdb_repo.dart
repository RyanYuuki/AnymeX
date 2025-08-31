import 'dart:convert';
import 'package:anymex/screens/anime/watch/subtitles/model/imdb_item.dart';
import 'package:anymex/utils/logger.dart';
import 'package:http/http.dart' as http;

class ImdbRepo {
  static const String baseUrl = 'https://api.imdbapi.dev/search/titles';

  static Future<List<ImdbItem>> searchTitles(String query) async {
    final url = Uri.parse('$baseUrl?query=$query');

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      final List<dynamic> results = data['titles'] ?? [];

      return results.map((e) => ImdbItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load IMDb data: ${res.statusCode}');
    }
  }

  static Future<List<ImdbEpisode>?> getEpisodes(String id) async {
    final url = Uri.parse('https://api.imdbapi.dev/titles/$id/episodes');

    Logger.d('Loading IMDb data for ${url.toString()}');

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      final List<dynamic> results = data['episodes'] ?? [];

      return results.map((e) => ImdbEpisode.fromJson(e)).toList();
    } else {
      Logger.e('Failed to load IMDb data: ${res.body}');
      return null;
    }
  }
}
