import 'dart:convert';
import 'package:anymex/screens/anime/watch/subtitles/model/online_subtitle.dart';
import 'package:http/http.dart' as http;

class SubtitleRepo {
  static const String baseUrl = 'https://sub.wyzie.ru/search';

  static Future<List<OnlineSubtitle>> searchById(String id) async {
    final url = Uri.parse('$baseUrl?id=$id');
    return _fetchSubtitles(url);
  }

  static Future<List<OnlineSubtitle>> searchByEpisode(
    String id, {
    required int season,
    required int episode,
  }) async {
    final url = Uri.parse('$baseUrl?id=$id&season=$season&episode=$episode');
    return _fetchSubtitles(url);
  }

  static Future<List<OnlineSubtitle>> searchByLanguage(
    String id, {
    required String language,
  }) async {
    final url = Uri.parse('$baseUrl?id=$id&language=$language');
    return _fetchSubtitles(url);
  }

  static Future<List<OnlineSubtitle>> searchByFormat(
    String id, {
    required String format,
  }) async {
    final url = Uri.parse('$baseUrl?id=$id&format=$format');
    return _fetchSubtitles(url);
  }

  static Future<List<OnlineSubtitle>> _fetchSubtitles(Uri url) async {
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => OnlineSubtitle.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load subtitles: ${res.statusCode}');
    }
  }
}
