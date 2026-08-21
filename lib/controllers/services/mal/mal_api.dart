import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MalApi {
  NetworkManager get _net => Get.find<NetworkManager>();
  http.Client get _client => _net.compatibleClient;

  static const String _defaultFields =
      "fields=mean,status,media_type,synopsis";

  static const String _fullFields =
      "fields=mean,status,media_type,synopsis,genres,type,num_episodes,num_chapters,studio,start_date,end_date,source,rating,rank,popularity,favorites,studios,statistics,recommendations";

  static const String _searchFields =
      "id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_episodes,status,genres,num_chapters,num_volumes,media_type,start_season,average_episode_duration,studios";

  Future<dynamic> request(String url, {bool useAuthHeader = false, String? token}) async {
    try {
      final clientId = dotenv.env['MAL_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        throw Exception('MAL_CLIENT_ID is not set in .env file.');
      }
      final tokenn = token ?? AuthKeys.malAuthToken.get<String?>();
      final useAuth = useAuthHeader && tokenn != null && tokenn.isNotEmpty;
      final response = await _client.get(
        Uri.parse(url),
        headers: useAuth
            ? {'Authorization': 'Bearer $tokenn'}
            : {'X-MAL-CLIENT-ID': clientId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        Logger.i('Failed to fetch data from $url: ${response.statusCode}');
        throw Exception('Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      Logger.i('Error fetching data from API: $e');
      return null;
    }
  }

  Future<List<Media>> fetchRanking(String url, {String? customFields}) async {
    final newField = customFields ?? _defaultFields;
    final data = await request('$url&$newField') as Map<String, dynamic>?;
    if (data == null || data['data'] == null) return [];
    final isManga = url.contains('/manga/');
    return (data['data'] as List<dynamic>)
        .map((e) => Media.fromMAL(e, isManga: isManga))
        .toList()
        .removeDupes();
  }

  Future<Media> fetchDetails(String url) async {
    final data = await request('$url?$_fullFields') as Map<String, dynamic>;
    final isManga = url.contains('/manga/');
    return Media.fromFullMAL(data, isManga: isManga);
  }

  Future<List<Media>> search(SearchParams params) async {
    final mediaType = params.isManga ? 'manga' : 'anime';
    final offset = (params.page - 1) * 25;
    final token = AuthKeys.malAuthToken.get<String?>();
    final isLoggedIn = token != null && token.isNotEmpty;
    final showNsfw = params.args == true;
    final url =
        'https://api.myanimelist.net/v2/$mediaType?q=${Uri.encodeComponent(params.query)}&limit=25&offset=$offset&fields=$_searchFields${showNsfw ? '&nsfw=true' : ''}';

    try {
      final data = await request(url, useAuthHeader: isLoggedIn);
      if (data != null && data['data'] != null) {
        return (data['data'] as List<dynamic>)
            .map((e) => Media.fromMAL(e, isManga: params.isManga))
            .toList()
            .removeDupes();
      }
      return [];
    } catch (e) {
      Logger.i('MAL search failed: $e');
      return [];
    }
  }

  Future<List<TrackedMedia>> fetchUserList({required bool isAnime}) async {
    final endpoint = isAnime ? 'animelist' : 'mangalist';
    final fieldName = isAnime ? 'num_episodes' : 'num_chapters';
    final data = await request(
      'https://api.myanimelist.net/v2/users/@me/$endpoint?fields=$fieldName,mean,list_status&limit=1000&sort=list_updated_at&nsfw=1',
      useAuthHeader: true,
    );
    if (data == null || data['data'] == null) return [];
    return (data['data'] as List<dynamic>)
        .map((e) => TrackedMedia.fromMAL(e))
        .toList();
  }

  Future<Profile?> fetchUserInfo({String? token}) async {
    final tokenn = token ?? AuthKeys.malAuthToken.get<String?>();
    final data = await request(
      'https://api.myanimelist.net/v2/users/@me?fields=anime_statistics,manga_statistics',
      useAuthHeader: true,
      token: tokenn,
    );
    if (data == null) return null;
    return Profile.fromMAL(data);
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('https://api.myanimelist.net/v2/users/@me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      Logger.i("Token validation failed: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> refreshToken(String refreshToken, String clientId, String clientSecret) async {
    final response = await _client.post(
      Uri.parse('https://myanimelist.net/v1/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String codeVerifier,
    required String secret,
  }) async {
    final response = await _client.post(
      Uri.parse('https://myanimelist.net/v1/oauth2/token'),
      body: {
        'client_id': clientId,
        'code': code,
        'client_secret': secret,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<bool> updateListEntry({
    required String listId,
    required bool isAnime,
    required Map<String, String> body,
    required String token,
  }) async {
    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');
    final response = await _client.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteListEntry({
    required String listId,
    required bool isAnime,
    required String token,
  }) async {
    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');
    final response = await _client.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    return response.statusCode == 200;
  }
}
