import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class AniListProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final Box _loginDataBox =
      Hive.box('login-data'); 
  dynamic _userData = {};
  bool _isLoading = false;

  dynamic get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      await fetchUserProfile();
    } else {
      final lastSession = _loginDataBox.get('last_session');
      if (lastSession != null) {
        _userData = lastSession;
        notifyListeners();
      }
    }
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
      print('Error during login: $e');
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

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final token = await storage.read(key: 'auth_token');
    if (token == null) {
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
          minutesWatched
          episodesWatched
        }
        manga {
          count
          chaptersRead
        }
      }
    }
  }
  ''';

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
      _userData = data['data']['Viewer'];

      // Save the newly fetched user data into Hive for future sessions
      await _loginDataBox.put('last_session', _userData);
      log('User profile fetched and saved');
    } else {
      throw Exception('Failed to load user profile');
    }

    _isLoading = false;
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
              episodes
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
      if (_userData['id'] == null) {
        log('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = _userData['id'];
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
          _userData['animeList'] =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();
          log('User anime list fetched successfully');
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
      if (_userData['id'] == null) {
        log('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = _userData['id'];
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
    await _loginDataBox.delete('last_session'); // Remove session data on logout
    notifyListeners();
  }
}
