// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

class SimklService extends GetxController
    implements BaseService, OnlineService {
  RxList<Media> trendingMovies = <Media>[].obs;
  RxList<Media> trendingSeries = <Media>[].obs;
  Rx<Media> detailsData = Media(
    serviceType: ServicesType.simkl,
  ).obs;
  final storage = Hive.box('auth');

  RxList<TrackedMedia> continueWatchingMovies = <TrackedMedia>[].obs;
  RxList<TrackedMedia> continueWatchingSeries = <TrackedMedia>[].obs;

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

  @override
  Future<void> fetchHomePage() async =>
      Future.wait([fetchMovies(), fetchSeries()]);

  Future<List<Media>> searchMovies(String query) async {
    final movieUrl = Uri.parse(
        'https://api.simkl.com/search/movie?q=$query&extended=full&client_id=${dotenv.env['SIMKL_CLIENT_ID']}');
    final resp = await get(movieUrl);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      List<Media> list = data.map((e) => Media.fromSimkl(e, true)).toList();
      return list;
    }
    return [];
  }

  Future<List<Media>> searchSeries(String query) async {
    final movieUrl = Uri.parse(
        'https://api.simkl.com/search/tv?q=$query&extended=full&client_id=${dotenv.env['SIMKL_CLIENT_ID']}');
    final resp = await get(movieUrl);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      List<Media> list = data.map((e) => Media.fromSimkl(e, true)).toList();
      return list;
    }
    return [];
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final movieData = await searchMovies(params.query);
    final seriesData = await searchSeries(params.query);
    return [...movieData, ...seriesData];
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    final isDesktop = Get.width > 600;
    return [
      if (isLoggedIn.value)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageButton(
              width: isDesktop ? 300 : Get.width / 2 - 40,
              height: !isDesktop ? 70 : 90,
              buttonText: "MOVIES LIST",
              backgroundImage: trendingMovies
                      .firstWhere(
                        (e) => e.cover != null,
                        orElse: () =>
                            Media(cover: '', serviceType: ServicesType.simkl),
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
              width: isDesktop ? 300 : Get.width / 2 - 40,
              height: !isDesktop ? 70 : 90,
              buttonText: "SERIES LIST",
              borderRadius: 16.multiplyRadius(),
              backgroundImage: trendingSeries
                      .firstWhere(
                        (e) => e.cover != null,
                        orElse: () =>
                            Media(cover: '', serviceType: ServicesType.simkl),
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
        ),
      const SizedBox(height: 25),
      buildSection("Planned Movies", continueWatchingMovies.value,
          variant: DataVariant.anilist),
      buildSection("Continue Watching (SHOWS)", continueWatchingSeries.value,
          variant: DataVariant.anilist),
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
          ReusableCarousel(
              data: trendingMovies.value.sublist(0, 10),
              title: "Trending Movies"),
          ReusableCarousel(
              data: trendingMovies.value.sublist(11, 20),
              title: "More Trending Movies"),
          ReusableCarousel(
              data: trendingMovies.value.sublist(21, 30),
              title: "More than More Trending Movies"),
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
          ReusableCarousel(
              data: trendingSeries.value.sublist(0, 10),
              title: "Trending Series"),
          ReusableCarousel(
              data: trendingSeries.value.sublist(11, 20),
              title: "More Trending Series"),
          ReusableCarousel(
              data: trendingSeries.value.sublist(21, trendingSeries.length - 1),
              title: "More than More Trending Series"),
        ],
      ].obs;

  @override
  RxBool isLoggedIn = false.obs;

  @override
  Rx<Profile> profileData = Profile().obs;

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    if (!isLoggedIn.value) {
      return;
    }
    final listId = params.listId;
    final status = params.status;
    final progress = params.progress;
    try {
      final isMovie = listId.split('*').last == 'MOVIE';
      final id = listId.split('*').first;

      String? newStatus = isMovie
          ? Simkl.alToSimklMovie(status ?? '')
          : Simkl.alToSimklShow(status ?? '');

      final token = await storage.get('simkl_auth_token');
      final apiKey = dotenv.env['SIMKL_CLIENT_ID'];

      if (token == null || apiKey == null) {
        Logger.i('Authentication token or API key missing');
        return;
      }

      final alrExist =
          (isMovie ? animeList : mangaList).any((e) => e.id == listId);

      final url = Uri.parse(alrExist
          ? 'https://api.simkl.com/sync/history'
          : 'https://api.simkl.com/sync/add-to-list');

      final body = isMovie
          ? {
              'movies': [
                {
                  if (!alrExist) 'to': newStatus,
                  'ids': {'simkl': id},
                }
              ]
            }
          : {
              'shows': [
                {
                  if (!alrExist) 'to': newStatus,
                  'ids': {'simkl': id},
                  'episodes': [
                    for (int i = 1; i <= (progress ?? 1); i++) {'number': i}
                  ]
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
    final token = await storage.get('simkl_auth_token');
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
  Future<void> login() async {
    final clientId = dotenv.env['SIMKL_CLIENT_ID'];
    final redirectUri = dotenv.env['CALLBACK_SCHEME'];

    final url =
        'https://simkl.com/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri';
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
    final redirectUri = dotenv.env['CALLBACK_SCHEME'];
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
        "redirect_uri": redirectUri,
        "grant_type": "authorization_code"
      }),
    );

    if (req.statusCode == 200) {
      final data = json.decode(req.body);
      final token = data['access_token'];
      await storage.put('simkl_auth_token', token);
      isLoggedIn.value = true;
      await fetchUserInfo();
      snackBar("Simkl Logined Successfully!");
    } else {
      Logger.i('${req.statusCode}: ${req.body}');
      snackBar("Yep, Failed");
    }
  }

  Future<void> fetchUserInfo() async {
    final token = await storage.get('simkl_auth_token');
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
    final token = await storage.get('simkl_auth_token');
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
    final token = await storage.get('simkl_auth_token');
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
    await storage.delete('simkl_auth_token');
    isLoggedIn.value = false;
    profileData.value = Profile();
  }

  @override
  Future<void> autoLogin() async {
    final token = await storage.get('simkl_auth_token');
    if (token != null) {
      await fetchUserInfo();
    }
  }

  @override
  Future<void> refresh() async =>
      Future.wait([fetchUserMovieList(), fetchUserSeriesList()]);
}
