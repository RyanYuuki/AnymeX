// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/comments_db.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
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
import 'package:http/http.dart';
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
    String redirectUri = dotenv.env['CALLBACK_SCHEME'] ?? '';

    if (selectedMethod == 'browser') {
      // Browser login flow
      final url =
          'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code';
      try {
        final result = await FlutterWebAuth2.authenticate(
          url: url,
          callbackUrlScheme: 'anymex',
        );
        final code = Uri.parse(result).queryParameters['code'];
        if (code != null) {
          Logger.i("token found: $code");
          await _exchangeCodeForToken(
              code, clientId, clientSecret, redirectUri);
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
          // Handle bar
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
          // Title
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
          // Browser login button
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

  Future<void> _exchangeCodeForToken(String code, String clientId,
      String clientSecret, String redirectUri) async {
    final response = await post(
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
        }
        manga {
          count
          chaptersRead
          volumesRead
          meanScore
        }
      }
      favourites {
        anime {
          pageInfo { total }
        }
        manga {
          pageInfo { total }
        }
      }
    }
  }
  ''';

    try {
      final response = await post(
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
        profileData.value = userProfile;
        isLoggedIn.value = true;

        Logger.i(
            'User profile fetched: ${userProfile.name} (ID: ${userProfile.id})');

        // fetchFollowersAndFollowing(userProfile.id ?? '');
        CommentsDatabase().login();
      } else {
        Logger.i('Failed to load user profile: ${response.statusCode}');
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      Logger.i('Error fetching user profile: $e');
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
      final response = await post(
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
        final followersCount = data['data']['followers']['pageInfo']['total'] as int;
        final followingCount = data['data']['following']['pageInfo']['total'] as int;

        final updatedProfile = profileData.value
          ..followers = followersCount
          ..following = followingCount;

        profileData.value = updatedProfile;
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
            coverImage {
              large
            }
          }
          progress
          status
          score
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

      final response = await post(
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

      final response = await post(
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
  }) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null || !isLoggedIn.value) {
      return;
    }

    const String mutation = '''
  mutation UpdateMediaList(\$id: Int, \$progress: Int, \$score: Float, \$status: MediaListStatus) {
    SaveMediaListEntry(mediaId: \$id, progress: \$progress, score: \$score, status: \$status) {
      id
      status
      progress
      score
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

      final response = await post(
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
            isAnime: isAnime));
      }

      if (response.statusCode == 200) {
        final newMedia = currentMedia.value
          ..episodeCount = progress.toString()
          ..watchingStatus = status
          ..score = score.toString();
        currentMedia.value = newMedia;
        if (isAnime) {
          fetchUserAnimeList();
        } else {
          fetchUserMangaList();
        }
        setCurrentMedia(listId, isManga: !isAnime);
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
              coverImage {
                large
              }
            }
            progress
            status
            score
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

      final response = await post(
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
      final response = await post(
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
      final response = await post(
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

   
    final String idField = type == "CHARACTER" ? "characterId" : "staffId";
    final mutation = '''
    mutation (\$id: Int) {
      ToggleFavourite($idField: \$id) {
        characters {
          nodes { id }
        }
        staff {
          nodes { id }
        }
      }
    }
  ''';

    try {
      final response = await post(
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

      return response.statusCode == 200;
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
