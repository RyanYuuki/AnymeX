// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:anymex/utils/oauth_helper.dart';
import 'dart:math' as math;

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
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
import 'package:anymex/widgets/anymex_widgets/anymex_image_button.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/common/installed_extensions_gridview.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/media_syncer.dart';
import 'package:anymex/widgets/common/big_carousel_gate.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:anymex/controllers/services/simkl/simkl_api.dart';

enum SimklSearchCategory { anime, movie, show }

class SimklService extends GetxController
    implements BaseService, OnlineService {
  final api = SimklApi();
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
    final media = await api.fetchDetails(params);
    detailsData.value = media;
    return media;
  }

  Future<void> fetchMovies() async {
    trendingMovies.value = await api.fetchTrending(true);
  }

  Future<void> fetchSeries() async {
    trendingSeries.value = await api.fetchTrending(false);
  }

  Future<List<Media>> _fetchTvGenres(String country) async {
    return api.fetchGenres('tv', country);
  }

  Future<List<Media>> _fetchMovieGenres(String country) async {
    return api.fetchGenres('movies', country);
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
    return api.searchMedia('movie', query, page: page);
  }

  Future<List<Media>> searchSeries(String query, {int page = 1}) async {
    return api.searchMedia('tv', query, page: page);
  }

  Future<List<Media>> searchAnime(String query, {int page = 1}) async {
    return api.searchMedia('anime', query, page: page);
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final results = await Future.wait([
      searchMovies(params.query, page: params.page),
      searchSeries(params.query, page: params.page),
      searchAnime(params.query, page: params.page),
    ]);
    final movies = results[0];
    final series = results[1];
    final anime = results[2];

    final merged = <Media>[];
    final seen = <String>{};
    final maxLen = [
      movies.length,
      series.length,
      anime.length,
    ].reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < maxLen; i++) {
      for (final list in [anime, series, movies]) {
        if (i < list.length) {
          final m = list[i];
          final key = m.title.toLowerCase().trim();
          if (seen.contains(key)) continue;
          seen.add(key);
          merged.add(m);
        }
      }
    }
    return merged;
  }

  Future<List<Media>> searchByCategory(
    String query,
    SimklSearchCategory category, {
    int page = 1,
  }) {
    switch (category) {
      case SimklSearchCategory.anime:
        return searchAnime(query, page: page);
      case SimklSearchCategory.movie:
        return searchMovies(query, page: page);
      case SimklSearchCategory.show:
        return searchSeries(query, page: page);
    }
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    final settings = Get.find<Settings>();
    final acceptedLists = settings.homePageCardsSimkl.entries
        .where((entry) => entry.value)
        .map<String>((entry) => entry.key)
        .toList();

    return [
      if (isLoggedIn.value)
        Obx(() {
          trendingMovies.length;
          trendingSeries.length;
          animeList.length;
          mangaList.length;
          return LayoutBuilder(
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
                    tagIcon: Icons.movie_filter_outlined,
                    subText: '${animeList.length} items',
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
                            data: animeList.value.removeDupes(),
                          ));
                    },
                  ),
                  const SizedBox(width: 15),
                  ImageButton(
                    width: itemWidth,
                    height: buttonHeight,
                    tagIcon: Icons.movie_filter_outlined,
                    subText: '${mangaList.length} items',
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
                            data: mangaList.value.removeDupes(),
                          ));
                    },
                  ),
                ],
              );
            },
          );
        }),
      const SizedBox(height: 15),
      Obx(() {
        trendingMovies.length;
        return LayoutBuilder(
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
                imageProportion: 0.5,
              ),
            );
          },
        );
      }),
      const SizedBox(height: 25),
      if (isLoggedIn.value && acceptedLists.isNotEmpty)
        Obx(() {
          mangaList.length;
          animeList.length;
          return Column(
            children: acceptedLists.map((e) {
              final isShowsList = e.contains("Shows") || e.contains("Series");
              final sourceList = isShowsList ? mangaList : animeList;
              final filtered = filterListByLabel(sourceList, e);
              return ReusableCarousel(
                data: filtered,
                title: e,
                variant: DataVariant.anilist,
                type: ItemType.anime,
              );
            }).toList(),
          );
        }),
      Obx(() => trendingMovies.value.isNotEmpty
          ? ReusableCarousel(
              data: trendingMovies.value
                  .sublist(0, math.min(10, trendingMovies.length)),
              title: "Trending Movies")
          : const SizedBox.shrink()),
      Obx(() => trendingSeries.value.isNotEmpty
          ? ReusableCarousel(
              data: trendingSeries.value
                  .sublist(0, math.min(10, trendingSeries.length)),
              title: "Trending Series")
          : const SizedBox.shrink()),
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) => [
        if (trendingMovies.isEmpty)
          const Center(
            child: AnymeXProgressIndicator(),
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
                onSeeAll: () =>
                    navigate(() => const CommunityRecommendationsPage(
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
            child: AnymeXProgressIndicator(),
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
                onSeeAll: () =>
                    navigate(() => const CommunityRecommendationsPage(
                          category: 'shows',
                          type: ItemType.anime,
                        )));
          }),
        ],
      ].obs;

  @override
  RxList<Widget> novelWidgets(BuildContext context) {
    return RxList.empty();
  }

  @override
  bool get isDataLoaded =>
      trendingMovies.isNotEmpty || trendingSeries.isNotEmpty;

  @override
  void clearState() {
    trendingMovies.clear();
    trendingSeries.clear();
    koreanSeries.clear();
    japaneseSeries.clear();
    usSeries.clear();
    ukSeries.clear();
    canadaSeries.clear();
    koreanMovies.clear();
    usMovies.clear();
    ukMovies.clear();
    canadaMovies.clear();
    continueWatchingMovies.clear();
    continueWatchingSeries.clear();
  }

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
            final isSpecial = ep['type'] == 'special';
            int? s;
            final directSeason = ep['season'];
            if (directSeason != null) {
              s = directSeason is int
                  ? directSeason
                  : int.tryParse(directSeason.toString());
            } else if (ep['tvdb'] is Map && ep['tvdb']['season'] != null) {
              final tvdbSeason = ep['tvdb']['season'];
              s = tvdbSeason is int
                  ? tvdbSeason
                  : int.tryParse(tvdbSeason.toString());
            }
            final finalSeason = (isSpecial || s == null || s <= 0) ? 0 : s;
            seasons[finalSeason] = (seasons[finalSeason] ?? 0) + 1;
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

  /// Syncs anime progress to Simkl using an external ID (e.g. AniList ID or MAL ID).
  /// Resolves the external ID to Simkl ID via `MediaSyncer.getSimklIdFromExternal`.
  Future<void> updateListEntryFromExternalId({
    String? anilistId,
    String? malId,
    double? score,
    String? status,
    int? progress,
    int? season,
    bool isAnime = true,
  }) async {
    if (!isLoggedIn.value) {
      return;
    }
    try {
      final simklId = await MediaSyncer.getSimklIdFromExternal(
        anilistId: anilistId,
        malId: malId,
      );

      if (simklId != null) {
        await updateListEntry(UpdateListEntryParams(
          listId: simklId,
          score: score,
          status: status,
          progress: progress,
          season: season,
          isAnime: isAnime,
        ));
      } else if (anilistId != null || malId != null) {
        // Fallback: If redirect resolution yielded no ID, update via external IDs directly in Simkl sync API
        final token = AuthKeys.simklAuthToken.get<String?>();
        final apiKey = dotenv.env['SIMKL_CLIENT_ID'];
        if (token == null || apiKey == null) return;

        final ids = <String, dynamic>{
          if (anilistId != null)
            'anilist': int.tryParse(anilistId) ?? anilistId,
          if (malId != null) 'mal': int.tryParse(malId) ?? malId,
        };

        if (status != null) {
          final url = Uri.parse('https://api.simkl.com/sync/add-to-list');
          final newStatus = Simkl.alToSimklShow(status);
          final body = {
            'shows': [
              {
                'to': newStatus,
                'ids': ids,
              }
            ]
          };
          await post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'simkl-api-key': apiKey,
            },
            body: jsonEncode(body),
          );
        }

        if (progress != null && progress > 0 && status != 'PLANNING') {
          final historyUrl = Uri.parse('https://api.simkl.com/sync/history');
          final effectiveSeason = (season != null && season > 0) ? season : 1;
          final historyBody = {
            'shows': [
              {
                'ids': ids,
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
          await post(
            historyUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'simkl-api-key': apiKey,
            },
            body: jsonEncode(historyBody),
          );
        }

        if (score != null && score > 0) {
          final ratingsUrl = Uri.parse('https://api.simkl.com/sync/ratings');
          final ratingsBody = {
            'shows': [
              {
                'rating': score.toInt(),
                'ids': ids,
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
        fetchUserSeriesList();
      }
    } catch (e, stack) {
      Logger.i('Exception in updateListEntryFromExternalId: $e\n$stack');
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
      final result = await OauthHelper.authenticate(
        context: context,
        url: url,
        callbackUrlScheme: 'anymex',
        forceWebAuth: true,
      );

      if (result != null) {
        final code = Uri.parse(result).queryParameters['code'];
        if (code != null) {
          await _exchangeCodeForToken(code);
        }
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
    final token = AuthKeys.simklAuthToken.get<String?>();
    if (token != null) {
      await fetchUserInfo();
    }
  }

  @override
  Future<void> refresh() async =>
      Future.wait([fetchUserMovieList(), fetchUserSeriesList()]);
}
