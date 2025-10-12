import 'dart:convert';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:math' show Random;
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/anime/misc/recommendation.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart' as fb;
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

class MalService extends GetxController implements BaseService, OnlineService {
  final storage = Hive.box('auth');
  @override
  RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;
  @override
  RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;

  // Anime Lists
  RxList<Media> trendingAnimes = <Media>[].obs;
  RxList<Media> popularAnimes = <Media>[].obs;
  RxList<Media> topAnimes = <Media>[].obs;
  RxList<Media> upcomingAnimes = <Media>[].obs;

  // Manga Lists
  RxList<Media> trendingManga = <Media>[].obs;
  RxList<Media> topManhwa = <Media>[].obs;
  RxList<Media> topManga = <Media>[].obs;
  RxList<Media> topManhua = <Media>[].obs;

  static const field = "fields=mean,status,media_type,synopsis";

  Future<List<Media>> fetchDataFromApi(String url,
      {String? customFields}) async {
    final newField = customFields ?? field;
    final data = await fetchMAL('$url&$newField') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => Media.fromMAL(e))
        .toList();
  }

  Widget buildSectionIfNotEmpty(String title, RxList<Media> list,
      {bool isManga = false}) {
    return list.isEmpty
        ? const AnymexProgressIndicator()
        : buildSection(title, list,
            type: isManga ? ItemType.manga : ItemType.anime);
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) => [
        Obx(() => trendingAnimes.isEmpty
            ? const Center(child: AnymexProgressIndicator())
            : Column(
                children: [
                  buildSectionIfNotEmpty("Trending Animes", trendingAnimes),
                  buildSectionIfNotEmpty("Popular Animes", popularAnimes),
                  buildSectionIfNotEmpty("Top Animes", topAnimes),
                  buildSectionIfNotEmpty("Upcoming Animes", upcomingAnimes),
                ],
              )),
      ].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) => [
        Obx(() => trendingManga.isEmpty
            ? const Center(child: AnymexProgressIndicator())
            : Column(
                children: [
                  buildSectionIfNotEmpty("Trending Manga", trendingManga,
                      isManga: true),
                  buildSectionIfNotEmpty("Top Manga", topManga, isManga: true),
                  buildSectionIfNotEmpty("Top Manhwa", topManhwa,
                      isManga: true),
                  buildSectionIfNotEmpty("Top Manhua", topManhua,
                      isManga: true),
                  ...sourceController.novelSections.value
                ],
              )),
      ].obs;

  @override
  Future<void> fetchHomePage() async {
    try {
      trendingAnimes.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/anime/ranking?ranking_type=airing&limit=15');
      popularAnimes.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/anime/ranking?ranking_type=bypopularity&limit=15');
      topAnimes.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/anime/ranking?ranking_type=tv&limit=15');
      upcomingAnimes.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/anime/ranking?ranking_type=upcoming&limit=15');

      trendingManga.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/manga/ranking?ranking_type=all&limit=15');
      topManga.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manga&limit=15');
      topManhwa.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manhwa&limit=15');
      topManhua.value = await fetchDataFromApi(
          'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manhua&limit=15');
    } catch (e) {
      Logger.i('Error fetching home page data: $e');
    }
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    try {
      final animeData = await fetchWithToken(
        'https://api.myanimelist.net/v2/anime/${params.id}',
      );
      return animeData;
    } catch (animeError) {
      try {
        final mangaData = await fetchWithToken(
          'https://api.myanimelist.net/v2/manga/${params.id}',
        );
        return mangaData;
      } catch (mangaError) {
        throw Exception(
            'Failed to fetch details for both anime and manga with ID: ${params.id}');
      }
    }
  }

  Future<Media> fetchWithToken(String url) async {
    const newField =
        "fields=mean,status,media_type,synopsis,genres,type,num_episodes,num_chapters,studio,start_date,end_date,source,rating,rank,popularity,favorites,studios,statistics,recommendations";

    final data = await fetchMAL('$url?$newField') as Map<String, dynamic>;
    cacheController.addCache(data);
    return Media.fromFullMAL(data);
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final mediaType = params.isManga ? 'manga' : 'anime';
    final data = await fetchDataFromApi(
      'https://api.myanimelist.net/v2/$mediaType?q=${params.query}&limit=30',
    );
    return data;
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    final isDesktop = Get.width > 600;
    final settings = Get.find<Settings>();
    final acceptedLists = settings.homePageCardsMal.entries
        .where((entry) => entry.value)
        .map<String>((entry) => entry.key)
        .toList();
    return [
      Obx(() => Column(
            children: [
              if (isLoggedIn.value) ...[
                LayoutBuilder(builder: (context, constraints) {
                  final width =
                      isDesktop ? 300.0 : constraints.maxWidth / 2 - 40;
                  final overflow = constraints.maxWidth < 900;
                  final overflowSecond =
                      !isDesktop ? false : constraints.maxWidth < 600;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 15,
                    children: [
                      ImageButton(
                        width: width,
                        height: !isDesktop ? 70 : 90,
                        buttonText: "ANIME LIST",
                        backgroundImage: trendingAnimes.isEmpty
                            ? ''
                            : trendingAnimes
                                    .firstWhere((e) => e.cover != null)
                                    .cover ??
                                '',
                        borderRadius: 16.multiplyRadius(),
                        onPressed: () {
                          navigate(() => const AnimeList());
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: overflowSecond ? 8.0 : 0),
                        child: ImageButton(
                          width: width,
                          height: !isDesktop ? 70 : 90,
                          buttonText: "MANGA LIST",
                          borderRadius: 16.multiplyRadius(),
                          backgroundImage: trendingMangas
                                  .firstWhere((e) => e.cover != null)
                                  .cover ??
                              '',
                          onPressed: () {
                            navigate(() => const AnilistMangaList());
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: overflow ? 8.0 : 0),
                        child: ImageButton(
                          width: width,
                          height: !isDesktop ? 70 : 90,
                          buttonText: "OTHER",
                          borderRadius: 16.multiplyRadius(),
                          backgroundImage: [
                                ...popularAnimes,
                                ...popularMangas,
                                ...trendingMangas,
                                ...trendingAnimes
                              ].where((e) => e.cover != null).last.cover ??
                              '',
                          onPressed: () {
                            navigate(() => const OtherFeaturesPage());
                          },
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                Obx(() => Column(
                      children: acceptedLists.map((e) {
                        return ReusableCarousel(
                          data: filterListByLabel(
                              e.contains("Manga") || e.contains("Reading")
                                  ? mangaList
                                  : animeList,
                              e),
                          title: e,
                          variant: DataVariant.anilist,
                          type: e.contains("Manga") || e.contains("Reading")
                              ? ItemType.manga
                              : ItemType.anime,
                        );
                      }).toList(),
                    )),
              ],
              buildSectionIfNotEmpty("Trending Animes", trendingAnimes),
              buildSectionIfNotEmpty("Popular Animes", popularAnimes),
              buildSectionIfNotEmpty("Trending Manga", trendingManga,
                  isManga: true),
              buildSectionIfNotEmpty("Popular Manga", topManga, isManga: true),
            ],
          )),
    ].obs;
  }

  @override
  RxBool isLoggedIn = false.obs;

  @override
  Rx<Profile> profileData = Profile().obs;

  Future<void> fetchUserAnimeList() async {
    final data = await fetchMAL(
        'https://api.myanimelist.net/v2/users/@me/animelist?fields=num_episodes,mean,list_status&limit=1000&sort=list_updated_at&nsfw=1',
        auth: false,
        useAuthHeader: true);
    animeList.value = (data['data'] as List<dynamic>)
        .map((e) => TrackedMedia.fromMAL(e))
        .toList();
    continueWatching.value = animeList
        .where((e) => e.watchingStatus?.toUpperCase().trim() == "CURRENT")
        .toList();
  }

  Future<void> fetchUserMangaList() async {
    final data = await fetchMAL(
        'https://api.myanimelist.net/v2/users/@me/mangalist?fields=num_chapters,mean,list_status&limit=1000&sort=list_updated_at&nsfw=1',
        auth: false,
        useAuthHeader: true);
    mangaList.value = (data['data'] as List<dynamic>)
        .map((e) => TrackedMedia.fromMAL(e))
        .toList();
    continueReading.value = mangaList
        .where((e) => e.watchingStatus?.toUpperCase().trim() == "CURRENT")
        .toList();
  }

  Future<void> fetchUserInfo({String? token}) async {
    final tokenn = token ?? storage.get('mal_auth_token');
    final data = await fetchMAL('https://api.myanimelist.net/v2/users/@me',
        auth: true, useAuthHeader: true, token: tokenn);
    profileData.value = Profile.fromKitsu(data);
    isLoggedIn.value = true;
    Future.wait([fetchUserAnimeList(), fetchUserMangaList()]);
  }

  @override
  Future<void> autoLogin() async {
    try {
      final token = await storage.get('mal_auth_token');
      final refreshToken = await storage.get('mal_refresh_token');

      if (token != null) {
        final isValid = await _validateToken(token);
        if (isValid) {
          Logger.i("Auto-login successful with existing token.");
          await fetchUserInfo(token: token);
          return;
        }
      }

      if (refreshToken != null) {
        await _refreshTokenWithMAL(refreshToken);
      } else {
        Logger.i("No valid tokens found. User needs to log in again.");
      }
    } catch (e) {
      Logger.i("Auto-login failed: $e");
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      final response = await get(
        Uri.parse('https://api.myanimelist.net/v2/users/@me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i("Token validation failed: $e");
      return false;
    }
  }

  Future<void> _refreshTokenWithMAL(String refreshToken) async {
    final clientId = dotenv.env['MAL_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['MAL_CLIENT_SECRET'] ?? '';

    final response = await post(
      Uri.parse('https://myanimelist.net/v1/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];

      await storage.put('mal_auth_token', newToken);
      if (newRefreshToken != null) {
        await storage.put('mal_refresh_token', newRefreshToken);
      }

      Logger.i("Token refreshed successfully.");
      await fetchUserInfo(token: newToken);
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  @override
  Future<void> login() async {
    String clientId = dotenv.env['MAL_CLIENT_ID'] ?? '';
    String secret = dotenv.env['MAL_CLIENT_SECRET'] ?? '';
    final secureRandom = Random.secure();
    final codeVerifierBytes =
        List<int>.generate(96, (_) => secureRandom.nextInt(256));

    final codeChallenge = base64UrlEncode(codeVerifierBytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    final url =
        'https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=$clientId&code_challenge=$codeChallenge';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'anymex',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        Logger.i("Authorization code: $code");
        await _exchangeCodeForTokenMAL(code, clientId, codeChallenge, secret);
      }
    } catch (e) {
      Logger.i('Error during MyAnimeList login: $e');
    }
  }

  Future<void> _exchangeCodeForTokenMAL(
      String code, String clientId, String codeVerifier, String secret) async {
    final response = await post(
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
      final data = json.decode(response.body);
      final token = data['access_token'];
      final refreshToken = data['refresh_token'];

      await storage.put('mal_auth_token', token);
      if (refreshToken != null) {
        await storage.put('mal_refresh_token', refreshToken);
      }

      Logger.i("MAL Access token: $token");
      await fetchUserInfo();
      Logger.i("Login Succesfull!");
    } else {
      throw Exception(
          'Failed to exchange code for token: ${response.body}, ${response.statusCode}');
    }
  }

  Future<dynamic> fetchMAL(String url,
      {bool auth = false, bool useAuthHeader = false, String? token}) async {
    try {
      final clientId = dotenv.env['MAL_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        throw Exception('MAL_CLIENT_ID is not set in .env file.');
      }
      final tokenn = token ?? await storage.get('mal_auth_token');
      final response = await get(Uri.parse(url),
          headers: useAuthHeader
              ? {
                  'Authorization': 'Bearer $tokenn',
                }
              : {
                  'X-MAL-CLIENT-ID': clientId,
                });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (auth) {
          final rep = await get(
              Uri.parse('https://api.jikan.moe/v4/users/${data['name']}/full'));
          return jsonDecode(rep.body)..['picture'] = data['picture'];
        }
        return data;
      } else {
        Logger.i('Failed to fetch data from $url: ${response.statusCode}');
        throw Exception(
            'Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      Logger.i('Error fetching data from API: $e');
      return [];
    }
  }

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    if (!isLoggedIn.value) return;
    final listId = params.listId;
    final score = params.score;
    final status = params.status;
    final progress = params.progress;
    final isAnime = params.isAnime;

    final token = await storage.get('mal_auth_token');
    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');

    final body = {
      if (status != null)
        'status': getMALStatusEquivalent(status, isAnime: isAnime),
      if (score != null) 'score': score.toString(),
      if (progress != null && isAnime)
        'num_watched_episodes': progress.toString(),
      if (progress != null && !isAnime)
        'num_chapters_read': progress.toString(),
    };

    final req = await put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if ((params.syncIds?.isNotEmpty ?? false) && params.syncIds?[0] != null) {
      await serviceHandler.anilistService.updateListEntry(UpdateListEntryParams(
          listId: params.syncIds![0],
          score: score,
          status: status,
          progress: progress,
          isAnime: isAnime));
    }

    if (req.statusCode == 200) {
      // snackBar(
      //     "${isAnime ? 'Anime' : 'Manga'} Tracked to ${isAnime ? 'Episode' : 'Chapter'} $progress Successfully!");

      final newMedia = currentMedia.value
        ..episodeCount = progress.toString()
        ..watchingStatus = status
        ..score = score.toString();
      currentMedia.value = newMedia;
      Logger.i('$isAnime: $body');
      if (isAnime) {
        fetchUserAnimeList();
      } else {
        fetchUserMangaList();
      }
    } else {
      Logger.i('Error: ${req.body}');
      Logger.i('$isAnime: $body');
    }
  }

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    final token = await storage.get('mal_auth_token');

    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');

    final req = await delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (req.statusCode == 200) {
      snackBar(
          "${isAnime ? "Anime" : "Manga"} successfully deleted from your list!");

      currentMedia.value = TrackedMedia();
      if (isAnime) {
        fetchUserAnimeList();
      } else {
        fetchUserMangaList();
      }
    } else {
      Logger.i('Error deleting entry: ${req.body}');
      snackBar(
          "Failed to delete ${isAnime ? "anime" : "manga"} from your list.");
    }
  }

  RxList<TrackedMedia> continueWatching = <TrackedMedia>[].obs;

  RxList<TrackedMedia> continueReading = <TrackedMedia>[].obs;

  @override
  Rx<TrackedMedia> currentMedia = TrackedMedia().obs;

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    final offlineStorage = Get.find<OfflineStorageController>();
    if (isManga) {
      final savedManga = offlineStorage.getMangaById(id);
      final number = savedManga?.currentChapter?.number?.toInt() ?? 0;
      currentMedia.value = mangaList.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
              episodeCount: number.toString(),
              chapterCount: number.toString(),
              totalEpisodes: savedManga?.chapters?.length.toString() ?? '??'));
    } else {
      final savedAnime = offlineStorage.getAnimeById(id);
      final number = savedAnime?.currentEpisode?.number.toInt() ?? 0;
      currentMedia.value = animeList.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
              episodeCount: number.toString(),
              chapterCount: number.toString()));
    }
  }

  @override
  Future<void> logout() async {
    storage.delete('mal_auth_token');
    storage.delete('mal_refresh_token');
    isLoggedIn.value = false;
    profileData.value = Profile();
    // animeList.value = [];
    // mangaList.value = [];
    continueWatching.value = [];
    continueReading.value = [];
  }

  @override
  Future<void> refresh() async {
    Future.wait([
      fetchUserAnimeList(),
      fetchUserMangaList(),
    ]);
  }
}
