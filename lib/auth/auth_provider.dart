import 'dart:convert';
import 'dart:developer';
import 'package:aurora/components/anilistExclusive/mappingMethod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

class AniListProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  dynamic _userData = {};
  bool _isLoading = false;

  dynamic get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      await fetchUserProfile();
    }
    await fetchAnilistHomepage();
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    String clientId = dotenv.get('CLIENT_ID');
    String clientSecret = dotenv.get('CLIENT_SECRET');
    String redirectUri = dotenv.get('REDIRECT_URL');

    final url =
        'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code';

    try {
      final result = await FlutterWebAuth.authenticate(
        url: url,
        callbackUrlScheme: 'anymex',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(
            code, clientId, clientSecret, redirectUri, context);
      }
    } catch (e) {
      log('Error during login: $e');
    }
  }

  Future<void> _exchangeCodeForToken(String code, String clientId,
      String clientSecret, String redirectUri, BuildContext context) async {
    final response = await http.post(
      Uri.parse('https://anilist.co/api/v2/oauth/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'code': code,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      await storage.write(key: 'auth_token', value: token);
      await fetchUserProfile();
    } else {
      throw Exception('Failed to exchange code for token: ${response.body}');
    }
  }

  Future<void> updateAnimeList({
    required int animeId,
    required int episodeProgress,
    required double rating,
    required String status,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.read(key: 'auth_token');
    const String mutation = '''
  mutation UpdateMediaList(\$animeId: Int, \$progress: Int, \$score: Float, \$status: MediaListStatus) {
    SaveMediaListEntry(mediaId: \$animeId, progress: \$progress, score: \$score, status: \$status) {
      id
      status
      progress
      score
    }
  }
  ''';

    final Map<String, dynamic> variables = {
      'animeId': animeId,
      'progress': episodeProgress,
      'score': rating,
      'status': status.toUpperCase(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': mutation,
        'variables': variables,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        log('Error: ${data['errors']}');
      } else {
        log('Anime list updated successfully: ${data['data']}');
        await fetchUserAnimeList();
      }
    } else {
      log('Failed to update anime list. Status code: ${response.statusCode}');
      log('Response body: ${response.body}');
    }
    notifyListeners();
  }

  Future<void> updateAnimeProgress({
    required int animeId,
    required int episodeProgress,
    required String status,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.read(key: 'auth_token');
    const String mutation = '''
  mutation UpdateMediaList(\$animeId: Int, \$progress: Int, \$status: MediaListStatus) {
    SaveMediaListEntry(mediaId: \$animeId, progress: \$progress, status: \$status) {
      id
      status
      progress
    }
  }
  ''';

    final Map<String, dynamic> variables = {
      'animeId': animeId,
      'progress': episodeProgress,
      'status': status.toUpperCase(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': mutation,
        'variables': variables,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        log('Error: ${data['errors']}');
      } else {
        log('Anime list updated successfully: ${data['data']}');
        await fetchUserAnimeList();
      }
    } else {
      log('Failed to update anime list. Status code: ${response.statusCode}');
      log('Response body: ${response.body}');
    }
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      log('No token found');
      _isLoading = false;
      notifyListeners();
      return;
    }

    const query = '''
    query {
    Viewer {
      id
      name
      avatar {
        large
      }
      statistics {
        anime {
          count
          episodesWatched
          meanScore
          minutesWatched
        }
        manga {
          count
          chaptersRead
          volumesRead
          meanScore
        }
      }
    }
  }
  ''';

    try {
      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userData['user'] = data['data']['Viewer'];
        log('User profile fetched successfully');
        await fetchUserAnimeList();
        await fetchUserMangaList();
      } else {
        log('Failed to load user profile: ${response.statusCode}');
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      log('Error fetching user profile: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAnilistHomepage() async {
    const String url = 'https://graphql.anilist.co';

    const String query = '''
  query {
    upcomingAnimes: Page(page: 1, perPage: 10) {
      media(type: ANIME, status: NOT_YET_RELEASED) {
        id
        title {
          romaji
          english
          native
        }
        averageScore
        coverImage {
          large
        }
      }
    }
    popularAnimes: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: POPULARITY_DESC) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    trendingAnimes: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: TRENDING_DESC) {
        id
        title {
          romaji
          english
          native
        }
        description
        bannerImage
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Today: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Week: Page(page: 2, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Month: Page(page: 3, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    latestAnimes: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [START_DATE]) {
        id
        title {
          romaji
          english
          native
        }
        averageScore
        coverImage {
          large
        }
      }
    }
  }
  ''';

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'query': query,
      }),
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      _userData['data'] = responseData['data'];
      log(responseData['data'].toString());
    } else {
      throw Exception('Failed to load AniList data: ${response.statusCode}');
    }
    notifyListeners();
  }

  Future<void> fetchUserAnimeList() async {
    _isLoading = true;
    notifyListeners();

    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    const query = '''
  query GetUserAnimeList(\$userId: Int) {
    MediaListCollection(userId: \$userId, type: ANIME) {
      lists {
        name
        entries {
          media {
            id
            title {
              romaji
              english
              native
            }
            format
            episodes
            averageScore
            coverImage {
              large
            }
          }
          progress
          status
        }
      }
    }
  }
  ''';

    try {
      if (_userData['user']['id'] == null) {
        log('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = _userData['user']['id'];
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': query,
          'variables': {
            'userId': userId,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null &&
            data['data']['MediaListCollection'] != null) {
          final lists =
              data['data']['MediaListCollection']['lists'] as List<dynamic>;

          final animeList =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();

          _userData['currentlyWatching'] = animeList
              .where((animeEntry) => animeEntry['status'] == 'CURRENT')
              .toList();

          _userData['animeList'] = animeList;
          log('User anime list fetched successfully');
          log('Fetched ${_userData['animeList'].length} anime entries');
          log('Fetched ${_userData['currentlyWatching'].length} currently watching entries');
          log(_userData['currentlyWatching']);
        } else {
          log('Unexpected response structure: ${response.body}');
        }
      } else {
        log('Fetch failed with status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Failed to load anime list: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserMangaList() async {
    _isLoading = true;
    notifyListeners();

    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    const query = '''
    query GetUserMangaList(\$userId: Int) {
      MediaListCollection(userId: \$userId, type: MANGA) {
        lists {
          name
          entries {
            media {
              id
              title {
                romaji
                english
                native
              }
              chapters
              volumes
              format
              genres
              status
              averageScore
              coverImage {
                large
              }
            }
            progress
            status
          }
        }
      }
    }
    ''';

    try {
      if (_userData['user']['id'] == null) {
        log('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = _userData['user']['id'];
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': query,
          'variables': {
            'userId': userId,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null &&
            data['data']['MediaListCollection'] != null) {
          final lists =
              data['data']['MediaListCollection']['lists'] as List<dynamic>;
          _userData['mangaList'] =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();
          log('User manga list fetched successfully');
          log('Fetched ${_userData['mangaList'].length} manga entries');
          log(data['data']['MediaListCollection']['lists']);
        } else {
          log('Unexpected response structure: ${response.body}');
        }
      } else {
        log('Fetch failed with status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Failed to load manga list: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await storage.delete(key: 'auth_token');
    _userData = {};
    notifyListeners();
  }
}
