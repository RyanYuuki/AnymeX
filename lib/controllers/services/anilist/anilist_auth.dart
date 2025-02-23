// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:developer';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AnilistAuth extends GetxController {
  RxBool isLoggedIn = false.obs;
  Rx<Profile> profileData = Profile().obs;
  final storage = Hive.box('auth');
  final offlineStorage = Get.find<OfflineStorageController>();

  Rx<TrackedMedia> currentMedia = TrackedMedia().obs;

  RxList<TrackedMedia> currentlyWatching = <TrackedMedia>[].obs;
  RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;

  RxList<TrackedMedia> currentlyReading = <TrackedMedia>[].obs;
  RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;

  Future<void> tryAutoLogin() async {
    isLoggedIn.value = false;
    final token = await storage.get('auth_token');
    if (token != null) {
      await fetchUserProfile();
      await fetchUserAnimeList();
      await fetchUserMangaList();
    }
  }

  Future<void> login() async {
    String clientId = dotenv.env['AL_CLIENT_ID'] ?? '';
    String clientSecret = dotenv.env['AL_CLIENT_SECRET'] ?? '';
    String redirectUri = dotenv.env['CALLBACK_SCHEME'] ?? '';

    final url =
        'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'anymex',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        log("token found: $code");
        await _exchangeCodeForToken(code, clientId, clientSecret, redirectUri);
      }
    } catch (e) {
      log('Error during login: $e');
    }
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
      await storage.put('auth_token', token);
      await fetchUserProfile();
      await fetchUserAnimeList();
      await fetchUserMangaList();
    } else {
      throw Exception('Failed to exchange code for token: ${response.body}');
    }
  }

  Future<void> fetchUserProfile() async {
    final token = await storage.get('auth_token');

    if (token == null) {
      log('No token found');
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

        log('User profile fetched: ${userProfile.name} (ID: ${userProfile.id})');

        fetchFollowersAndFollowing(userProfile.id ?? '');
      } else {
        log('Failed to load user profile: ${response.statusCode}');
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      log('Error fetching user profile: $e');
    }
  }

  Future<void> fetchFollowersAndFollowing(String userId) async {
    final token = await storage.get('auth_token');

    if (token == null) {
      log('No token found');
      return;
    }

    const query = '''
  query(\$userId: Int!) {
    Follower(userId: \$userId) {
      id
    }
    Following(userId: \$userId) {
      id
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
        log(data.toString());

        final followersList = data['data']['followers'] as List<dynamic>;
        final followingList = data['data']['following'] as List<dynamic>;

        final updatedProfile = profileData.value
          ..followers = followersList.length
          ..following = followingList.length;

        profileData.value = updatedProfile;
      } else {
        log('Failed to load followers/following: ${response.statusCode}');
        throw Exception('Failed to load followers/following ${response.body}');
      }
    } catch (e) {
      log('Error fetching followers/following: $e');
    }
  }

  Future<void> fetchUserAnimeList() async {
    final token = await storage.get('auth_token');
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
        log('User ID is not available. Fetching user profile first.');
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
              .toList();

          animeList.value = animeListt
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
              .toList();
          log("Anime List Fetched Successfully!");
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
  }

  Future<void> deleteMediaFromList(String listId, {bool isAnime = true}) async {
    final token = await storage.get('auth_token');
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
        log('User ID is not available. Fetching user profile first.');
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
        log('Failed to delete media with list ID $listId');
        log('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('Failed to delete media: $e');
    }
  }

  Future<void> updateListEntry({
    required String listId,
    double? score,
    String? status,
    int? progress,
    bool isAnime = true,
  }) async {
    final token = await storage.get('auth_token');
    if (token == null) {
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
        log('User ID is not available. Fetching user profile first.');
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

      if (response.statusCode == 200) {
        // snackBar(
        //     "${isAnime ? 'Anime' : 'Manga'} Tracked to ${isAnime ? 'Episode' : 'Chapter'} $progress Successfully!");
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
        log('Update failed with status code: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Failed to update media: $e');
    }
  }

  Future<void> fetchUserMangaList() async {
    final token = await storage.get('auth_token');
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
        log('User ID is not available. Fetching user profile first.');
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
              .toList();

          mangaList.value = animeListt
              .map((animeEntry) => TrackedMedia.fromJson(animeEntry))
              .toList()
              .reversed
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
  }

  Future<void> updateAnimeStatus({
    required String animeId,
    String? status,
    int? progress,
    double score = 0.0,
  }) async {
    final token = await storage.get('auth_token');
    if (token == null) {
      log('Auth token is not available.');
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
        log('Anime status updated successfully: ${response.body}');
      } else {
        log('Failed to update anime status: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Error while updating anime status: $e');
    }
  }

  Future<void> updateMangaStatus({
    required String mangaId,
    String? status,
    int? progress,
    double? score,
  }) async {
    final token = await storage.get('auth_token');
    if (token == null) {
      log('Auth token is not available.');
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
        log('Manga status updated successfully: ${response.body}');
      } else {
        log('Failed to update manga status: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Error while updating manga status: $e');
    }
  }

  TrackedMedia returnAvailAnime(String id) {
    return animeList.value
        .firstWhere((el) => el.id == id, orElse: () => TrackedMedia());
  }

  void setCurrentMedia(String id, {bool isManga = false}) {
    if (isManga) {
      final savedManga = offlineStorage.getMangaById(id);
      currentMedia.value = mangaList.value.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
              episodeCount: savedManga?.currentChapter?.number?.toString() ??
                  savedManga?.currentEpisode?.number ??
                  '0'));
    } else {
      final savedAnime = offlineStorage.getAnimeById(id);
      currentMedia.value = animeList.value.firstWhere((el) => el.id == id,
          orElse: () =>
              TrackedMedia(episodeCount: savedAnime?.currentEpisode?.number));
    }
  }

  TrackedMedia returnAvailManga(String id) {
    return mangaList.value
        .firstWhere((el) => el.id == id, orElse: () => TrackedMedia());
  }

  Future<void> logout() async {
    await storage.delete('auth_token');
    profileData.value = Profile();
    isLoggedIn.value = false;
  }
}
