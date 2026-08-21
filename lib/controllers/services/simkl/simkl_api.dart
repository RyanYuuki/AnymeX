import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SimklApi {
  NetworkManager get _net => Get.find<NetworkManager>();
  http.Client get _client => _net.compatibleClient;

  String? get _clientId => dotenv.env['SIMKL_CLIENT_ID'];

  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final id = params.id;
    final newId = id.split('*').first;
    final isSeries = id.split('*').last == "SERIES";
    final resp = await _client.get(Uri.parse(
        "https://api.simkl.com/${isSeries ? 'tv' : 'movies'}/$newId?extended=full&client_id=$_clientId"));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      data['id'] = '$newId*${isSeries ? "SERIES" : "MOVIE"}';
      data['__isMovie'] = !isSeries;

      if (isSeries &&
          data['next_episode'] == null &&
          (data['status']?.toString().toLowerCase() == 'airing' ||
              data['status']?.toString().toLowerCase() == 'returning series')) {
        try {
          final epResp = await _client.get(
              Uri.parse("https://api.simkl.com/tv/episodes/$newId?client_id=$_clientId"));
          if (epResp.statusCode == 200) {
            data['episodes'] = jsonDecode(epResp.body);
          }
        } catch (e) {
          Logger.i("Failed to fetch episodes for Simkl series $newId: $e");
        }
      }

      final tmdbId = data['ids']?['tmdb']?.toString();
      final tmdbApiKey = dotenv.env['TMDB_API_KEY'];
      if (tmdbId != null &&
          tmdbId.isNotEmpty &&
          tmdbApiKey != null &&
          tmdbApiKey.isNotEmpty) {
        try {
          final creditsResp = await _client.get(Uri.parse(
              "https://api.themoviedb.org/3/${isSeries ? 'tv' : 'movie'}/$tmdbId/credits?api_key=$tmdbApiKey"));
          if (creditsResp.statusCode == 200) {
            data['tmdb_credits'] = jsonDecode(creditsResp.body);
          }
        } catch (e) {
          Logger.i("Failed to fetch TMDb credits for $tmdbId: $e");
        }
      }

      return Media.fromSimkl(data, !isSeries);
    } else {
      throw Exception('Failed to fetch details: ${resp.statusCode}');
    }
  }

  Future<List<Media>> fetchTrending(bool isMovie) async {
    final path = isMovie ? 'movies' : 'tv';
    final url =
        "https://api.simkl.com/$path/trending?extended=overview&client_id=$_clientId${isMovie ? '&perPage=20' : ''}";
    final resp = await _client.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Media.fromSimkl(e, isMovie)).toList();
    }
    return [];
  }

  Future<List<Media>> fetchGenres(String type, String country) async {
    final endpoint = type == 'tv' ? 'tv' : 'movies';
    final url = type == 'tv'
        ? "https://api.simkl.com/$endpoint/genres/all/all-types/$country/all-networks/all-years/rank?extended=overview&client_id=$_clientId&limit=20"
        : "https://api.simkl.com/$endpoint/genres/all/all-types/$country/all-years/rank?extended=overview&client_id=$_clientId&limit=20";
    final resp = await _client.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Media.fromSimkl(e, type != 'tv')).toList();
    }
    return [];
  }

  Future<List<Media>> searchMedia(String category, String query, {int page = 1}) async {
    final uri = Uri.https('api.simkl.com', '/search/$category', {
      'q': query,
      'extended': 'full',
      'page': '$page',
      'limit': '25',
      'client_id': '$_clientId',
    });
    final resp = await _client.get(uri);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Media.fromSimklSearch(e)).toList();
    }
    return [];
  }

  Future<List<dynamic>> fetchUserItems(String category, String token) async {
    final response = await _client.get(
      Uri.parse('https://api.simkl.com/sync/all-items/$category'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'simkl-api-key': '$_clientId',
      },
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded[category] != null) {
        return decoded[category] as List<dynamic>;
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchUserSettings(String token) async {
    final response = await _client.get(
      Uri.parse('https://api.simkl.com/users/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'simkl-api-key': '$_clientId',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchUserStats(String token) async {
    final response = await _client.get(
      Uri.parse('https://api.simkl.com/users/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'simkl-api-key': '$_clientId',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> postSyncData(String endpoint, Map<String, dynamic> body, String token) async {
    final response = await _client.post(
      Uri.parse('https://api.simkl.com/sync/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'simkl-api-key': '$_clientId',
      },
      body: jsonEncode(body),
    );
    return response.statusCode == 200;
  }
}
