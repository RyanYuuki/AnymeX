import 'dart:convert';
import 'dart:math' show min;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:anymex/controllers/services/anilist/kitsu.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart' as fb;
import 'package:anymex/utils/fallback/fallback_manga.dart' as fbm;
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/staff.dart';

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
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final buttonHeight = !isDesktop ? 70.0 : 90.0;

            final double itemWidth = isDesktop ? 300.0 : constraints.maxWidth;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth * 2 + 15,
                    child: Row(
                      children: [
                        Expanded(
                          child: ImageButton(
                            height: buttonHeight,
                            buttonText: "ANIME LIST",
                            backgroundImage: trendingAnimes
                                .firstWhere((e) => e.cover != null)
                                .cover!,
                            borderRadius: 16.multiplyRadius(),
                            onPressed: () => navigate(() => const AnimeList()),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ImageButton(
                            height: buttonHeight,
                            buttonText: "MANGA LIST",
                            backgroundImage: trendingMangas
                                .firstWhere((e) => e.cover != null)
                                .cover!,
                            borderRadius: 16.multiplyRadius(),
                            onPressed: () =>
                                navigate(() => const AnilistMangaList()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > (itemWidth * 3)
                        ? itemWidth
                        : itemWidth * 2 + 15,
                    child: ImageButton(
                      height: buttonHeight,
                      buttonText: "OTHER",
                      borderRadius: 16.multiplyRadius(),
                      backgroundImage: [
                        ...popularAnimes,
                        ...popularMangas,
                        ...trendingMangas,
                        ...trendingAnimes
                      ].where((e) => e.cover != null).last.cover!,
                      onPressed: () =>
                          navigate(() => const OtherFeaturesPage()),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Obx(() {
          anilistAuth.isLoggedIn.value;
          if (acceptedLists.isEmpty) return const SizedBox.shrink();
          return Column(
            children: acceptedLists.map((e) {
              return ReusableCarousel(
                data: filterListByLabel(
                    e.contains("Manga") || e.contains("Reading")
                        ? anilistAuth.mangaList.removeDupes()
                        : anilistAuth.animeList.removeDupes(),
                    e),
                title: e,
                variant: DataVariant.anilist,
                type: e.contains("Manga") || e.contains("Reading")
                    ? ItemType.manga
                    : ItemType.anime,
              );
            }).toList(),
          );
        }),
      ],
      Column(
        children: [
          if (acceptedLists.contains("Recommended Animes") &&
              settings.homePageCards.keys.contains('Recommended Animes'))
            ReusableCarousel(
              title: "Recommended Anime",
              data: isLoggedIn.value
                  ? recAnimes.where((e) => !ids[0].contains(e.id)).toList()
                  : recAnimes,
              type: ItemType.anime,
            ),
          if (acceptedLists.contains("Recommended Mangas") &&
              settings.homePageCards.keys.contains('Recommended Mangas'))
            ReusableCarousel(
              title: "Recommended Manga",
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
      buildSection('Trending Anime', trendingAnimes),
      buildSection('Popular Anime', popularAnimes),
      buildSection('Recently Completed', latestAnimes),
      buildSection('Upcoming Anime', upcomingAnimes),
    ].obs;
  }

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    return [
      buildBigCarousel(trendingMangas, true),
      buildMangaSection('Trending Manga', trendingMangas),
      buildMangaSection('Latest Manga', latestMangas),
      buildMangaSection('Popular Manga', popularMangas),
      buildMangaSection('More Popular Manga', morePopularMangas),

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
      upcomingAnimes.value = fb.upcomingAnimes.removeDupes();
      popularAnimes.value = fb.popularAnimes.removeDupes();
      trendingAnimes.value = fb.trendingAnimes.removeDupes();
      latestAnimes.value = fb.latestAnimes.removeDupes();

      popularMangas.value = fbm.popularMangas.removeDupes();
      latestMangas.value = fbm.latestMangas.removeDupes();
      topOngoingMangas.value = fbm.trendingMangas.removeDupes();
      trendingMangas.value = fbm.trendingMangas.removeDupes();
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
        episodes
        averageScore
        coverImage {
          large
          extraLarge
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
          extraLarge
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
        filters: filters,
        isAdult: params.args);
    return data;
  }

  static Future<List<Media>> anilistSearch(
      {required bool isManga,
      String? query,
      Map<String, dynamic>? filters,
      required bool isAdult}) async {
    const url = 'https://graphql.anilist.co/';
    final token = AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> variables = {
      if (query != null && query.isNotEmpty) 'search': query,
      'isAdult': isAdult,
    };

    if (filters != null) {
      if (filters['isAdult'] == true) {
        variables['isAdult'] = true;
      }
    }

    final Map<String, String> typeMap = {
      'search': 'String',
      'sort': '[MediaSort]',
      'season': 'MediaSeason',
      'status': 'MediaStatus',
      'format_in': '[MediaFormat]',
      'genre_in': '[String]',
      'genre_not_in': '[String]',
      'tag_in': '[String]',
      'tag_not_in': '[String]',
      'source_in': '[MediaSource]',
      'countryOfOrigin': 'CountryCode',
      'licensedById_in': '[Int]',
      'isLicensed': 'Boolean',
      'onList': 'Boolean',
      'seasonYear': 'Int',
      'year': 'String',
      'startDate_like': 'String',
      'startDate_greater': 'FuzzyDateInt',
      'startDate_lesser': 'FuzzyDateInt',
      'episodes_greater': 'Int',
      'episodes_lesser': 'Int',
      'duration_greater': 'Int',
      'duration_lesser': 'Int',
      'chapters_greater': 'Int',
      'chapters_lesser': 'Int',
      'volumes_greater': 'Int',
      'volumes_lesser': 'Int',
      'isAdult': 'Boolean',
    };

    if (filters != null) {
      filters.forEach((key, value) {
        if (value == null) return;

        String apiKey = key;
        const keyMapping = {
          'format': 'format_in',
          'genres': 'genre_in',
          'tags': 'tag_in',
          'licensedBy': 'licensedById_in',
          'source': 'source_in',
          'year': 'startDate_like',
          'yearGreater': 'startDate_greater',
          'yearLesser': 'startDate_lesser',
          'episodeGreater': 'episodes_greater',
          'episodeLesser': 'episodes_lesser',
          'durationGreater': 'duration_greater',
          'durationLesser': 'duration_lesser',
          'chapterGreater': 'chapters_greater',
          'chapterLesser': 'chapters_lesser',
          'volumeGreater': 'volumes_greater',
          'volumeLesser': 'volumes_lesser',
        };
        apiKey = keyMapping[key] ?? key;

        if (apiKey == 'format_in' && value is List) {
          variables[apiKey] = value
              .map((e) => e.toString().replaceAll(' ', '_').toUpperCase())
              .toList();
        } else if (apiKey == 'format_in' && value is String) {
          variables[apiKey] = [
            value.toString().replaceAll(' ', '_').toUpperCase()
          ];
        } else if (apiKey == 'source_in') {
          if (value is List) {
            variables[apiKey] =
                value.map((e) => e.toString().toUpperCase()).toList();
          } else {
            variables[apiKey] = [value.toString().toUpperCase()];
          }
        } else if (apiKey == 'status' && value.toString() != 'All') {
          variables[apiKey] = value.toString().toUpperCase();
        } else if (apiKey == 'season') {
          variables[apiKey] = value.toString().toUpperCase();
        } else if (apiKey == 'genre_not_in' || apiKey == 'tag_not_in') {
          variables[apiKey] = value;
        } else {
          variables[apiKey] = value;
        }
      });
    }

    final validVariables =
        variables.keys.where((k) => typeMap.containsKey(k)).toList();

    final String queryArgsDef =
        validVariables.map((k) => '\$$k: ${typeMap[k]}').join(', ');
    final String queryArgsPass =
        validVariables.map((k) => '$k: \$$k').join(',\n        ');

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

    final String queryStr = '''
  query (\$page: Int${queryArgsDef.isNotEmpty ? ', $queryArgsDef' : ''}) {
    Page (page: \$page) {
      media (
        type: ${isManga ? "MANGA" : "ANIME"},
        $queryArgsPass
      ) {
        $commonFields
      }
    }
  }
  ''';

    variables.removeWhere((k, v) => !typeMap.containsKey(k));

    final Map<String, dynamic> body = {
      'query': queryStr,
      'variables': {'page': 1, ...variables},
    };

    try {
      final response =
          await post(Uri.parse(url), headers: headers, body: jsonEncode(body));

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

    final token = AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final media = data['data']['Media'];
        final page = data['data']['Page'];
        cacheController.addCache(media);
        return Media.fromJson(media, pageJson: page);
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
    await Future.wait([
      fetchAnilistHomepage(),
      fetchAnilistMangaPage(),
    ]);
  }

  static Map<String, dynamic>? _cachedAnimeFilterData;
  static Map<String, dynamic>? _cachedMangaFilterData;

  static Future<Map<String, dynamic>> fetchFilterData({
    bool isManga = false,
  }) async {
    final cached = isManga ? _cachedMangaFilterData : _cachedAnimeFilterData;
    if (cached != null) return cached;

    const url = 'https://graphql.anilist.co/';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    List<String> genres = [];
    List<String> tags = [];
    List<Map<String, dynamic>> streamingServices = [];
    List<String> formats = [];
    List<String> statuses = [];
    List<String> sources = [];
    List<String> seasons = [];
    List<String> sortOptions = [];
    List<String> countries = [];
    int minYear = 1940;
    double maxEpisodes = 150;
    double maxDuration = 170;
    double maxChapters = 500;
    double maxVolumes = 50;

    final field1 = isManga ? 'chapters' : 'episodes';
    final field2 = isManga ? 'volumes' : 'duration';

    final batchQuery = '''
    query(\$mediaType: MediaType, \$sort1: [MediaSort], \$sort2: [MediaSort]) {
      GenreCollection
      MediaTagCollection { name isAdult }
      ExternalLinkSourceCollection { id site type language icon }
      formats: __type(name: "MediaFormat") { enumValues { name } }
      statuses: __type(name: "MediaStatus") { enumValues { name } }
      sources: __type(name: "MediaSource") { enumValues { name } }
      seasons: __type(name: "MediaSeason") { enumValues { name } }
      sorts: __type(name: "MediaSort") { enumValues { name } }
      maxField1: Page(perPage: 1) {
        media(sort: \$sort1, type: \$mediaType) { $field1 }
      }
      maxField2: Page(perPage: 1) {
        media(sort: \$sort2, type: \$mediaType) { $field2 }
      }
      oldestMedia: Page(perPage: 1) {
        media(sort: START_DATE, type: \$mediaType) {
          startDate { year }
        }
      }
      countryList: Page(perPage: 100) {
        media(sort: POPULARITY_DESC, type: \$mediaType) { countryOfOrigin }
      }
    }
    ''';

    final variables = {
      'mediaType': isManga ? 'MANGA' : 'ANIME',
      'sort1': [isManga ? 'CHAPTERS_DESC' : 'EPISODES_DESC'],
      'sort2': [isManga ? 'VOLUMES_DESC' : 'DURATION_DESC'],
    };

    try {
      var response = await post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'query': batchQuery, 'variables': variables}),
      );

      
      if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        response = await post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'query': batchQuery, 'variables': variables}),
        );
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

       
        final errors = body['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          Logger.i(
              'GraphQL errors in filter data: ${errors.map((e) => e['message']).join(', ')}');
        }

        final data = body['data'] as Map<String, dynamic>?;
        if (data == null) {
          Logger.i('No data in filter response');
        } else {
          final genreList = data['GenreCollection'] as List?;
          if (genreList != null) {
            genres = genreList.cast<String>()..sort();
          }

          final tagList = data['MediaTagCollection'] as List?;
          if (tagList != null) {
            tags = tagList
                .where((t) => t['isAdult'] != true)
                .map<String>((t) => t['name'] as String)
                .toList()
              ..sort();
          }

          final linkSources = data['ExternalLinkSourceCollection'] as List?;
          if (linkSources != null) {
            streamingServices = linkSources
                .where((s) => s['type'] == 'STREAMING')
                .map<Map<String, dynamic>>((s) => {
                      'id': s['id'] as int,
                      'site': s['site'] as String,
                      'language': s['language'] as String?,
                      'icon': s['icon'] as String?,
                    })
                .toList();
          }

          formats = _extractEnumValues(data['formats']);
          statuses = _extractEnumValues(data['statuses']);
          sources = _extractEnumValues(data['sources']);
          seasons = _extractEnumValues(data['seasons']);
          sortOptions = _extractEnumValues(data['sorts']);

          final f1Media = (data['maxField1']?['media'] as List?) ?? [];
          if (f1Media.isNotEmpty && f1Media[0][field1] != null) {
            final v = (f1Media[0][field1] as int).toDouble();
            if (isManga) {
              maxChapters = v;
            } else {
              maxEpisodes = v;
            }
          }

          final f2Media = (data['maxField2']?['media'] as List?) ?? [];
          if (f2Media.isNotEmpty && f2Media[0][field2] != null) {
            final v = (f2Media[0][field2] as int).toDouble();
            if (isManga) {
              maxVolumes = v;
            } else {
              maxDuration = v;
            }
          }

          final oldest = (data['oldestMedia']?['media'] as List?) ?? [];
          if (oldest.isNotEmpty) {
            final year = oldest[0]?['startDate']?['year'] as int?;
            if (year != null) minYear = year;
          }

          final countryMedia = (data['countryList']?['media'] as List?) ?? [];
          final apiCountries = countryMedia
              .map((m) => m['countryOfOrigin'] as String?)
              .whereType<String>()
              .toSet();
         
          const coreCountries = ['JP', 'KR', 'CN', 'TW'];
          final extras = apiCountries
              .where((c) => !coreCountries.contains(c))
              .toList()
            ..sort();
          countries = [...coreCountries, ...extras];
        }
      }
    } catch (e) {
      Logger.i('Error fetching filter data: $e');
    }

    final result = {
      'genres': genres,
      'tags': tags,
      'streamingServices': streamingServices,
      'formats': formats,
      'statuses': statuses,
      'sources': sources,
      'seasons': seasons,
      'sortOptions': sortOptions,
      'countries': countries,
      'minYear': minYear,
      'maxEpisodes': maxEpisodes,
      'maxDuration': maxDuration,
      'maxChapters': maxChapters,
      'maxVolumes': maxVolumes,
    };

    if (isManga) {
      _cachedMangaFilterData = result;
    } else {
      _cachedAnimeFilterData = result;
    }
    return result;
  }

  static List<String> _extractEnumValues(Map<String, dynamic>? typeData) {
    final values = typeData?['enumValues'] as List?;
    if (values == null) return [];
    return values.map<String>((v) => v['name'] as String).toList();
  }

  static Map<String, dynamic>? _cachedMalAnimeFilterData;
  static Map<String, dynamic>? _cachedMalMangaFilterData;

  static Future<Map<String, dynamic>> fetchMalFilterData({
    bool isManga = false,
  }) async {
    final cached =
        isManga ? _cachedMalMangaFilterData : _cachedMalAnimeFilterData;
    if (cached != null) return cached;

    List<String> genres = [];

    try {
      final type = isManga ? 'manga' : 'anime';
      final response = await get(
        Uri.parse('https://api.jikan.moe/v4/genres/$type?filter=genres'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List?;
        if (list != null) {
          genres = list.map<String>((g) => g['name'] as String).toList()
            ..sort();
        }
      }
    } catch (e) {
      Logger.i('Error fetching MAL filter data: $e');
    }

    final result = {'genres': genres};

    if (isManga) {
      _cachedMalMangaFilterData = result;
    } else {
      _cachedMalAnimeFilterData = result;
    }
    return result;
  }

  Future<dynamic> getCharacterDetails(String id) async {
    const String url = 'https://graphql.anilist.co';
    final Map<String, dynamic> variables = {'id': int.tryParse(id)};

    final token = AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'query': characterDetailsQuery,
          'variables': variables,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Character.fromDetailJson(data['data']['Character']);
      }
    } catch (e) {
      Logger.i('Error fetching character details: $e');
    }
    return null;
  }

  Future<Staff?> getStaffDetails(String id) async {
    const String url = 'https://graphql.anilist.co';
    int charPage = 1;
    int staffPage = 1;
    bool charHasNext = true;
    bool staffHasNext = true;
    List<dynamic> allCharacterEdges = [];
    List<dynamic> allStaffEdges = [];
    final token = AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      Map<String, dynamic>? initialData;
      int loopCount = 0;
      while (staffHasNext && loopCount < 20) {
        Logger.i("Loop $loopCount: charPage=$charPage, staffPage=$staffPage");
        final variables = {
          'id': int.tryParse(id),
          'characterPage': charPage,
          'staffPage': staffPage,
        };

        final response = await post(
          Uri.parse(url),
          headers: headers,
          body: json.encode({
            'query': staffDetailsQuery,
            'variables': variables,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final staffData = data['data']['Staff'];

          if (loopCount == 0) {
            initialData = staffData;
          }

          // Character
          if (charHasNext) {
            final charData = staffData['characters'];
            if (charData != null) {
              final edges = charData['edges'] as List?;
              if (edges != null) {
                Logger.i("Fetched ${edges.length} character edges");
                allCharacterEdges.addAll(edges);
              }

              final pageInfo = charData['pageInfo'];
              charHasNext = pageInfo?['hasNextPage'] ?? false;
              if (charHasNext) charPage++;
            } else {
              charHasNext = false;
            }
          }

          // Staff
          if (staffHasNext) {
            final stfMedia = staffData['staffMedia'];
            if (stfMedia != null) {
              final edges = stfMedia['edges'] as List?;
              if (edges != null) allStaffEdges.addAll(edges);

              final pageInfo = stfMedia['pageInfo'];
              staffHasNext = pageInfo?['hasNextPage'] ?? false;
              if (staffHasNext) staffPage++;
            } else {
              staffHasNext = false;
            }
          }
        } else {
          Logger.i(
              'Error fetching staff details page $loopCount: ${response.statusCode}');
          break;
        }
        loopCount++;
      }

      if (initialData != null) {
        final finalData = Map<String, dynamic>.from(initialData);

        if (finalData['characters'] == null) finalData['characters'] = {};
        finalData['characters']['edges'] = allCharacterEdges;

        if (finalData['staffMedia'] == null) finalData['staffMedia'] = {};
        finalData['staffMedia']['edges'] = allStaffEdges;

        return Staff.fromDetailJson(finalData);
      }
    } catch (e) {
      Logger.i('Error fetching staff details: $e');
    }
    return null;
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
  Future<void> login(BuildContext context) async => anilistAuth.login(context);

  @override
  Future<void> logout() async => anilistAuth.logout();

  @override
  Future<void> autoLogin() => anilistAuth.tryAutoLogin();

  @override
  Future<void> refresh() async {
    await anilistAuth.fetchUserAnimeList();
    await anilistAuth.fetchUserMangaList();
  }
}
