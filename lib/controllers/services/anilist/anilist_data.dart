import 'dart:convert';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:math' show min;
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/kitsu.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/anime/misc/recommendation.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart' as fbm;
import 'package:anymex/utils/fallback/fallback_anime.dart' as fb;
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

Map<String, dynamic> _parseJson(String body) {
  return jsonDecode(body) as Map<String, dynamic>;
}

class AnilistData extends GetxController implements BaseService, OnlineService {
  final anilistAuth = Get.find<AnilistAuth>();

  // Anime Data
  RxList<Media> upcomingAnimes = <Media>[].obs;
  RxList<Media> popularAnimes = <Media>[].obs;
  RxList<Media> trendingAnimes = <Media>[].obs;
  RxList<Media> latestAnimes = <Media>[].obs;
  RxList<Media> recentlyUpdatedAnimes = <Media>[].obs;

  // Manga Data
  RxList<Media> popularMangas = <Media>[].obs;
  RxList<Media> morePopularMangas = <Media>[].obs;
  RxList<Media> latestMangas = <Media>[].obs;
  RxList<Media> mostFavoriteMangas = <Media>[].obs;
  RxList<Media> topRatedMangas = <Media>[].obs;
  RxList<Media> topUpdatedMangas = <Media>[].obs;
  RxList<Media> topOngoingMangas = <Media>[].obs;
  RxList<Media> trendingMangas = <Media>[].obs;

  // Novel Data
  RxList<DMedia> novelData = <DMedia>[].obs;

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    final settings = Get.find<Settings>();
    final acceptedLists = settings.homePageCards.entries
        .where((entry) => entry.value)
        .map<String>((entry) => entry.key)
        .toList();
    final isDesktop = Get.width > 600;
    final recAnimes =
        (popularAnimes + trendingAnimes + latestAnimes).removeDupes();
    final recMangas =
        (popularMangas + topOngoingMangas + topRatedMangas).removeDupes();
    final ids = [
      animeList.map((e) => e.id).toSet(),
      mangaList.map((e) => e.id).toSet()
    ];
    return [
      if (anilistAuth.isLoggedIn.value) ...[
        LayoutBuilder(builder: (context, constraints) {
          final width = isDesktop ? 300.0 : constraints.maxWidth / 2 - 40;
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
                backgroundImage:
                    trendingAnimes.firstWhere((e) => e.cover != null).cover ??
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
                  backgroundImage:
                      trendingMangas.firstWhere((e) => e.cover != null).cover ??
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
                          ? anilistAuth.mangaList
                          : anilistAuth.animeList,
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
      Column(
        children: [
          ReusableCarousel(
            title: "Recommended Animes",
            data: isLoggedIn.value
                ? recAnimes.where((e) => !ids[0].contains(e.id)).toList()
                : recAnimes,
            type: ItemType.anime,
          ),
          ReusableCarousel(
            title: "Recommended Mangas",
            data: isLoggedIn.value
                ? recMangas.where((e) => !ids[1].contains(e.id)).toList()
                : recMangas,
            type: ItemType.manga,
          )
        ],
      )
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) {
    return [
      buildBigCarousel(trendingAnimes, false),
      buildSection('Recently Updated', recentlyUpdatedAnimes),
      buildSection('Trending Animes', trendingAnimes),
      buildSection('Popular Animes', popularAnimes),
      buildSection('Recently Completed', latestAnimes),
      buildSection('Upcoming Animes', upcomingAnimes),
    ].obs;
  }

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    return [
      buildBigCarousel(trendingMangas, true),
      buildMangaSection('Trending Mangas', trendingMangas),
      buildMangaSection('Latest Mangas', latestMangas),
      buildMangaSection('Popular Mangas', popularMangas),
      buildMangaSection('More Popular Mangas', morePopularMangas),

      // buildMangaSection('Most Favorite Mangas', mostFavoriteMangas),
      // buildMangaSection('Top Rated Mangas', topRatedMangas),
      // buildMangaSection('Top Ongoing Mangas', topOngoingMangas),
      ...sourceController.novelSections
    ].obs;
  }

  @override
  void onInit() {
    super.onInit();
    _initFallback();
  }

  void _initFallback() {
    if (trendingAnimes.isEmpty) {
      upcomingAnimes.value = fb.upcomingAnimes;
      popularAnimes.value = fb.popularAnimes;
      trendingAnimes.value = fb.trendingAnimes;
      latestAnimes.value = fb.latestAnimes;

      popularMangas.value = fbm.popularMangas;
      latestMangas.value = fbm.latestMangas;
      topOngoingMangas.value = fbm.trendingMangas;
      trendingMangas.value = fbm.trendingMangas;
    }
  }

  Future<void> fetchAnilistHomepage() async {
    const String url = 'https://graphql.anilist.co';

    const String query = '''
  query {
    upcomingAnimes: Page(page: 1, perPage: 15) {
      media(type: ANIME, status: NOT_YET_RELEASED, sort: [POPULARITY_DESC, TRENDING_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        type
        averageScore
        coverImage {
          large
        }
      }
    }
    popularAnimes: Page(page: 1, perPage: 15) {
      media(type: ANIME, sort: POPULARITY_DESC) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        type
        averageScore
        coverImage {
          large
        }
      }
    }
    trendingAnimes: Page(page: 1, perPage: 15) {
      media(type: ANIME, sort: TRENDING_DESC) {
        id
        title {
          romaji
          english
          native
        }
        description
        bannerImage
        type
        averageScore
        coverImage {
          large
        }
      }
    }
    latestAnimes: Page(page: 1, perPage: 15) {
      media(
        type: ANIME, 
        status: FINISHED, 
        sort: [END_DATE_DESC, SCORE_DESC, POPULARITY_DESC], 
        averageScore_greater: 70, 
        popularity_greater: 10000
      ) {
        id
        title {
          romaji
          english
          native
        }
        type
        averageScore
        coverImage {
          large
        }
      }
    }
    recentlyUpdatedAnimes: Page(page: 1, perPage: 15) {
    media(
      type: ANIME,
      sort: [UPDATED_AT_DESC, POPULARITY_DESC],
      status: RELEASING,
      isAdult: false,
      countryOfOrigin: "JP"
    ) {
        id
        title {
          romaji
          english
          native
        }
        type
        averageScore
        coverImage {
          large
        }
        updatedAt
      }
    }
  }
''';

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'query': query,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body)['data'];
      upcomingAnimes.value =
          parseMediaList(responseData['upcomingAnimes']['media']);
      popularAnimes.value =
          parseMediaList(responseData['popularAnimes']['media']);
      trendingAnimes.value =
          parseMediaList(responseData['trendingAnimes']['media']);
      latestAnimes.value =
          parseMediaList(responseData['latestAnimes']['media']);
      recentlyUpdatedAnimes.value =
          parseMediaList(responseData['recentlyUpdatedAnimes']['media']);
    } else {
      throw Exception('Failed to load AniList data: ${response.statusCode}');
    }
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
        type
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
        type
averageScore
      }
    }

    # Latest Mangas (Page 1)
    latestMangas: Page(page: 1, perPage: \$perPage) {
      media(status: FINISHED, 
      sort: [END_DATE_DESC, SCORE_DESC, POPULARITY_DESC], 
      averageScore_greater: 70, 
      popularity_greater: 10000, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
        type
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
        type
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
        type
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
        type
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
        type
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
        type
averageScore
      }
    }
  }
''';

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'query': query,
        'variables': {
          'perPage': 15,
        },
      }),
    );

    if (response.statusCode == 200) {
      final dynamic responsee = json.decode(response.body);
      final responseData = responsee['data'];
      popularMangas.value =
          parseMediaList(responseData['popularMangas']['media']);
      morePopularMangas.value =
          parseMediaList(responseData['morePopularMangas']['media']);
      latestMangas.value =
          parseMediaList(responseData['latestMangas']['media']);
      mostFavoriteMangas.value =
          parseMediaList(responseData['mostFavoriteMangas']['media']);
      topRatedMangas.value = parseMediaList(responseData['topRated']['media']);
      topUpdatedMangas.value =
          parseMediaList(responseData['topUpdated']['media']);
      topOngoingMangas.value =
          parseMediaList(responseData['topOngoing']['media']);
      trendingMangas.value =
          parseMediaList(responseData['trendingManga']['media']);
    } else {
      throw Exception(
          'Failed to load AniList manga data: ${response.statusCode}');
    }
  }

  List<Media> parseMediaList(List<dynamic> mediaList) {
    return mediaList
        .map((media) {
          return Media.fromSmallJson(media, media['type'] == 'MANGA');
        })
        .toList()
        .removeDupes();
  }

  static Future<List<Episode>> fetchEpisodesFromAnify(
      String animeId, List<Episode> episodeList) async {
    Logger.i("Fetching Anify metadata for animeId: $animeId");

    try {
      final resp = await get(Uri.parse(
          "https://api.ani.zip/mappings?${serviceHandler.serviceType.value == ServicesType.anilist ? 'anilist_id' : 'mal_id'}=$animeId"));

      if (resp.statusCode != 200 || resp.body.isEmpty) {
        Logger.i("Failed to fetch Anify data, trying Kitsu...");
        return await Kitsu.fetchKitsuEpisodes(animeId, episodeList)
            .catchError((_) => episodeList);
      }

      final Map<String, dynamic> data = await compute(_parseJson, resp.body);

      if (data['episodes'].isEmpty) {
        Logger.i("No valid data found.");
        return episodeList;
      }

      final Map<String, dynamic> episodesData = data['episodes'];

      if (episodesData.isEmpty) {
        Logger.i("No episodes found for animeId: $animeId");
        return episodeList;
      }

      for (int i = 0; i < min(episodeList.length, episodesData.length); i++) {
        final episodeData = episodesData.entries.toList()[i];
        episodeList[i]
          ..title = episodeData.value?['title']['en']?.toString() ??
              episodeList[i].title
          ..thumbnail = episodeData.value?['image']?.toString() ??
              episodeList[i].thumbnail
          ..desc =
              episodeData.value?['overview']?.toString() ?? episodeList[i].desc;
      }

      return episodeList;
    } catch (e, stack) {
      Logger.i("Error fetching Anify data: $e\n$stack");

      return await Kitsu.fetchKitsuEpisodes(animeId, episodeList)
          .catchError((_) => episodeList);
    }
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final filters = params.filters;
    final data = await anilistSearch(
        isManga: params.isManga,
        query: params.query,
        sort: filters?['sort'],
        season: filters?['season'],
        status: filters?['status'],
        format: filters?['format'],
        genres: filters?['genres'],
        isAdult: params.args);
    return data;
  }

  static Future<List<Media>> anilistSearch(
      {required bool isManga,
      String? query,
      String? sort,
      String? season,
      String? status,
      String? format,
      List<String>? genres,
      required bool isAdult}) async {
    const url = 'https://graphql.anilist.co/';
    final headers = {'Content-Type': 'application/json'};

    final Map<String, dynamic> variables = {
      if (query != null && query.isNotEmpty) 'search': query,
      if (sort != null) 'sort': [sort],
      if (season != null) 'season': season.toUpperCase(),
      if (status != null && status != 'All') 'status': status.toUpperCase(),
      if (format != null) 'format': format.replaceAll(' ', '_').toUpperCase(),
      if (genres != null && genres.isNotEmpty) 'genre_in': genres,
      'isAdult': isAdult,
    };

    final String commonFields = '''
    id
    title {
      english
      romaji
      native
    }
    coverImage {
      large
    }
    type
averageScore
    ${isManga ? 'chapters' : 'episodes'}
  ''';

    dynamic body;
    if (query != null && query.isNotEmpty) {
      body = jsonEncode({
        'query': '''
  query (\$search: String, \$sort: [MediaSort], \$season: MediaSeason, \$status: MediaStatus, \$format: MediaFormat, \$genre_in: [String], \$isAdult: Boolean) {
    Page (page: 1) {
      media (
        ${query.isNotEmpty ? 'search: \$search,' : ''}
        type: ${isManga ? "MANGA" : "ANIME"},
        sort: \$sort,
        season: \$season,
        status: \$status,
        format: \$format,
        genre_in: \$genre_in,
        isAdult: \$isAdult
      ) {
        $commonFields
      }
    }
  }
  ''',
        'variables': variables,
      });
    } else {
      body = jsonEncode({
        'query': '''
  query (\$sort: [MediaSort], \$season: MediaSeason, \$status: MediaStatus, \$format: MediaFormat, \$genre_in: [String], \$isAdult: Boolean) {
    Page (page: 1) {
      media (
        type: ${isManga ? "MANGA" : "ANIME"},
        sort: \$sort,
        season: \$season,
        status: \$status,
        format: \$format,
        genre_in: \$genre_in,
        isAdult: \$isAdult
      ) {
        $commonFields
      }
    }
  }
  ''',
        'variables': variables,
      });
    }

    try {
      final response = await post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final mediaList = jsonData['data']['Page']['media'];

        final mappedData = mediaList.map<Media>((media) {
          return Media.fromSmallJson(media, isManga);
        }).toList();
        return mappedData;
      } else {
        Logger.i(
            'Failed to fetch ${isManga ? "manga" : "anime"} data. Status code: ${response.statusCode} \n response body: ${response.body}');
        return [];
      }
    } catch (e) {
      Logger.i(
          'Error occurred while fetching ${isManga ? "manga" : "anime"} data: $e');
      return [];
    }
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    Media? data = cacheController.getCacheById(params.id);

    if (data != null) return data;

    const String url = 'https://graphql.anilist.co/';
    final Map<String, dynamic> variables = {
      'id': int.parse(params.id),
    };

    final Map<String, dynamic> body = {
      'query': detailsQuery,
      'variables': variables,
    };

    try {
      final response = await post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final media = data['data']['Media'];
        cacheController.addCache(media);
        return Media.fromJson(media);
      } else if (response.statusCode == 429) {
        warningSnackBar('Chill for a min, you got rate limited.');
        throw Exception(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      Logger.i('Error occurred while fetching details: $e');
    }
    return Media(serviceType: ServicesType.simkl);
  }

  @override
  Future<void> fetchHomePage() async {
    Future.wait([
      fetchAnilistHomepage(),
      fetchAnilistMangaPage(),
    ]);
  }

  @override
  RxBool get isLoggedIn => anilistAuth.isLoggedIn;

  @override
  Rx<Profile> get profileData => anilistAuth.profileData;

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) =>
      anilistAuth.updateListEntry(
          listId: params.listId,
          malId: params.syncIds?[0],
          score: params.score,
          status: params.status,
          progress: params.progress,
          isAnime: params.isAnime);

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async =>
      anilistAuth.deleteMediaFromList(listId, isAnime: isAnime);

  @override
  RxList<TrackedMedia> get animeList => anilistAuth.animeList;

  @override
  Rx<TrackedMedia> get currentMedia => anilistAuth.currentMedia;

  @override
  void setCurrentMedia(String id, {bool isManga = false}) =>
      anilistAuth.setCurrentMedia(id, isManga: isManga);

  @override
  RxList<TrackedMedia> get mangaList => anilistAuth.mangaList;

  @override
  Future<void> login() async => anilistAuth.login();

  @override
  Future<void> logout() async => anilistAuth.logout();

  @override
  Future<void> autoLogin() => anilistAuth.tryAutoLogin();

  @override
  Future<void> refresh() async {
    Future.wait([
      anilistAuth.fetchUserAnimeList(),
      anilistAuth.fetchUserMangaList(),
    ]);
  }
}
