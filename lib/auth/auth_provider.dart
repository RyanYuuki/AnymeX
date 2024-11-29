import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class AniListProvider with ChangeNotifier {
  final storage = Hive.box('login-data');
  dynamic _userData = {};
  bool _isLoading = false;

  dynamic get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    final token = await storage.get('auth_token');
    if (token != null) {
      await fetchUserProfile();
      notifyListeners();
    }
    await fetchAnilistHomepage();
    await fetchAnilistMangaPage();
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    String clientId = dotenv.get('CLIENT_ID');
    String clientSecret = dotenv.get('CLIENT_SECRET');
    String redirectUri = dotenv.get('REDIRECT_URL');

    final url =
        'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code';

    try {
      final result = await FlutterWebAuth2.authenticate(
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
      await storage.put('auth_token', token);
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
    final token = await storage.get('auth_token');
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

  Future<void> updateMangaList({
    required int mangaId,
    required int chapterProgress,
    required double rating,
    required String status,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.get('auth_token');
    const String mutation = '''
  mutation UpdateMediaList(\$mangaId: Int, \$progress: Int, \$score: Float, \$status: MediaListStatus) {
    SaveMediaListEntry(mediaId: \$mangaId, progress: \$progress, score: \$score, status: \$status) {
      id
      status
      progress
      score
    }
  }
  ''';

    final Map<String, dynamic> variables = {
      'mangaId': mangaId,
      'progress': chapterProgress,
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
        log('Manga list updated successfully: ${data['data']}');
        await fetchUserMangaList();
      }
    } else {
      log('Failed to update manga list. Status code: ${response.statusCode}');
      log('Response body: ${response.body}');
    }
    notifyListeners();
  }

  Future<void> deleteMangaFromList({
    required int mangaId,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.get('auth_token');

    const String query = '''
  query GetMangaListEntryId(\$mediaId: Int) {
    MediaList(mediaId: \$mediaId) {
      id
    }
  }
  ''';

    final responseId = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': query,
        'variables': {'mediaId': mangaId},
      }),
    );

    if (responseId.statusCode != 200) {
      log('Failed to fetch media list entry ID. Status code: ${responseId.statusCode}');
      log('Response body: ${responseId.body}');
      return;
    }

    final dataId = jsonDecode(responseId.body);
    if (dataId['errors'] != null || dataId['data']['MediaList'] == null) {
      log('Error fetching media list entry ID: ${dataId['errors']}');
      return;
    }

    final int mediaListEntryId = dataId['data']['MediaList']['id'];

    const String mutation = '''
  mutation DeleteMangaEntry(\$id: Int) {
    DeleteMediaListEntry(id: \$id) {
      deleted
    }
  }
  ''';

    final responseDelete = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': mutation,
        'variables': {'id': mediaListEntryId},
      }),
    );

    if (responseDelete.statusCode == 200) {
      final dataDelete = jsonDecode(responseDelete.body);
      if (dataDelete['errors'] != null) {
        log('Error deleting manga: ${dataDelete['errors']}');
      } else {
        log('Manga deleted successfully: ${dataDelete['data']}');
        await fetchUserMangaList();
      }
    } else {
      log('Failed to delete manga. Status code: ${responseDelete.statusCode}');
      log('Response body: ${responseDelete.body}');
    }

    notifyListeners();
  }

  Future<void> deleteAnimeFromList({
    required int animeId,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.get('auth_token');

    const String query = '''
  query GetAnimeListEntryId(\$mediaId: Int) {
    MediaList(mediaId: \$mediaId) {
      id
    }
  }
  ''';

    final responseId = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': query,
        'variables': {'mediaId': animeId},
      }),
    );

    if (responseId.statusCode != 200) {
      log('Failed to fetch media list entry ID. Status code: ${responseId.statusCode}');
      log('Response body: ${responseId.body}');
      return;
    }

    final dataId = jsonDecode(responseId.body);
    if (dataId['errors'] != null || dataId['data']['MediaList'] == null) {
      log('Error fetching media list entry ID: ${dataId['errors']}');
      return;
    }

    final int mediaListEntryId = dataId['data']['MediaList']['id'];

    // Step 2: Delete the entry using the media list entry ID
    const String mutation = '''
  mutation DeleteAnimeEntry(\$id: Int) {
    DeleteMediaListEntry(id: \$id) {
      deleted
    }
  }
  ''';

    final responseDelete = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': mutation,
        'variables': {'id': mediaListEntryId},
      }),
    );

    if (responseDelete.statusCode == 200) {
      final dataDelete = jsonDecode(responseDelete.body);
      if (dataDelete['errors'] != null) {
        log('Error deleting anime: ${dataDelete['errors']}');
      } else {
        log('Anime deleted successfully: ${dataDelete['data']}');
        await fetchUserAnimeList();
      }
    } else {
      log('Failed to delete anime. Status code: ${responseDelete.statusCode}');
      log('Response body: ${responseDelete.body}');
    }

    notifyListeners();
  }

  Future<void> updateMangaProgress({
    required int mangaId,
    required int chapterProgress,
    required String status,
  }) async {
    const String url = 'https://graphql.anilist.co';
    final token = await storage.get('auth_token');
    const String mutation = '''
  mutation UpdateMediaList(\$mangaId: Int, \$progress: Int, \$status: MediaListStatus) {
    SaveMediaListEntry(mediaId: \$mangaId, progress: \$progress, status: \$status) {
      id
      status
      progress
    }
  }
  ''';

    final Map<String, dynamic> variables = {
      'mangaId': mangaId,
      'progress': chapterProgress,
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
        log('Manga list updated successfully: ${data['data']}');
        await fetchUserMangaList();
      }
    } else {
      log('Failed to update manga list. Status code: ${response.statusCode}');
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
    final token = await storage.get('auth_token');
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

    final token = await storage.get('auth_token');

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
    } else {
      throw Exception('Failed to load AniList data: ${response.statusCode}');
    }
    notifyListeners();
  }

  Future<void> fetchAnilistMangaPage() async {
    const String url = 'https://graphql.anilist.co';

    const String query = '''
  query CombinedMangaQueries(\$perPage: Int) {
    # Popular Mangas (Page 1)
    popularMangas: Page(page: 1, perPage: \$perPage) {
      media(sort: POPULARITY_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        averageScore
      }
    }

    # Popular Mangas (Page 2)
    morePopularMangas: Page(page: 2, perPage: \$perPage) {
      media(sort: POPULARITY_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        averageScore
      }
    }

    # Latest Mangas (Page 1)
    latestMangas: Page(page: 1, perPage: \$perPage) {
      media(sort: START_DATE_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        averageScore
      }
    }

    # Most Favorite Mangas (Page 1)
    mostFavoriteMangas: Page(page: 1, perPage: \$perPage) {
      media(sort: FAVOURITES_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        averageScore
      }
    }

    # Top Rated Mangas (Page 1)
    topRated: Page(page: 1, perPage: \$perPage) {
      media(sort: SCORE_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        chapters
        averageScore
      }
    }

    # Top Updated Mangas (Page 1)
    topUpdated: Page(page: 1, perPage: \$perPage) {
      media(sort: UPDATED_AT_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        chapters
        averageScore
      }
    }

    # Top Ongoing Mangas (Page 1)
    topOngoing: Page(page: 1, perPage: \$perPage) {
      media(status: RELEASING, sort: SCORE_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        chapters
        averageScore
      }
    }

    # Trending Mangas (Page 1)
    trendingManga: Page(page: 1, perPage: \$perPage) {
      media(sort: TRENDING_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        description
        bannerImage
        coverImage {
          large
        }
        averageScore
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
        'variables': {
          'perPage': 10,
        },
      }),
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      _userData['mangaData'] = responseData['data'];
    } else {
      throw Exception(
          'Failed to load AniList manga data: ${response.statusCode}');
    }
    notifyListeners();
  }

  Future<void> fetchUserAnimeList() async {
    _isLoading = true;
    notifyListeners();

    final token = await storage.get('auth_token');
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

    final token = await storage.get('auth_token');
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
              format
              status
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
      if (_userData?['user']?['id'] == null) {
        log('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = _userData?['user']?['id'];
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
          final entries =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();
          log('User manga list fetched successfully');
          log('Fetched ${_userData['mangaList'].length} manga entries');

          _userData['currentlyReading'] = entries
              .where((animeEntry) => animeEntry['status'] == 'CURRENT')
              .toList();
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
    await storage.delete('auth_token');
    _userData = {};
    notifyListeners();
  }
}
