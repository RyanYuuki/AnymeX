// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:math' as math;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/screens/community/community_recommendations_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

class SimklService extends GetxController
    implements BaseService, OnlineService {

  void _triggerCloudTokenSync() {
    try {
      if (Get.isRegistered<CloudSyncService>()) {
        Get.find<CloudSyncService>().autoSyncServiceTokens('simkl');
      }
    } catch (_) {}
  }

  RxList<Media> trendingMovies = <Media>[].obs;
  RxList<Media> trendingSeries = <Media>[].obs;
  Rx<Media> detailsData = Media(
    serviceType: ServicesType.simkl,
  ).obs;
  RxList<TrackedMedia> continueWatchingMovies = <TrackedMedia>[].obs;
  RxList<TrackedMedia> continueWatchingSeries = <TrackedMedia>[].obs;
  RxList<Media> koreanSeries = <Media>[].obs;
  RxList<Media> japaneseSeries = <Media>[].obs;
  RxList<Media> usSeries = <Media>[].obs;
  RxList<Media> ukSeries = <Media>[].obs;
  RxList<Media> canadaSeries = <Media>[].obs;
  RxList<Media> koreanMovies = <Media>[].obs;
  RxList<Media> usMovies = <Media>[].obs;
  RxList<Media> ukMovies = <Media>[].obs;
  RxList<Media> canadaMovies = <Media>[].obs;

  final communityService = Get.find<CommunityService>();

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final id = params.id;
    final newId = id.split('*').first;
    final isSeries = id.split('*').last == "SERIES";
    Logger.i(isSeries.toString());
    final resp = await get(Uri.parse(
        "https://api.simkl.com/${isSeries ? 'tv' : 'movies'}/$newId?extended=full&client_id=${dotenv.env['SIMKL_CLIENT_ID']}"));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      data['id'] = '$newId*${isSeries ? "SERIES" : "MOVIE"}';
      data['__isMovie'] = !isSeries;
      cacheController.addCache(data);
      detailsData.value = Media.fromSimkl(data, !isSeries);
      return detailsData.value;
    } else {
      throw Exception('Failed to fetch trending movies: ${resp.statusCode}');
    }
  }

  Future<void> fetchMovies() async {
    final url =
        "https://api.simkl.com/movies/trending?extended=overview&client_id=${dotenv.env['SIMKL_CLIENT_ID']}&perPage=20";
    final resp = await get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      final list = data.map((e) {
        return Media.fromSimkl(e, true);
      }).toList();
      trendingMovies.value = list;
    } else {
      Logger.i(url);
      Logger.i("Error Ocurred: ${resp.body}");
      throw Exception('Failed to fetch trending movies: ${resp.statusCode}');
    }
  }

  Future<void> fetchSeries() async {
    final resp = await get(Uri.parse(
        "https://api.simkl.com/tv/trending?extended=overview&client_id=${dotenv.env['SIMKL_CLIENT_ID']}"));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      final list = data.map((e) {
        return Media.fromSimkl(e, false);
      }).toList();
      trendingSeries.value = list;
    } else {
      throw Exception('Failed to fetch trending series: ${resp.statusCode}');
    }
  }

  Future<List<Media>> _fetchTvGenres(String country) async {
    final url =
        "https://api.simkl.com/tv/genres/all/all-types/$country/all-networks/all-years/rank?extended=overview&client_id=${dotenv.env['SIMKL_CLIENT_ID']}&limit=20";
    final resp = await get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Media.fromSimkl(e, false)).toList();
    }
    Logger.i("Failed to fetch TV genres for $country: ${resp.statusCode}");
    return [];
  }

  Future<List<Media>> _fetchMovieGenres(String country) async {
    final url =
        "https://api.simkl.com/movies/genres/all/all-types/$country/all-years/rank?extended=overview&client_id=${dotenv.env['SIMKL_CLIENT_ID']}&limit=20";
    final resp = await get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Media.fromSimkl(e, true)).toList();
    }
    Logger.i("Failed to fetch movie genres for $country: ${resp.statusCode}");
    return [];
  }

  Future<void> fetchCountrySeries() async {
    final results = await Future.wait([
      _fetchTvGenres('kr'),
      _fetchTvGenres('jp'),
      _fetchTvGenres('us'),
      _fetchTvGenres('gb'),
      _fetchTvGenres('ca'),
    ]);
    koreanSeries.value = results[0];
    japaneseSeries.value = results[1];
    usSeries.value = results[2];
    ukSeries.value = results[3];
    canadaSeries.value = results[4];
  }

  Future<void> fetchCountryMovies() async {
    final results = await Future.wait([
      _fetchMovieGenres('kr'),
      _fetchMovieGenres('us'),
      _fetchMovieGenres('gb'),
      _fetchMovieGenres('ca'),
    ]);
    koreanMovies.value = results[0];
    usMovies.value = results[1];
    ukMovies.value = results[2];
    canadaMovies.value = results[3];
  }

  @override
  Future<void> fetchHomePage() async => Future.wait([
        fetchMovies(),
        fetchSeries(),
        fetchCountryMovies(),
        fetchCountrySeries(),
        communityService.fetchCommunityShows(),
        communityService.fetchCommunityMovies(),
      ]);

  Future<List<Media>> searchMovies(String query, {int page = 1}) async {
    final movieUrl = Uri.https('api.simkl.com', '/search/movie', {
      'q': query,
      'extended': 'full',
      'page': '$page',
      'limit': '25',
      'client_id': '${dotenv.env['SIMKL_CLIENT_ID']}',
    });
    final resp = await get(movieUrl);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      List<Media> list = data.map((e) => Media.fromSimkl(e, true)).toList();
      return list;
    }
    return [];
  }

  Future<List<Media>> searchSeries(String query, {int page = 1}) async {
    final seriesUrl = Uri.https('api.simkl.com', '/search/tv', {
      'q': query,
      'extended': 'full',
      'page': '$page',
      'limit': '25',
      'client_id': '${dotenv.env['SIMKL_CLIENT_ID']}',
    });
    final resp = await get(seriesUrl);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      List<Media> list = data.map((e) => Media.fromSimkl(e, true)).toList();
      return list;
    }
    return [];
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final movieData = await searchMovies(params.query, page: params.page);
    final seriesData = await searchSeries(params.query, page: params.page);
    return [...movieData, ...seriesData];
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    return [
      if (isLoggedIn.value)
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final buttonHeight = !isDesktop ? 70.0 : 90.0;
            final itemWidth = isDesktop
                ? math.min(300.0, (constraints.maxWidth - 15) / 2)
                : (constraints.maxWidth / 2) - 20;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageButton(
                  width: itemWidth,
                  height: buttonHeight,
                  buttonText: "MOVIES LIST",
                  backgroundImage: trendingMovies
                          .firstWhere(
                            (e) => e.cover != null,
                            orElse: () => Media(
                                cover: '', serviceType: ServicesType.simkl),
                          )
                          .cover ??
                      '',
                  borderRadius: 16.multiplyRadius(),
                  onPressed: () {
                    navigate(() => AnimeList(
                          title: "Movies",
                          data: animeList.value,
                        ));
                  },
                ),
                const SizedBox(width: 15),
                ImageButton(
                  width: itemWidth,
                  height: buttonHeight,
                  buttonText: "SERIES LIST",
                  borderRadius: 16.multiplyRadius(),
                  backgroundImage: trendingSeries
                          .firstWhere(
                            (e) => e.cover != null,
                            orElse: () => Media(
                                cover: '', serviceType: ServicesType.simkl),
                          )
                          .cover ??
                      '',
                  onPressed: () {
                    navigate(() => AnimeList(
                          title: "Shows",
                          data: mangaList.value,
                        ));
                  },
                ),
              ],
            );
          },
        ),
      const SizedBox(height: 15),
      LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          final buttonHeight = !isDesktop ? 70.0 : 90.0;
          final buttonWidth =
              isDesktop ? 300.0 : math.max(120.0, constraints.maxWidth - 40);
          return Center(
            child: ImageButton(
              width: buttonWidth,
              height: buttonHeight,
              buttonText: "CALENDAR",
              borderRadius: 16.multiplyRadius(),
              backgroundImage: trendingMovies.isNotEmpty
                  ? trendingMovies[0].cover ?? ''
                  : '',
              onPressed: () {
                navigate(() => const Calendar());
              },
            ),
          );
        },
      ),
      const SizedBox(height: 25),
      if (isLoggedIn.value) ...[
        buildSection("Planned Movies", continueWatchingMovies.value,
            variant: DataVariant.anilist),
        buildSection("Continue Watching (SHOWS)", continueWatchingSeries.value,
            variant: DataVariant.anilist),
      ],
      if (trendingMovies.value.isNotEmpty)
        ReusableCarousel(
            data: trendingMovies.value.sublist(0, 10),
            title: "Trending Movies"),
      if (trendingSeries.value.isNotEmpty)
        ReusableCarousel(
            data: trendingSeries.value.sublist(0, 10),
            title: "Trending Series"),
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) => [
        if (trendingMovies.isEmpty)
          const Center(
            child: AnymexProgressIndicator(),
          )
        else ...[
          // TappableSearchBar(
          //   onSubmitted: () {
          //     // navigate(() => const SearchPage(
          //     //       searchTerm: "",
          //     //       isManga: false,
          //     //     ));
          //     searchTypeSheet(context, "");
          //   },
          //   chipLabel: ("MOVIES"),
          //   hintText: "Search Movie...",
          // ),
          buildBigCarousel(trendingMovies.value.sublist(0, 10), false,
              type: CarouselType.simkl),
          if (trendingMovies.value.isNotEmpty)
            ReusableCarousel(
                data: trendingMovies.value.sublist(0, 10),
                title: "Trending Movies"),
          if (koreanMovies.value.isNotEmpty)
            ReusableCarousel(data: koreanMovies.value, title: "Korean Movies"),
          if (usMovies.value.isNotEmpty)
            ReusableCarousel(data: usMovies.value, title: "US Movies"),
          if (ukMovies.value.isNotEmpty)
            ReusableCarousel(data: ukMovies.value, title: "UK Movies"),
          if (canadaMovies.value.isNotEmpty)
            ReusableCarousel(
                data: canadaMovies.value, title: "Canadian Movies"),
          Obx(() {
            final list = communityService.getFilteredCommunityMovies();
            return buildUnderratedSection('Community Recommendations', list,
                onSeeAll: () => navigate(() => CommunityRecommendationsPage(
                      category: 'movies',
                      type: ItemType.anime,
                    )));
          }),
        ],
      ].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) => [
        if (trendingSeries.isEmpty)
          const Center(
            child: AnymexProgressIndicator(),
          )
        else ...[
          // CustomSearchBar(
          //   onSubmitted: (val) {
          //     navigate(() => SearchPage(
          //           searchTerm: val,
          //           isManga: false,
          //         ));
          //   },
          //   suffixIconWidget: buildChip("SERIES"),
          //   disableIcons: true,
          //   hintText: "Search Series...",
          // ),
          buildBigCarousel(trendingSeries.value.sublist(0, 10), false,
              type: CarouselType.simkl),
          if (trendingSeries.value.isNotEmpty)
            ReusableCarousel(
                data: trendingSeries.value.sublist(0, 10),
                title: "Trending Series"),
          if (koreanSeries.value.isNotEmpty)
            ReusableCarousel(data: koreanSeries.value, title: "K-Dramas"),
          if (japaneseSeries.value.isNotEmpty)
            ReusableCarousel(data: japaneseSeries.value, title: "J-Dramas"),
          if (usSeries.value.isNotEmpty)
            ReusableCarousel(data: usSeries.value, title: "US Shows"),
          if (ukSeries.value.isNotEmpty)
            ReusableCarousel(data: ukSeries.value, title: "UK Shows"),
          if (canadaSeries.value.isNotEmpty)
            ReusableCarousel(data: canadaSeries.value, title: "Canadian Shows"),
          Obx(() {
            final list = communityService.getFilteredCommunityShows();
            return buildUnderratedSection('Community Recommendations', list,
                onSeeAll: () => navigate(() => CommunityRecommendationsPage(
                      category: 'shows',
                      type: ItemType.anime,
                    )));
          }),
        ],
      ].obs;

  @override
  RxBool isLoggedIn = false.obs;

  @override
  Rx<Profile> profileData = Profile().obs;

  Future<Map<int, int>> getEpisodesBySeason(String listId) async {
    final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
    if (apiKey == null) return {};

    final isMovie = listId.split('*').last.toUpperCase() == 'MOVIE';
    if (isMovie) return {1: 1};

    final id = listId.split('*').first;
    final isAnime = listId.split('*').last.toUpperCase() == 'ANIME';

    Future<Map<int, int>> fetchFrom(String endpointType) async {
      final url = Uri.parse(
          'https://api.simkl.com/$endpointType/episodes/$id?client_id=$apiKey');
      try {
        final response =
            await get(url, headers: {'Content-Type': 'application/json'});
        if (response.statusCode == 200) {
          final dynamic decoded = json.decode(response.body);
          if (decoded is! List || decoded.isEmpty) return {};
          final seasons = <int, int>{};
          for (final ep in decoded) {
            int s = 1;
            final directSeason = ep['season'];
            if (directSeason != null) {
              s = directSeason is int
                  ? directSeason
                  : int.tryParse(directSeason.toString()) ?? 1;
            } else if (ep['tvdb'] is Map && ep['tvdb']['season'] != null) {
              final tvdbSeason = ep['tvdb']['season'];
              s = tvdbSeason is int
                  ? tvdbSeason
                  : int.tryParse(tvdbSeason.toString()) ?? 1;
            }
            seasons[s] = (seasons[s] ?? 0) + 1;
          }
          Logger.i('[Simkl/$endpointType] Season map for $id: $seasons');
          return seasons;
        }
        Logger.i(
            '[Simkl/$endpointType] HTTP ${response.statusCode} for id=$id');
      } catch (e) {
        Logger.i('[Simkl/$endpointType] Error for $id: $e');
      }
      return {};
    }

    final endpoint = isAnime ? 'anime' : 'tv';
    final fallbackEndpoint = isAnime ? 'tv' : 'anime';

    var seasons = await fetchFrom(endpoint);
    if (seasons.isEmpty) {
      seasons = await fetchFrom(fallbackEndpoint);
    }

    return seasons;
  }

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    if (!isLoggedIn.value) {
      return;
    }
    final String listId = params.listId;
    final double? score = params.score;
    final String? status = params.status;
    final int? progress = params.progress;
    final bool isAnime = params.isAnime;
    final int? season = params.season;
    try {
      final isMovie = listId.split('*').last == 'MOVIE';
      final id = listId.split('*').first;

      final token = AuthKeys.simklAuthToken.get<String?>();
      final apiKey = dotenv.env['SIMKL_CLIENT_ID'];

      if (token == null || apiKey == null) {
        Logger.i('Authentication token or API key missing');
        return;
      }

      final url = Uri.parse('https://api.simkl.com/sync/add-to-list');

      if (status != null) {
        String newStatus = isMovie
            ? Simkl.alToSimklMovie(status)
            : Simkl.alToSimklShow(status);

        final body = isMovie
            ? {
                'movies': [
                  {
                    'to': newStatus,
                    'ids': {'simkl': id},
                  }
                ]
              }
            : {
                'shows': [
                  {
                    'to': newStatus,
                    'ids': {'simkl': id},
                  }
                ]
              };

        final response = await post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'simkl-api-key': apiKey,
          },
          body: jsonEncode(body),
        );
        Logger.i(response.body);
      }

      if (progress != null && progress > 0 && status != 'PLANNING') {
        final historyUrl = Uri.parse('https://api.simkl.com/sync/history');
        final effectiveSeason = (season != null && season > 0) ? season : 1;
        final historyBody = isMovie
            ? null
            : {
                'shows': [
                  {
                    'ids': {'simkl': id},
                    'seasons': [
                      {
                        'number': effectiveSeason,
                        'episodes': [
                          for (int i = 1; i <= progress; i++) {'number': i}
                        ]
                      }
                    ]
                  }
                ]
              };

        if (historyBody != null) {
          await post(historyUrl,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'simkl-api-key': apiKey,
              },
              body: jsonEncode(historyBody));
        }
      }

      if (score != null && score > 0) {
        final ratingsUrl = Uri.parse('https://api.simkl.com/sync/ratings');
        final ratingsBody = isMovie
            ? {
                'movies': [
                  {
                    'rating': score.toInt(),
                    'ids': {'simkl': id},
                  }
                ]
              }
            : {
                'shows': [
                  {
                    'rating': score.toInt(),
                    'ids': {'simkl': id},
                  }
                ]
              };
        await post(
          ratingsUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'simkl-api-key': apiKey,
          },
          body: jsonEncode(ratingsBody),
        );
      }

      if (progress != null) {
        currentMedia.value.episodeCount = progress.toString();
      }
      // snackBar('${isMovie ? "Movie" : "Series"} Tracked Successfully');
      isMovie ? fetchUserMovieList() : fetchUserSeriesList();
    } catch (e, stack) {
      Logger.i('Exception: $e\n$stack');
      errorSnackBar('An unexpected error occurred');
    }
  }

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    final isMovie = listId.split('*').last == 'MOVIE';
    final id = listId.split('*').first;
    final token = AuthKeys.simklAuthToken.get<String?>();
    final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
    final url = Uri.parse('https://api.simkl.com/sync/history/remove');
    final response = await post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'simkl-api-key': apiKey!
        },
        body: json.encode(isMovie
            ? {
                'movies': [
                  {
                    'ids': {'simkl': id}
                  }
                ]
              }
            : {
                'shows': [
                  {
                    'ids': {'simkl': id}
                  }
                ]
              }));
    Logger.i(response.body);

    snackBar('${isMovie ? "Movie" : "Series"} Deleted Successfully');
    currentMedia.value = TrackedMedia();
    fetchUserMovieList();
    fetchUserSeriesList();
  }

  @override
  RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;

  @override
  Rx<TrackedMedia> currentMedia = TrackedMedia().obs;

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    final isMovie = id.split('*').last == "MOVIE";
    if (!isMovie) {
      currentMedia.value =
          mangaList.firstWhere((e) => e.id == id, orElse: () => TrackedMedia());
    } else {
      currentMedia.value = animeList.firstWhere((e) {
        Logger.i('Searching: $id ${e.id}');
        return e.id == id;
      }, orElse: () => TrackedMedia());
    }
  }

  // Series
  @override
  RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;

  @override
  Future<void> login(BuildContext context) async {
    final clientId = dotenv.env['SIMKL_CLIENT_ID'];

    final url =
        'https://simkl.com/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=anymex://callback';
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'anymex',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(code);
      }
    } catch (e) {
      Logger.i(e.toString());
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    final clientId = dotenv.env['SIMKL_CLIENT_ID'];
    final clientSecret = dotenv.env['SIMKL_CLIENT_SECRET'];

    final url = Uri.parse('https://api.simkl.com/oauth/token');
    final req = await post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "code": code,
        "client_id": clientId,
        "client_secret": clientSecret,
        "redirect_uri": "anymex://callback",
        "grant_type": "authorization_code"
      }),
    );

    if (req.statusCode == 200) {
      final data = json.decode(req.body);
      final token = data['access_token'];
      AuthKeys.simklAuthToken.set(token);
      isLoggedIn.value = true;
      await fetchUserInfo();
      snackBar("Simkl Logined Successfully!");
      _triggerCloudTokenSync();
    } else {
      Logger.i('${req.statusCode}: ${req.body}');
      snackBar("Yep, Failed");
    }
  }

  Future<void> fetchUserInfo() async {
    final token = AuthKeys.simklAuthToken.get<String?>();
    final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
    final url = Uri.parse('https://api.simkl.com/users/settings');
    final response = await post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'simkl-api-key': apiKey!
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final req = await post(
          Uri.parse(
              'https://api.simkl.com/users/${data['account']['id']}/stats'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'simkl-api-key': apiKey
          });
      final stats = jsonDecode(req.body);
      isLoggedIn.value = true;
      profileData.value = Profile(
          id: data['account']['id']?.toString() ?? 'Guest',
          name: data['user']['name'] ?? 'Guest',
          avatar: data['user']['avatar'],
          stats: ProfileStatistics(
              animeStats: AnimeStats(
                animeCount:
                    stats['movies']?['completed']?['count']?.toString() ?? '??',
              ),
              mangaStats: MangaStats(
                  mangaCount:
                      stats['tv']?['completed']?['count']?.toString())));
      fetchUserMovieList();
      fetchUserSeriesList();
    } else {
      snackBar("User Info Fetching Failed!");
    }
  }

  Future<void> fetchUserMovieList() async {
    final token = AuthKeys.simklAuthToken.get<String?>();
    final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
    final url = Uri.parse('https://api.simkl.com/sync/all-items/movies');
    final response = await get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'simkl-api-key': apiKey!
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      animeList.value = (data['movies'] as List<dynamic>)
          .map((e) => TrackedMedia.fromSimklMovie(e))
          .toList();
      continueWatchingMovies.value = animeList.value
          .where((e) => e.watchingStatus != "COMPLETED")
          .toList();
    } else {
      Logger.i(response.body);
    }
  }

  Future<void> fetchUserSeriesList() async {
    final token = AuthKeys.simklAuthToken.get<String?>();
    final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
    final url = Uri.parse('https://api.simkl.com/sync/all-items/shows');
    final response = await get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'simkl-api-key': apiKey!
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      mangaList.value = (data['shows'] as List<dynamic>)
          .map((e) => TrackedMedia.fromSimklShow(e))
          .toList();
      continueWatchingSeries.value =
          mangaList.where((e) => e.watchingStatus == "CURRENT").toList();
    } else {
      Logger.i(response.body);
    }
  }

  @override
  Future<void> logout() async {
    AuthKeys.simklAuthToken.delete();
    isLoggedIn.value = false;
    profileData.value = Profile();
  }

  @override
  Future<void> autoLogin() async {
    isLoggedIn.value = false;
    profileData.value = Profile();
    final token = AuthKeys.simklAuthToken.get<String?>();
    if (token != null) {
      await fetchUserInfo();
    }
  }

  @override
  Future<void> refresh() async =>
      Future.wait([fetchUserMovieList(), fetchUserSeriesList()]);
}
