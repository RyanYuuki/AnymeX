// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/missing_sequel/missing_sequel_service.dart';
import 'package:anymex/database/comments/comments_db.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Anilist/social_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class AnilistAuth extends GetxController {
  RxBool isLoggedIn = false.obs;
  Rx<Profile> profileData = Profile().obs;
  final offlineStorage = Get.find<OfflineStorageController>();

  Rx<TrackedMedia> currentMedia = TrackedMedia().obs;

  RxList<TrackedMedia> currentlyWatching = <TrackedMedia>[].obs;
  RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;

  RxList<TrackedMedia> currentlyReading = <TrackedMedia>[].obs;
  RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;
  DateTime? _rateLimitUntil;

  void _handle403(http.Response response) {
    dynamic errorJson;
    try {
      errorJson = jsonDecode(response.body);
    } catch (_) {}

    const base = "Why is it 403";
    final apiMessage = errorJson?['errors']?[0]?['message'] as String?;
    final message = apiMessage != null && apiMessage.isNotEmpty
        ? "$base: $apiMessage"
        : "$base: Forbidden (error 403)";

    throw Exception(message);
  }

  Future<http.Response> _anilistPost({
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    int maxRetries = 3,
  }) async {
    const url = 'https://graphql.anilist.co';
    int attempt = 0;

    while (true) {
      if (_rateLimitUntil != null &&
          DateTime.now().isBefore(_rateLimitUntil!)) {
        final wait = _rateLimitUntil!.difference(DateTime.now());
        if (wait.inMilliseconds > 0) {
          await Future.delayed(wait);
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      final resetEpoch =
          int.tryParse(response.headers['x-ratelimit-reset'] ?? '');
      if (resetEpoch != null && resetEpoch > 0) {
        final resetAt = DateTime.fromMillisecondsSinceEpoch(resetEpoch * 1000);
        if (_rateLimitUntil == null || resetAt.isAfter(_rateLimitUntil!)) {
          _rateLimitUntil = resetAt;
        }
      }

      if (response.statusCode != 429 || attempt >= maxRetries) {
        return response;
      }

      // Parse Retry After header
      final retryAfter = response.headers['retry-after'];
      final waitSeconds = retryAfter != null
          ? (int.tryParse(retryAfter) ?? (2 << attempt))
          : (2 << attempt);

      final retryUntil = DateTime.now().add(Duration(seconds: waitSeconds));
      if (_rateLimitUntil == null || retryUntil.isAfter(_rateLimitUntil!)) {
        _rateLimitUntil = retryUntil;
      }

      Logger.i(
          'AniList 429 rate limit hit, retry ${attempt + 1}/$maxRetries after ${waitSeconds}s');
      await Future.delayed(Duration(seconds: waitSeconds));
      attempt++;
    }
  }

  Future<void> tryAutoLogin() async {
    isLoggedIn.value = false;
    final token = AuthKeys.authToken.get<String?>();
    if (token != null) {
      await fetchUserProfile();
      await fetchUserAnimeList();
      await fetchUserMangaList();

      try {
        final commentumService = Get.find<CommentumService>();
        await commentumService.getUserRole();
      } catch (e) {
        Logger.i('Error checking Commentum role during auto login: $e');
      }
    }
  }

  DateTime? getExpiryFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      String normalizedSource = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalizedSource));
      final Map<String, dynamic> map = json.decode(decoded);

      if (map.containsKey('exp')) {
        return DateTime.fromMillisecondsSinceEpoch(map['exp'] * 1000);
      }
    } catch (e) {
      Logger.i('Error decoding token: $e');
    }
    return null;
  }

  Future<void> login(BuildContext context) async {
    final selectedMethod = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLoginBottomSheet(context),
    );

    if (selectedMethod == null) return;

    String clientId = dotenv.env['AL_CLIENT_ID'] ?? '';
    String clientSecret = dotenv.env['AL_CLIENT_SECRET'] ?? '';

    if (selectedMethod == 'browser') {
      final url =
          'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=anymex://callback&response_type=code';
      try {
        final result = await FlutterWebAuth2.authenticate(
          url: url,
          callbackUrlScheme: 'anymex',
        );
        final code = Uri.parse(result).queryParameters['code'];
        if (code != null) {
          Logger.i("token found");
          await _exchangeCodeForToken(
              code, clientId, clientSecret);
        }
      } catch (e) {
        Logger.i('Error during login: $e');
      }
    } else if (selectedMethod == 'token') {
      _showTokenInputDialog(context);
    }
  }

  Widget _buildLoginBottomSheet(BuildContext context) {
    final theme = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.onSurface.opaque(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Login to AniList',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          _buildButton(
            context,
            onPressed: () => Navigator.pop(context, 'browser'),
            icon: Icons.language,
            label: 'Login from Browser',
          ),
          const SizedBox(height: 16),
          _buildButton(
            context,
            onPressed: () => Navigator.pop(context, 'token'),
            icon: Icons.vpn_key,
            label: 'Login with Token',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    final theme = context.colors;

    return Material(
      color: theme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primary.opaque(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.opaque(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.onPrimaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: theme.onPrimaryContainer.opaque(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTokenInputDialog(BuildContext context) async {
    final TextEditingController tokenController = TextEditingController();
    final theme = context.colors;

    const url =
        'https://anilist.co/api/v2/oauth/authorize?client_id=35224&response_type=token';

    await launchUrlString(url);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Login with Token',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please paste the token from the browser',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: theme.onSurface.opaque(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                hintText: 'Enter token here',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: theme.onSurface.opaque(0.5),
                ),
                filled: true,
                fillColor: theme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: theme.onSurface,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: theme.onSurface.opaque(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = tokenController.text.trim();
              if (token.isNotEmpty) {
                Navigator.pop(context);
                try {
                  AuthKeys.authToken.set(token);
                  await fetchUserProfile();
                  await fetchUserAnimeList();
                  await fetchUserMangaList();
                  try {
                    final commentumService = Get.find<CommentumService>();
                    await commentumService.getUserRole();
                  } catch (e) {
                    Logger.i('Error checking Commentum role: $e');
                  }
                } catch (e) {
                  Logger.i('Error saving token: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: theme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exchangeCodeForToken(
      String code, String clientId, String clientSecret) async {
    final response = await http.post(
      Uri.parse('https://anilist.co/api/v2/oauth/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': "anymex://callback",
        'code': code,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      AuthKeys.authToken.set(token);
      await fetchUserProfile();
      await fetchUserAnimeList();
      await fetchUserMangaList();
      try {
        final commentumService = Get.find<CommentumService>();
        await commentumService.getUserRole();
      } catch (e) {
        Logger.i('Error checking Commentum role: $e');
      }
    } else {
      throw Exception('Failed to exchange code for token: ${response.body}');
    }
  }

  Future<void> fetchUserProfile() async {
    final token = AuthKeys.authToken.get<String?>();

    if (token == null) {
      Logger.i('No token found');
      return;
    }

    const query = '''
  query {
    Viewer {
      id
      name
      about(asHtml: true)
      aboutMarkdown: about
      donatorTier
      donatorBadge
      createdAt
      avatar {
        large
      }
      bannerImage
      statistics {
        anime {
          count
          episodesWatched
          meanScore
          minutesWatched
          standardDeviation
          scores(sort: MEAN_SCORE) { score count meanScore minutesWatched }
          formats { format count meanScore minutesWatched }
          statuses { status count meanScore minutesWatched }
          countries { country count meanScore minutesWatched }
          lengths { length count meanScore minutesWatched }
          releaseYears { releaseYear count meanScore minutesWatched }
          startYears { startYear count meanScore minutesWatched }
          genres(sort: COUNT_DESC) { genre count meanScore minutesWatched }
          tags(sort: COUNT_DESC) { tag { name } count meanScore minutesWatched }
          voiceActors(sort: COUNT_DESC) { voiceActor { id name { full } image { medium } } count meanScore minutesWatched }
          studios(sort: COUNT_DESC) { studio { id name } count meanScore minutesWatched }
          staff(sort: COUNT_DESC) { staff { id name { full } image { medium } } count meanScore minutesWatched }
        }
        manga {
          count
          chaptersRead
          volumesRead
          meanScore
          standardDeviation
          scores(sort: MEAN_SCORE) { score count meanScore chaptersRead }
          formats { format count meanScore chaptersRead }
          statuses { status count meanScore chaptersRead }
          countries { country count meanScore chaptersRead }
          lengths { length count meanScore chaptersRead }
          releaseYears { releaseYear count meanScore chaptersRead }
          startYears { startYear count meanScore chaptersRead }
          genres(sort: COUNT_DESC) { genre count meanScore chaptersRead }
          tags(sort: COUNT_DESC) { tag { name } count meanScore chaptersRead }
          staff(sort: COUNT_DESC) { staff { id name { full } image { medium } } count meanScore chaptersRead }
        }
      }
      favourites {
        anime {
          pageInfo { total }
          nodes {
            id
            title { userPreferred english romaji }
            coverImage { large }
            averageScore
            format
          }
        }
        manga {
          pageInfo { total }
          nodes {
            id
            title { userPreferred english romaji }
            coverImage { large }
            averageScore
            format
          }
        }
        characters {
          nodes {
            id
            name { full }
            image { large medium }
          }
        }
        staff {
          nodes {
            id
            name { full userPreferred }
            image { large }
          }
        }
        studios {
          nodes {
            id
            name
          }
        }
      }
      stats {
        activityHistory {
          date
          amount
          level
        }
      }
      mediaListOptions {
        animeList { splitCompletedSectionByFormat sectionOrder }
        mangaList { splitCompletedSectionByFormat sectionOrder }
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
        final viewerData = data['data']['Viewer'];

        final userProfile = Profile.fromJson(viewerData);
        userProfile.tokenExpiry = getExpiryFromToken(token);
        profileData.value = userProfile;
        isLoggedIn.value = true;

        Get.find<MissingSequelService>().fetchAll();

        Logger.i(
            'User profile fetched: ${userProfile.name} (ID: ${userProfile.id})');

        // fetchFollowersAndFollowing(userProfile.id ?? '');
        CommentsDatabase().login();
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to load user profile: ${response.statusCode}');
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      Logger.i('Error fetching user profile: $e');
    }
  }

  Future<Profile?> fetchUserDetails(int userId) async {
    const query = r'''
  query ($id: Int) {
    User(id: $id) {
      id
      name
      about(asHtml: true)
      aboutMarkdown: about
      donatorTier
      donatorBadge
      isFollowing
      isFollower
      createdAt
      avatar {
        large
      }
      bannerImage
      statistics {
        anime {
          count
          episodesWatched
          meanScore
          minutesWatched
          standardDeviation
          scores(sort: MEAN_SCORE) { score count meanScore minutesWatched }
          formats { format count meanScore minutesWatched }
          statuses { status count meanScore minutesWatched }
          countries { country count meanScore minutesWatched }
          lengths { length count meanScore minutesWatched }
          releaseYears { releaseYear count meanScore minutesWatched }
          startYears { startYear count meanScore minutesWatched }
          genres(sort: COUNT_DESC) { genre count meanScore minutesWatched }
          tags(sort: COUNT_DESC) { tag { name } count meanScore minutesWatched }
          voiceActors(sort: COUNT_DESC) { voiceActor { id name { full } image { medium } } count meanScore minutesWatched }
          studios(sort: COUNT_DESC) { studio { id name } count meanScore minutesWatched }
          staff(sort: COUNT_DESC) { staff { id name { full } image { medium } } count meanScore minutesWatched }
        }
        manga {
          count
          chaptersRead
          volumesRead
          meanScore
          standardDeviation
          scores(sort: MEAN_SCORE) { score count meanScore chaptersRead }
          formats { format count meanScore chaptersRead }
          statuses { status count meanScore chaptersRead }
          countries { country count meanScore chaptersRead }
          lengths { length count meanScore chaptersRead }
          releaseYears { releaseYear count meanScore chaptersRead }
          startYears { startYear count meanScore chaptersRead }
          genres(sort: COUNT_DESC) { genre count meanScore chaptersRead }
          tags(sort: COUNT_DESC) { tag { name } count meanScore chaptersRead }
          staff(sort: COUNT_DESC) { staff { id name { full } image { medium } } count meanScore chaptersRead }
        }
      }
      favourites {
        anime {
          pageInfo { total }
          nodes {
            id
            title { userPreferred english romaji }
            coverImage { large }
            averageScore
            format
          }
        }
        manga {
          pageInfo { total }
          nodes {
            id
            title { userPreferred english romaji }
            coverImage { large }
            averageScore
            format
          }
        }
        characters {
          nodes {
            id
            name { full }
            image { large medium }
          }
        }
        staff {
          nodes {
            id
            name { full userPreferred }
            image { large }
          }
        }
        studios {
          nodes {
            id
            name
          }
        }
      }
      stats {
        activityHistory {
          date
          amount
          level
        }
      }
      mediaListOptions {
        animeList { splitCompletedSectionByFormat sectionOrder }
        mangaList { splitCompletedSectionByFormat sectionOrder }
      }
    }
  }
  ''';

    try {
      final token = AuthKeys.authToken.get<String?>();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'id': userId},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['User'];
        if (userData != null) {
          return Profile.fromJson(userData);
        }
      } else {
        Logger.e('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Error fetching user details: $e');
    }
    return null;
  }

  Future<bool?> toggleFollow(int userId) async {
    const mutation = r'''
  mutation ($userId: Int) {
    ToggleFollow(userId: $userId) {
      isFollowing
    }
  }
  ''';

    try {
      final token = AuthKeys.authToken.get<String?>();
      if (token == null || token.isEmpty) return null;

      final response = await _anilistPost(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'query': mutation,
          'variables': {'userId': userId},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['ToggleFollow']?['isFollowing'] as bool?;
      } else {
        Logger.e('Failed to toggle follow: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Error toggling follow: $e');
    }
    return null;
  }

  Future<Map<String, List<TrackedMedia>>> fetchUserMediaList(
      int userId, String type) async {
    const query = r'''
  query ($userId: Int, $type: MediaType) {
    MediaListCollection(userId: $userId, type: $type, sort: UPDATED_TIME) {
      lists {
        name
        entries {
          status
          score(format: POINT_100)
          progress
          updatedAt
          media {
            id
            type
            format
            status
            episodes
            chapters
            averageScore
            genres
            startDate { year }
            title { english romaji native }
            coverImage { large }
            nextAiringEpisode { episode }
            mediaListEntry { id }
          }
        }
      }
    }
  }
  ''';

    try {
      final token = AuthKeys.authToken.get<String?>();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'userId': userId, 'type': type},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lists =
            data['data']?['MediaListCollection']?['lists'] as List<dynamic>?;
        if (lists == null) return {};

        final result = <String, List<TrackedMedia>>{};
        final allEntries = <TrackedMedia>[];
        for (final list in lists) {
          final name = list['name'] as String? ?? 'Unknown';
          final entries = list['entries'] as List<dynamic>? ?? [];
          final parsed = <TrackedMedia>[];
          for (final entry in entries) {
            if (entry['media'] == null) continue;
            parsed.add(TrackedMedia.fromJson(entry));
          }
          if (parsed.isNotEmpty) {
            result[name] = parsed;
            allEntries.addAll(parsed);
          }
        }
        if (allEntries.isNotEmpty) {
          result['All'] = allEntries;
        }
        return result;
      } else {
        Logger.e('Failed to fetch user media list: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Error fetching user media list: $e');
    }
    return {};
  }

  Future<int?> fetchUserIdByName(String username) async {
    const query = r'''
  query ($name: String) {
    User(name: $name) {
      id
    }
  }
  ''';

    try {
      final token = AuthKeys.authToken.get<String?>();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'name': username},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['User']?['id'] as int?;
      }
    } catch (e) {
      Logger.i('Error resolving AniList user by name ($username): $e');
    }

    return null;
  }

  Future<(List<SocialUser>, bool, int)> fetchFollowingPage(int userId,
      {int page = 1}) async {
    final token = AuthKeys.authToken.get<String?>();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    const query = r'''
  query ($userId: Int!, $page: Int) {
    Page(page: $page, perPage: 50) {
      pageInfo { hasNextPage total }
      following(userId: $userId, sort: USERNAME) {
        id
        name
        avatar { large }
        bannerImage
      }
    }
  }
  ''';

    try {
      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'userId': userId, 'page': page},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pageData = data['data']?['Page'];
        final list = pageData?['following'] as List<dynamic>? ?? [];
        final hasNextPage = pageData?['pageInfo']?['hasNextPage'] == true;
        final totalCount = pageData?['pageInfo']?['total'] as int? ?? 0;
        return (
          list.map((e) => SocialUser.fromJson(e)).toList(),
          hasNextPage,
          totalCount,
        );
      } else {
        Logger.e(
            'fetchFollowing failed: status=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      Logger.e('Error fetching following: $e');
    }
    return (<SocialUser>[], false, 0);
  }

  Future<List<SocialUser>> fetchFollowing(int userId, {int page = 1}) async {
    final (users, _, _) = await fetchFollowingPage(userId, page: page);
    return users;
  }

  Future<(List<SocialUser>, bool, int)> fetchFollowersPage(int userId,
      {int page = 1}) async {
    final token = AuthKeys.authToken.get<String?>();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    const query = r'''
  query ($userId: Int!, $page: Int) {
    Page(page: $page, perPage: 50) {
      pageInfo { hasNextPage total }
      followers(userId: $userId, sort: USERNAME) {
        id
        name
        avatar { large }
        bannerImage
      }
    }
  }
  ''';

    try {
      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'userId': userId, 'page': page},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pageData = data['data']?['Page'];
        final list = pageData?['followers'] as List<dynamic>? ?? [];
        final hasNextPage = pageData?['pageInfo']?['hasNextPage'] == true;
        final totalCount = pageData?['pageInfo']?['total'] as int? ?? 0;
        return (
          list.map((e) => SocialUser.fromJson(e)).toList(),
          hasNextPage,
          totalCount,
        );
      } else {
        Logger.e(
            'fetchFollowers failed: status=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      Logger.e('Error fetching followers: $e');
    }
    return (<SocialUser>[], false, 0);
  }

  Future<List<SocialUser>> fetchFollowers(int userId, {int page = 1}) async {
    final (users, _, _) = await fetchFollowersPage(userId, page: page);
    return users;
  }

  Future<(List<AnilistActivity>, bool)> fetchUserActivities(int userId,
      {int page = 1,
      List<String> typeIn = const [
        'ANIME_LIST',
        'MANGA_LIST',
        'TEXT',
        'MESSAGE'
      ]}) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null || token.isEmpty) return (<AnilistActivity>[], false);

    const query = r'''
  query ($userId: Int, $page: Int, $typeIn: [ActivityType]) {
    Page(page: $page, perPage: 25) {
      pageInfo { hasNextPage }
      activities(userId: $userId, sort: ID_DESC, type_in: $typeIn) {
        ... on ListActivity {
          id
          type
          status
          progress
          createdAt
          likeCount
          replyCount
          isLiked
          isPinned
          isSubscribed
          likes {
            id
            name
            avatar { large }
            bannerImage
          }
          media {
            id
            title { userPreferred }
            coverImage { large }
            bannerImage
          }
          user {
            id
            name
            avatar { large }
          }
        }
        ... on TextActivity {
          id
          type
          text(asHtml: true)
          createdAt
          likeCount
          replyCount
          isLiked
          isPinned
          isSubscribed
          likes {
            id
            name
            avatar { large }
            bannerImage
          }
          user {
            id
            name
            avatar { large }
          }
        }
        ... on MessageActivity {
          id
          type
          message(asHtml: true)
          createdAt
          likeCount
          replyCount
          isLiked
          isSubscribed
          isPrivate
          likes {
            id
            name
            avatar { large }
            bannerImage
          }
          messenger {
            id
            name
            avatar { large }
          }
        }
      }
    }
  }
  ''';

    try {
      final response = await _anilistPost(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'query': query,
          'variables': {
            'userId': userId,
            'page': page,
            'typeIn': typeIn,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final activitiesJson =
            data['data']?['Page']?['activities'] as List<dynamic>? ?? [];

        final hasNextPage =
            data['data']?['Page']?['pageInfo']?['hasNextPage'] == true;

        final activities = activitiesJson
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => AnilistActivity.fromJson(e as Map<String, dynamic>))
            .toList();
        return (activities, hasNextPage);
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to fetch activities: ${response.statusCode}');
      }
    } catch (e) {
      Logger.i('Error fetching activities: $e');
    }
    return (<AnilistActivity>[], false);
  }

  Future<bool> toggleLike(int id, String type) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation ToggleLike($id: Int, $type: LikeableType) {
    ToggleLikeV2(id: $id, type: $type) {
      ... on ListActivity { likeCount isLiked }
      ... on TextActivity { likeCount isLiked }
      ... on MessageActivity { likeCount isLiked }
      ... on ActivityReply { likeCount isLiked }
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id, 'type': type},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error toggling like: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(int id) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation DeleteActivity($id: Int) {
    DeleteActivity(id: $id) {
      deleted
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error deleting activity: $e');
      return false;
    }
  }

  Future<bool> postActivityReply(int activityId, String text) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation SaveActivityReply($activityId: Int, $text: String) {
    SaveActivityReply(activityId: $activityId, text: $text) {
      id
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
        body: json.encode({
          'query': mutation,
          'variables': {'activityId': activityId, 'text': text},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error posting activity reply: $e');
      return false;
    }
  }

  Future<bool> editActivityReply(int id, String text) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation SaveActivityReply($id: Int, $text: String) {
    SaveActivityReply(id: $id, text: $text) {
      id
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id, 'text': text},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error editing activity reply: $e');
      return false;
    }
  }

  Future<bool> deleteActivityReply(int id) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation DeleteActivityReply($id: Int) {
    DeleteActivityReply(id: $id) {
      deleted
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error deleting activity reply: $e');
      return false;
    }
  }

  Future<List<ActivityReply>> fetchActivityReplies(int activityId) async {
    final token = AuthKeys.authToken.get<String?>();

  
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    const query = r'''
  query ($activityId: Int!, $page: Int) {
    Page(page: $page, perPage: 50) {
      pageInfo { hasNextPage }
      activityReplies(activityId: $activityId) {
        id
        text(asHtml: true)
        likeCount
        isLiked
        createdAt
        user { id name avatar { large } }
        likes {
          id
          name
          avatar { large medium }
          bannerImage
        }
      }
    }
  }
  ''';

    try {
      final response = await _anilistPost(
        headers: headers,
        body: {
          'query': query,
          'variables': {'activityId': activityId, 'page': 1},
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final repliesJson =
            data['data']?['Page']?['activityReplies'] as List<dynamic>? ?? [];
        return repliesJson
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => ActivityReply.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.e(
            'fetchActivityReplies failed: status=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      Logger.e('Error fetching activity replies: $e');
    }
    return [];
  }

  Future<bool> createActivity(String text) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

   
    const mutation = r'''
  mutation CreateActivity($text: String) {
    SaveTextActivity(text: $text) {
      id
      text
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
        body: json.encode({
          'query': mutation,
          'variables': {'text': text},
        }),
      );
      if (response.statusCode != 200) {
        Logger.e('Error creating activity: ${response.body}');
        throw Exception(response.body);
      }
      return true;
    } catch (e) {
      Logger.e('Error creating activity: $e');
      rethrow;
    }
  }

  Future<bool> createMessageActivity(
      int recipientId, String message, bool isPrivate) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation SaveMessageActivity($recipientId: Int, $message: String, $private: Boolean) {
    SaveMessageActivity(recipientId: $recipientId, message: $message, private: $private) {
      id
      message
      isPrivate
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
        body: json.encode({
          'query': mutation,
          'variables': {
            'recipientId': recipientId,
            'message': message,
            'private': isPrivate
          },
        }),
      );
      if (response.statusCode != 200) {
        Logger.e('Error creating message activity: ${response.body}');
        throw Exception(response.body);
      }
      return true;
    } catch (e) {
      Logger.e('Error creating message activity: $e');
      rethrow;
    }
  }

  Future<bool> editActivity(int id, String text) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation EditActivity($id: Int, $text: String) {
    SaveTextActivity(id: $id, text: $text) {
      id
      text
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id, 'text': text},
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error editing activity: $e');
      return false;
    }
  }

  Future<String?> toggleActivityPin(int id, bool isPinned) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return "Not logged in";

    const mutation = r'''
  mutation ToggleActivityPin($id: Int, $pinned: Boolean) {
    ToggleActivityPin(id: $id, pinned: $pinned) {
      ... on TextActivity {
        id
        isPinned
      }
      ... on ListActivity {
        id
        isPinned
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id, 'pinned': isPinned},
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['errors'] == null) {
        return null; // Success
      } else {
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          return data['errors'][0]['message'] ?? 'Failed to pin activity';
        }
        return 'Failed to pin activity (Status: ${response.statusCode})';
      }
    } catch (e) {
      Logger.i('Error toggling activity pin: $e');
      return 'Network error occurred';
    }
  }

  Future<bool> toggleActivitySubscription(int id, bool isSubscribed) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    const mutation = r'''
  mutation ToggleActivitySubscription($id: Int, $subscribe: Boolean) {
    ToggleActivitySubscription(activityId: $id, subscribe: $subscribe) {
      id
      isSubscribed
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
        body: json.encode({
          'query': mutation,
          'variables': {'id': id, 'subscribe': isSubscribed},
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error toggling activity subscription: $e');
      return false;
    }
  }

  Future<void> fetchFollowersAndFollowing(String userId) async {
    final token = AuthKeys.authToken.get<String?>();

    if (token == null) {
      Logger.i('No token found');
      return;
    }

    const query = '''
  query(\$userId: Int!) {
    followers: Page {
      pageInfo { total }
    }
    following: Page {
      pageInfo { total }
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
        body: json.encode({
          'query': query,
          'variables': {'userId': userId.toInt()}
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final followersCount =
            data['data']['followers']['pageInfo']['total'] as int;
        final followingCount =
            data['data']['following']['pageInfo']['total'] as int;

        final updatedProfile = profileData.value
          ..followers = followersCount
          ..following = followingCount;

        profileData.value = updatedProfile;
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to load followers/following: ${response.statusCode}');
        throw Exception('Failed to load followers/following ${response.body}');
      }
    } catch (e) {
      Logger.i('Error fetching followers/following: $e');
    }
  }

  Future<void> fetchUserAnimeList() async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) {
      return;
    }

    const query = '''
  query GetUserAnimeList(\$userId: Int) {
    MediaListCollection(userId: \$userId, type: ANIME, sort: UPDATED_TIME) {
      lists {
        name
        entries {
          media {
            id
            idMal
            title {
              romaji
              english
              native
            }
            mediaListEntry {
              id
            }
            format
            episodes
            nextAiringEpisode {
              episode
              airingAt
            }
            averageScore
            type
            genres
            startDate {
              year
            }
            coverImage {
              large
            }
          }
          progress
          status
          score
          updatedAt
          startedAt { year month day }
          completedAt { year month day }
        }
      }
    }
  }
  ''';

    try {
      if (profileData.value.id == null) {
        Logger.i('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = profileData.value.id;
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

          final animeListt =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();

          currentlyWatching.value = animeListt
              .where((animeEntry) => animeEntry['status'] == 'CURRENT')
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
              .toList()
              .removeDupes();

          currentlyWatching.value = currentlyWatching.value.removeDupes();

          animeList.value = animeListt
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
              .toList()
              .removeDupes();
          Logger.i("Anime List Fetched Successfully!");
        } else {
          Logger.i('Unexpected response structure: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Fetch failed with status code: ${response.statusCode}');
        Logger.i('Response body: ${response.body}');
      }
    } catch (e) {
      Logger.i('Failed to load anime list: $e');
    }
  }

  Future<void> deleteMediaFromList(String listId, {bool isAnime = true}) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) {
      return;
    }

    const String mutation = r'''
    mutation Mutation($deleteMediaListEntryId: Int) {
      DeleteMediaListEntry(id: $deleteMediaListEntryId) {
        deleted
      }
    }
  ''';

    try {
      if (profileData.value.id == null) {
        Logger.i('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = profileData.value.id;
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
          'query': mutation,
          'variables': {
            'deleteMediaListEntryId': listId,
          },
        }),
      );

      if (response.statusCode == 200) {
        snackBar(
            "${isAnime ? "Anime" : "Manga"} successfully deleted from your list!");
        currentMedia.value = TrackedMedia();
        if (isAnime) {
          fetchUserAnimeList();
        } else {
          fetchUserMangaList();
        }
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to delete media with list ID $listId');
        Logger.i('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.i('Failed to delete media: $e');
    }
  }

  Future<void> updateListEntry({
    required String listId,
    String? malId,
    double? score,
    String? status,
    int? progress,
    bool isAnime = true,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isPrivate,
  }) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null || !isLoggedIn.value) {
      return;
    }

    const String mutation = '''
  mutation UpdateMediaList(\$id: Int, \$progress: Int, \$score: Float, \$status: MediaListStatus, \$startedAt: FuzzyDateInput, \$completedAt: FuzzyDateInput, \$private: Boolean) {
    SaveMediaListEntry(mediaId: \$id, progress: \$progress, score: \$score, status: \$status, startedAt: \$startedAt, completedAt: \$completedAt, private: \$private) {
      id
      status
      progress
      score
      startedAt { year month day }
      completedAt { year month day }
    }
  }
  ''';

    try {
      if (profileData.value.id == null) {
        Logger.i('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = profileData.value.id;
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      final variables = <String, dynamic>{
        'id': listId,
      };

      if (score != null) {
        variables['score'] = score;
      }
      if (status != null) {
        variables['status'] = status;
      }
      if (progress != null) {
        variables['progress'] = progress;
      }
      if (startedAt != null) {
        variables['startedAt'] = {
          'year': startedAt.year,
          'month': startedAt.month,
          'day': startedAt.day,
        };
      }
      if (completedAt != null) {
        variables['completedAt'] = {
          'year': completedAt.year,
          'month': completedAt.month,
          'day': completedAt.day,
        };
      }
      if (isPrivate != null) {
        variables['private'] = isPrivate;
      }

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': mutation,
          'variables': variables,
        }),
      );

      if (malId != null) {
        serviceHandler.malService.updateListEntry(UpdateListEntryParams(
            listId: malId,
            score: score,
            status: status,
            progress: progress,
            isAnime: isAnime,
            startedAt: startedAt,
            completedAt: completedAt));
      }

      if (response.statusCode == 200) {
        final newMedia = currentMedia.value
          ..episodeCount = progress.toString()
          ..watchingStatus = status
          ..score = score.toString();
        currentMedia.value = newMedia;
        if (isAnime) {
          await fetchUserAnimeList();
        } else {
          await fetchUserMangaList();
        }
        setCurrentMedia(listId, isManga: !isAnime);
        Get.find<MissingSequelService>().onListChanged(isAnime: isAnime);
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Update failed with status code: ${response.statusCode}');
        Logger.i('Response body: ${response.body}');
      }
    } catch (e) {
      Logger.i('Failed to update media: $e');
    }
  }

  Future<void> fetchUserMangaList() async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) {
      return;
    }

    const query = '''
    query GetUserMangaList(\$userId: Int) {
      MediaListCollection(userId: \$userId, type: MANGA, sort: UPDATED_TIME) {
        lists {
          name
          entries {
            media {
              id
              idMal
              title {
                romaji
                english
                native
              }
              mediaListEntry {
                id
              }
              chapters
              format
              status
              type
              averageScore
              genres
              startDate {
                year
              }
              coverImage {
                large
              }
            }
            progress
            status
            score
            updatedAt
          }
        }
      }
    }
    ''';

    try {
      if (profileData.value.id == null) {
        Logger.i('User ID is not available. Fetching user profile first.');
        await fetchUserProfile();
      }

      final userId = profileData.value.id;
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

          final animeListt =
              lists.expand((list) => list['entries'] as List<dynamic>).toList();

          currentlyReading.value = animeListt
              .where((animeEntry) =>
                  animeEntry['status'] == 'CURRENT' ||
                  animeEntry['status'] == 'REPEATING')
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
              .toList()
              .removeDupes();

          mangaList.value = animeListt
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
              .toList()
              .removeDupes();
        } else {
          Logger.i('Unexpected response structure: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Fetch failed with status code: ${response.statusCode}');
        Logger.i('Response body: ${response.body}');
      }
    } catch (e) {
      Logger.i('Failed to load manga list: $e');
    }
  }

  Future<void> updateAnimeStatus({
    required String animeId,
    String? status,
    int? progress,
    double score = 0.0,
  }) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) {
      Logger.i('Auth token is not available.');
      return;
    }

    const mutation = '''
  mutation UpdateAnimeStatus(\$mediaId: Int, \$status: MediaListStatus, \$progress: Int, \$score: Float) {
    SaveMediaListEntry(mediaId: \$mediaId, status: \$status, progress: \$progress, score: \$score) {
      id
      status
      progress
      score
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
        body: json.encode({
          'query': mutation,
          'variables': {
            'mediaId': animeId.toInt(),
            'status': status,
            'progress': progress,
            'score': score,
          },
        }),
      );

      if (response.statusCode == 200) {
        Logger.i('Anime status updated successfully: ${response.body}');
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to update anime status: ${response.statusCode}');
        Logger.i('Response body: ${response.body}');
      }
    } catch (e) {
      Logger.i('Error while updating anime status: $e');
    }
  }

  Future<void> updateMangaStatus({
    required String mangaId,
    String? status,
    int? progress,
    double? score,
  }) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) {
      Logger.i('Auth token is not available.');
      return;
    }

    const mutation = '''
  mutation UpdateMangaStatus(\$mediaId: Int, \$status: MediaListStatus, \$progress: Int, \$score: Float) {
    SaveMediaListEntry(mediaId: \$mediaId, status: \$status, progress: \$progress, score: \$score) {
      id
      status
      progress
      score
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
        body: json.encode({
          'query': mutation,
          'variables': {
            'mediaId': mangaId,
            'status': status,
            'progress': progress,
            'score': score,
          },
        }),
      );

      if (response.statusCode == 200) {
        Logger.i('Manga status updated successfully: ${response.body}');
      } else if (response.statusCode == 403) {
        _handle403(response);
      } else {
        Logger.i('Failed to update manga status: ${response.statusCode}');
        Logger.i('Response body: ${response.body}');
      }
    } catch (e) {
      Logger.i('Error while updating manga status: $e');
    }
  }

  Future<bool> toggleFavorite({required int id, required String type}) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return false;

    String idField;
    if (type == "CHARACTER") {
      idField = "characterId";
    } else if (type == "STUDIO") {
      idField = "studioId";
    } else {
      idField = "staffId";
    }

    final mutation = '''
    mutation (\$id: Int) {
      ToggleFavourite($idField: \$id) {
        characters {
          nodes { id }
        }
        staff {
          nodes { id }
        }
        studios {
          nodes { id }
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
        },
        body: json.encode({
          'query': mutation,
          'variables': {'id': id},
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        _handle403(response);
      }
      return false;
    } catch (e) {
      Logger.i("Error toggling favorite: $e");
      return false;
    }
  }

  TrackedMedia returnAvailAnime(String id) {
    return animeList.value
        .firstWhere((el) => el.id == id, orElse: () => TrackedMedia());
  }

  void setCurrentMedia(String id, {bool isManga = false}) async {
    if (isManga) {
      final savedManga = offlineStorage.getMangaById(id);
      final number = savedManga?.currentChapter?.number?.toInt() ?? 0;
      currentMedia.value = mangaList.value.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
                episodeCount: number.toString(),
                chapterCount: number.toString(),
              ));
    } else {
      final savedAnime = offlineStorage.getAnimeById(id);
      final number = savedAnime?.currentEpisode?.number?.toInt() ?? 0;
      currentMedia.value = animeList.value.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
              episodeCount: number.toString(),
              chapterCount: number.toString()));
    }
  }

  TrackedMedia returnAvailManga(String id) {
    return mangaList.value
        .firstWhere((el) => el.id == id, orElse: () => TrackedMedia());
  }

  Future<void> logout() async {
    AuthKeys.authToken.delete();
    profileData.value = Profile();
    isLoggedIn.value = false;
  }
}
