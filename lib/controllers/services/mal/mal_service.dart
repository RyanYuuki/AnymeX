import 'dart:convert';
import 'dart:math' show Random;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/screens/community/community_recommendations_page.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/services/missing_sequel/missing_sequel_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/screens/other/media_see_all_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MalService extends GetxController implements BaseService, OnlineService {
  final communityService = Get.find<CommunityService>();
  late final MissingSequelService missingSequelService;

  @override
  void onInit() {
    super.onInit();
    missingSequelService = Get.find<MissingSequelService>();
  }

  Media? _firstMediaWithCover(Iterable<Media> mediaList) {
    for (final media in mediaList) {
      final cover = media.cover;
      if (cover != null && cover.isNotEmpty) {
        return media;
      }
    }
    return null;
  }

  Media? _lastMediaWithCover(Iterable<Media> mediaList) {
    final list = mediaList.toList(growable: false);
    for (var index = list.length - 1; index >= 0; index--) {
      final media = list[index];
      final cover = media.cover;
      if (cover != null && cover.isNotEmpty) {
        return media;
      }
    }
    return null;
  }

  void _openHomeButtonMedia(Media media) {
    final tag = 'home-button-${media.serviceType.name}-${media.id}';
    if (media.mediaType == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
      return;
    }
    navigate(() => AnimeDetailsPage(media: media, tag: tag));
  }

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
        .toList()
        .removeDupes();
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
                  buildBigCarousel(trendingAnimes, false),
                  buildMediaSectionWithSeeAll("Trending Anime", trendingAnimes, ItemType.anime),
                  buildMediaSectionWithSeeAll("Popular Anime", popularAnimes, ItemType.anime),
                  buildMediaSectionWithSeeAll("Top Anime", topAnimes, ItemType.anime),
                  buildMediaSectionWithSeeAll("Upcoming Anime", upcomingAnimes, ItemType.anime),
                  Obx(() {
                    final ms = missingSequelService;
                    if (!isLoggedIn.value) return const SizedBox.shrink();
                    return Column(
                      children: [
                        if (ms.missingSequelsAnime.isNotEmpty)
                          buildMediaSectionWithSeeAll('Missing Sequels', ms.missingSequelsAnime, ItemType.anime,
                            onRefresh: () => ms.refreshSection('check', isAnime: true)),
                        if (ms.upcomingSequelsAnime.isNotEmpty)
                          buildMediaSectionWithSeeAll('Upcoming Sequels', ms.upcomingSequelsAnime, ItemType.anime,
                            onRefresh: () => ms.refreshSection('upcoming', isAnime: true)),
                        if (ms.catchUpAnime.isNotEmpty)
                          buildMediaSectionWithSeeAll('Catch Up', ms.catchUpAnime, ItemType.anime,
                            onRefresh: () => ms.refreshSection('catchup', isAnime: true)),
                      ],
                    );
                  }),
                  Obx(() {
                    final filteredList =
                        communityService.getFilteredCommunityAnimes();
                    if (filteredList.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return buildUnderratedSection(
                        'Community Recommendations', filteredList,
                        onSeeAll: () =>
                            navigate(() => CommunityRecommendationsPage(
                                  category: 'anime',
                                  type: ItemType.anime,
                                )));
                  }),
                ],
              )),
      ].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) => [
        Obx(() => trendingManga.isEmpty
            ? const Center(child: AnymexProgressIndicator())
            : Column(
                children: [
                  buildBigCarousel(trendingManga, true),
                  buildMediaSectionWithSeeAll("Trending Manga", trendingManga, ItemType.manga),
                  buildMediaSectionWithSeeAll("Top Manga", topManga, ItemType.manga),
                  buildMediaSectionWithSeeAll("Top Manhwa", topManhwa, ItemType.manga),
                  buildMediaSectionWithSeeAll("Top Manhua", topManhua, ItemType.manga),
                  Obx(() {
                    final ms = missingSequelService;
                    if (!isLoggedIn.value) return const SizedBox.shrink();
                    return Column(
                      children: [
                        if (ms.missingSequelsManga.isNotEmpty)
                          buildMediaSectionWithSeeAll('Missing Sequels', ms.missingSequelsManga, ItemType.manga,
                            onRefresh: () => ms.refreshSection('check', isAnime: false)),
                        if (ms.upcomingSequelsManga.isNotEmpty)
                          buildMediaSectionWithSeeAll('Upcoming Sequels', ms.upcomingSequelsManga, ItemType.manga,
                            onRefresh: () => ms.refreshSection('upcoming', isAnime: false)),
                        if (ms.catchUpManga.isNotEmpty)
                          buildMediaSectionWithSeeAll('Catch Up', ms.catchUpManga, ItemType.manga,
                            onRefresh: () => ms.refreshSection('catchup', isAnime: false)),
                      ],
                    );
                  }),
                  ...sourceController.novelSections.value,
                  Obx(() {
                    final filteredList =
                        communityService.getFilteredCommunityMangas();
                    if (filteredList.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return buildUnderratedMangaSection(
                        'Community Recommendations', filteredList,
                        onSeeAll: () =>
                            navigate(() => CommunityRecommendationsPage(
                                  category: 'manga',
                                  type: ItemType.manga,
                                )));
                  }),
                ],
              )),
      ].obs;

  @override
  Future<void> fetchHomePage() async {
    try {
      trendingAnimes.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/anime/ranking?ranking_type=airing&limit=15'))
          .removeDupes();
      for (var i in trendingAnimes) {
        print("${i.cover} - ${i.poster}");
      }
      popularAnimes.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/anime/ranking?ranking_type=bypopularity&limit=15'))
          .removeDupes();
      topAnimes.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/anime/ranking?ranking_type=tv&limit=15'))
          .removeDupes();
      upcomingAnimes.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/anime/ranking?ranking_type=upcoming&limit=15'))
          .removeDupes();

      trendingManga.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/manga/ranking?ranking_type=all&limit=15'))
          .removeDupes();
      topManga.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manga&limit=15'))
          .removeDupes();
      topManhwa.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manhwa&limit=15'))
          .removeDupes();
      topManhua.value = (await fetchDataFromApi(
              'https://api.myanimelist.net/v2/manga/ranking?ranking_type=manhua&limit=15'))
          .removeDupes();

      await communityService.fetchAll();
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
    final response = await http.get(
      Uri.parse(
          'https://api.jikan.moe/v4/$mediaType?q=${Uri.encodeComponent(params.query)}&limit=25&page=${params.page}&sfw=${!params.args}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List<dynamic>)
          .map((e) => Media.fromJikan(e, isManga: params.isManga))
          .toList()
          .removeDupes();
    } else {
      Logger.i('Jikan search failed: ${response.statusCode}');
      return [];
    }
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
      if (isLoggedIn.value) ...[
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop ? 300.0 : constraints.maxWidth / 2 - 40;
          final overflow = constraints.maxWidth < 900;
          final overflowSecond =
              !isDesktop ? false : constraints.maxWidth < 600;
          final animeButtonMedia = _firstMediaWithCover(trendingAnimes);
          final mangaButtonMedia = _firstMediaWithCover(
            trendingManga.isNotEmpty ? trendingManga : trendingMangas,
          );
          final otherButtonMedia = _lastMediaWithCover([
            ...popularAnimes,
            ...(topManga.isNotEmpty ? topManga : popularMangas),
            ...(trendingManga.isNotEmpty ? trendingManga : trendingMangas),
            ...trendingAnimes,
          ]);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            children: [
              ImageButton(
                width: width,
                height: !isDesktop ? 70 : 90,
                buttonText: "ANIME LIST",
                backgroundImage: animeButtonMedia?.cover ?? '',
                borderRadius: 16.multiplyRadius(),
                onPressed: () {
                  navigate(() => const AnimeList());
                },
                onLongPress: animeButtonMedia == null
                    ? null
                    : () => _openHomeButtonMedia(animeButtonMedia),
              ),
              Padding(
                padding: EdgeInsets.only(top: overflowSecond ? 8.0 : 0),
                child: ImageButton(
                  width: width,
                  height: !isDesktop ? 70 : 90,
                  buttonText: "MANGA LIST",
                  borderRadius: 16.multiplyRadius(),
                  backgroundImage: mangaButtonMedia?.cover ?? '',
                  onPressed: () {
                    navigate(() => const AnilistMangaList());
                  },
                  onLongPress: mangaButtonMedia == null
                      ? null
                      : () => _openHomeButtonMedia(mangaButtonMedia),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: overflow ? 8.0 : 0),
                child: ImageButton(
                  width: constraints.maxWidth > (width * 3)
                      ? width
                      : width * 2 + 15,
                  height: !isDesktop ? 70 : 90,
                  buttonText: "OTHER",
                  borderRadius: 16.multiplyRadius(),
                  backgroundImage: otherButtonMedia?.cover ?? '',
                  onPressed: () {
                    navigate(() => const OtherFeaturesPage());
                  },
                  onLongPress: otherButtonMedia == null
                      ? null
                      : () => _openHomeButtonMedia(otherButtonMedia),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 10),
        Obx(() => Column(
              children: acceptedLists.map((e) {
                final isManga = e.contains("Manga") || e.contains("Reading");
                final filteredData = filterListByLabel(isManga ? mangaList : animeList, e);
                return ReusableCarousel(
                  data: filteredData,
                  title: e,
                  variant: DataVariant.anilist,
                  type: isManga ? ItemType.manga : ItemType.anime,
                  onSeeAll: () => navigate(() => MediaSeeAllPage(
                    title: e,
                    dataList: filteredData,
                    type: isManga ? ItemType.manga : ItemType.anime,
                    variant: DataVariant.anilist,
                  )),
                );
              }).toList(),
            )),
      ],
      buildMediaSectionWithSeeAll("Trending Animes", trendingAnimes, ItemType.anime),
      buildMediaSectionWithSeeAll("Popular Animes", popularAnimes, ItemType.anime),
      buildMediaSectionWithSeeAll("Trending Manga", trendingManga, ItemType.manga),
      buildMediaSectionWithSeeAll("Popular Manga", topManga, ItemType.manga),
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
    final tokenn = token ?? AuthKeys.malAuthToken.get<String?>();
    final data = await fetchMAL('https://api.myanimelist.net/v2/users/@me',
        auth: true, useAuthHeader: true, token: tokenn);
    profileData.value = Profile.fromKitsu(data);
    isLoggedIn.value = true;
    Get.find<MissingSequelService>().fetchAll();
    Future.wait([fetchUserAnimeList(), fetchUserMangaList()]);
  }

  @override
  Future<void> autoLogin() async {
    try {
      final token = AuthKeys.malAuthToken.get<String?>();
      final refreshToken = AuthKeys.malRefreshToken.get<String?>();

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
      final response = await http.get(
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

    final response = await http.post(
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

      AuthKeys.malAuthToken.set(newToken);
      if (newRefreshToken != null) {
        AuthKeys.malRefreshToken.set(newRefreshToken);
      }

      Logger.i("Token refreshed successfully.");
      await fetchUserInfo(token: newToken);
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  @override
  Future<void> login(BuildContext context) async {
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
        await _fetchAndStoreMalSessionId();
      }
    } catch (e) {
      Logger.i('Error during MyAnimeList login: $e');
    }
  }

  Future<void> _fetchAndStoreMalSessionId() async {
    try {
      final token = AuthKeys.malAuthToken.get<String?>();
      if (token == null) {
        Logger.i('No MAL token found for session fetch');
        return;
      }

      Logger.i('Attempting to fetch MAL session ID with token');

      final response = await http.get(
        Uri.parse('https://myanimelist.net/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.headers.containsKey('set-cookie')) {
        final cookies = response.headers['set-cookie']!;
        Logger.i('Raw cookie header: $cookies');

        final patterns = [
          RegExp(r'MALHLOGSESSID=([^;]+)'),
          RegExp(r'mal_session_id=([^;]+)'),
          RegExp(r'session_id=([^;]+)'),
        ];

        for (final pattern in patterns) {
          final match = pattern.firstMatch(cookies);
          if (match != null) {
            final sessionId = match.group(1);
            if (sessionId != null && sessionId.isNotEmpty) {
              AuthKeys.malSessionId.set(sessionId);
              Logger.i('MAL session ID stored successfully: $sessionId');
              final verify = AuthKeys.malSessionId.get<String?>();
              Logger.i('Verification - stored session: $verify');
              return;
            }
          }
        }
      }

      Logger.i('No session cookie in main page, trying export page');
      final exportResponse = await http.get(
        Uri.parse('https://myanimelist.net/panel.php?go=export'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (exportResponse.headers.containsKey('set-cookie')) {
        final cookies = exportResponse.headers['set-cookie']!;
        final match = RegExp(r'MALHLOGSESSID=([^;]+)').firstMatch(cookies);
        if (match != null) {
          final sessionId = match.group(1);
          if (sessionId != null && sessionId.isNotEmpty) {
            AuthKeys.malSessionId.set(sessionId);
            Logger.i('MAL session ID stored from export page: $sessionId');
            final verify = AuthKeys.malSessionId.get<String?>();
            Logger.i('Verification - stored session: $verify');
          }
        }
      }

      if (AuthKeys.malSessionId.get<String?>() == null) {
        Logger.i('Attempting to create session via export form');
        final formResponse = await http.post(
          Uri.parse('https://myanimelist.net/panel.php?go=export'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'type': '1',
            'subexport': 'Export My List',
          },
        );

        if (formResponse.headers.containsKey('set-cookie')) {
          final cookies = formResponse.headers['set-cookie']!;
          final match = RegExp(r'MALHLOGSESSID=([^;]+)').firstMatch(cookies);
          if (match != null) {
            final sessionId = match.group(1);
            if (sessionId != null && sessionId.isNotEmpty) {
              AuthKeys.malSessionId.set(sessionId);
              Logger.i('MAL session ID created via export: $sessionId');
            }
          }
        }
      }
    } catch (e) {
      Logger.i('Error fetching MAL session ID: $e');
    }
  }

  Future<void> _exchangeCodeForTokenMAL(
      String code, String clientId, String codeVerifier, String secret) async {
    final response = await http.post(
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

      AuthKeys.malAuthToken.set(token);
      if (refreshToken != null) {
        AuthKeys.malRefreshToken.set(refreshToken);
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
      final tokenn = token ?? AuthKeys.malAuthToken.get<String?>();
      final response = await http.get(Uri.parse(url),
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
          final rep = await http.get(
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
    final startedAt = params.startedAt;
    final completedAt = params.completedAt;

    final token = AuthKeys.malAuthToken.get<String?>();
    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');

    String _formatMalDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final body = {
      if (status != null)
        'status': getMALStatusEquivalent(status, isAnime: isAnime),
      if (score != null) 'score': score.toInt().toString(),
      if (progress != null && isAnime)
        'num_watched_episodes': progress.toString(),
      if (progress != null && !isAnime)
        'num_chapters_read': progress.toString(),
      if (startedAt != null) 'start_date': _formatMalDate(startedAt),
      if (completedAt != null) 'finish_date': _formatMalDate(completedAt),
    };

    final req = await http.put(
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
          isAnime: isAnime,
          startedAt: startedAt,
          completedAt: completedAt));
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
      missingSequelService.onListChanged(isAnime: isAnime);
    } else {
      Logger.i('Error: ${req.body}');
      Logger.i('$isAnime: $body');
    }
  }

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    final token = AuthKeys.malAuthToken.get<String?>();

    final url = Uri.parse(
        'https://api.myanimelist.net/v2/${isAnime ? 'anime' : 'manga'}/$listId/my_list_status');

    final req = await http.delete(
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
      final number = savedAnime?.currentEpisode?.number?.toInt() ?? 0;
      currentMedia.value = animeList.firstWhere((el) => el.id == id,
          orElse: () => TrackedMedia(
              episodeCount: number.toString(),
              chapterCount: number.toString()));
    }
  }

  @override
  Future<void> logout() async {
    AuthKeys.malAuthToken.delete();
    AuthKeys.malRefreshToken.delete();
    AuthKeys.malSessionId.delete();
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
