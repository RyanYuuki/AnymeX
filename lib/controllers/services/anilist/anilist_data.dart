import 'dart:convert';
import 'dart:developer';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Model/Source.dart';
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
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart' as fbm;
import 'package:anymex/utils/fallback/fallback_anime.dart' as fb;
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

class AnilistData extends GetxController implements BaseService, OnlineService {
  final anilistAuth = Get.find<AnilistAuth>();

  // Anime Data
  RxList<Media> upcomingAnimes = <Media>[].obs;
  RxList<Media> popularAnimes = <Media>[].obs;
  RxList<Media> trendingAnimes = <Media>[].obs;
  RxList<Media> latestAnimes = <Media>[].obs;
  RxList<Media> top10Today = <Media>[].obs;
  RxList<Media> top10Week = <Media>[].obs;
  RxList<Media> top10Month = <Media>[].obs;

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
  Map<Source, List<MManga>?> novelData = {};

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    final settings = Get.find<Settings>();
    final acceptedLists = settings.homePageCards.entries
        .where((entry) => entry.value)
        .map<String>((entry) => entry.key)
        .toList();
    final isDesktop = Get.width > 600;
    return [
      if (anilistAuth.isLoggedIn.value) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageButton(
              width: isDesktop ? 300 : Get.width / 2 - 40,
              height: !isDesktop ? 70 : 90,
              buttonText: "ANIME LIST",
              backgroundImage:
                  trendingAnimes.firstWhere((e) => e.cover != null).cover ?? '',
              borderRadius: 16.multiplyRadius(),
              onPressed: () {
                Get.to(() => const AnimeList());
              },
            ),
            const SizedBox(width: 15),
            ImageButton(
              width: isDesktop ? 300 : Get.width / 2 - 40,
              height: !isDesktop ? 70 : 90,
              buttonText: "MANGA LIST",
              borderRadius: 16.multiplyRadius(),
              backgroundImage:
                  trendingMangas.firstWhere((e) => e.cover != null).cover ?? '',
              onPressed: () {
                Get.to(() => const AnilistMangaList());
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
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
                  isManga: e.contains("Manga") || e.contains("Reading"),
                );
              }).toList(),
            )),
      ],
      Column(
        children: [
          ReusableCarousel(
            title: "Recommended Animes",
            data: popularAnimes + trendingAnimes,
          ),
          ReusableCarousel(
            title: "Recommended Mangas",
            data: popularMangas + trendingMangas,
            isManga: true,
          )
        ],
      )
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) {
    return [
      // TappableSearchBar(
      //   onSubmitted: () {
      //     Get.to(() => const SearchPage(
      //           searchTerm: "",
      //           isManga: false,
      //         ));
      //   },
      //   chipLabel: "ANIME",
      //   hintText: "Search Anime...",
      // ),
      buildBigCarousel(trendingAnimes, false),
      buildSection('Trending Animes', trendingAnimes),
      buildSection('Popular Animes', popularAnimes),
      buildSection('Recently Completed', latestAnimes),
      buildSection('Upcoming Animes', upcomingAnimes),
    ].obs;
  }

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    return [
      // CustomSearchBar(
      //   onSubmitted: (val) {
      //     Get.to(() => SearchPage(
      //           searchTerm: val,
      //           isManga: true,
      //         ));
      //   },
      //   suffixIconWidget: buildChip("MANGA"),
      //   disableIcons: true,
      //   hintText: "Search Manga...",
      // ),
      buildBigCarousel(trendingMangas, true),
      buildMangaSection('Trending Mangas', trendingMangas),
      buildMangaSection('Latest Mangas', latestMangas),
      buildMangaSection('Popular Mangas', popularMangas),
      buildMangaSection('More Popular Mangas', morePopularMangas),
      buildMangaSection('Most Favorite Mangas', mostFavoriteMangas),
      buildMangaSection('Top Rated Mangas', topRatedMangas),
      buildMangaSection('Top Updated Mangas', topUpdatedMangas),
      buildMangaSection('Top Ongoing Mangas', topOngoingMangas),
    ].obs;
  }

  @override
  void onInit() {
    super.onInit();
    _initFallback();
    fetchHomePage();
  }

  void _initFallback() {
    upcomingAnimes.value = fb.upcomingAnimes;
    popularAnimes.value = fb.popularAnimes;
    trendingAnimes.value = fb.trendingAnimes;
    latestAnimes.value = fb.latestAnimes;
    top10Today.value = fb.top10Today;
    top10Week.value = fb.top10Week;
    top10Month.value = fb.top10Month;

    popularMangas.value = fbm.popularMangas;
    // morePopularMangas.value = fbm.top10Week;
    latestMangas.value = fbm.latestMangas;
    // mostFavoriteMangas.value = fbm.top10Today;
    // topRatedMangas.value = fbm.top10Week;
    // topUpdatedMangas.value = fbm.upcomingMangas;
    topOngoingMangas.value = fbm.trendingMangas;
    trendingMangas.value = fbm.trendingMangas;
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
    return mediaList.map((media) {
      return Media.fromSmallJson(media, media['type'] == 'MANGA');
    }).toList();
  }

  static Future<List<Episode>> fetchEpisodesFromAnify(
      String animeId, List<Episode> episodeList) async {
    final resp = await get(
        Uri.parse("https://anify.eltik.cc/content-metadata/$animeId"));

    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body);
        final episodesData = data[0]['data'];

        if (episodesData == null || episodesData.isEmpty) {
          return episodeList;
        }

        for (int i = 0; i < episodeList.length; i++) {
          if (i < episodesData.length) {
            final episodeData = episodesData[i];
            episodeList[i].title = episodeData['title'] ?? episodeList[i].title;
            episodeList[i].thumbnail =
                episodeData['img'] ?? episodeList[i].thumbnail;
            episodeList[i].desc =
                episodeData['description'] ?? episodeList[i].desc;
          }
        }

        return episodeList;
      } catch (e) {
        return episodeList;
      }
    } else {
      return episodeList;
    }
  }

  @override
  Future<List<Media>> search(String query,
      {bool isManga = false, Map<String, dynamic>? filters}) async {
    final data = await anilistSearch(
        isManga: isManga,
        query: query,
        sort: filters?['sort'],
        season: filters?['season'],
        status: filters?['status'],
        format: filters?['format'],
        genres: filters?['genres']);
    return data;
  }

  static Future<List<Media>> anilistSearch({
    required bool isManga,
    String? query,
    String? sort,
    String? season,
    String? status,
    String? format,
    List<String>? genres,
  }) async {
    const url = 'https://graphql.anilist.co/';
    final headers = {'Content-Type': 'application/json'};

    final Map<String, dynamic> variables = {
      if (query != null && query.isNotEmpty) 'search': query,
      if (sort != null) 'sort': [sort],
      if (season != null) 'season': season.toUpperCase(),
      if (status != null) 'status': status.toUpperCase(),
      if (format != null) 'format': format.replaceAll(' ', '_').toUpperCase(),
      if (genres != null && genres.isNotEmpty) 'genre_in': genres,
      'isAdult': false,
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
        log('Failed to fetch ${isManga ? "manga" : "anime"} data. Status code: ${response.statusCode} \n response body: ${response.body}');
        return [];
      }
    } catch (e) {
      log('Error occurred while fetching ${isManga ? "manga" : "anime"} data: $e');
      return [];
    }
  }

  @override
  Future<Media> fetchDetails(dynamic animeId) async {
    const String url = 'https://graphql.anilist.co/';
    final Map<String, dynamic> variables = {
      'id': int.parse(animeId),
    };

    final Map<String, dynamic> body = {
      'query': detailsQuery,
      'variables': variables,
    };

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

      // final startDate = media['startDate'];
      // final endDate = media['endDate'];
      // String aired = '';

      // if (startDate != null) {
      //   aired =
      //       '${startDate['year']}-${startDate['month']?.toString().padLeft(2, '0')}-${startDate['day']?.toString().padLeft(2, '0')}';
      //   if (endDate != null && endDate['year'] != null) {
      //     aired +=
      //         ' to ${endDate['year']}-${endDate['month']?.toString().padLeft(2, '0')}-${endDate['day']?.toString().padLeft(2, '0')}';
      //   }
      // }
      return Media.fromJson(media);
    } else {
      throw Exception('Failed to fetch anime info, Network Error');
    }
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
  Future<void> updateListEntry(
          {required String listId,
          double? score,
          String? status,
          int? progress,
          bool isAnime = true}) =>
      anilistAuth.updateListEntry(
          listId: listId,
          score: score,
          status: status,
          progress: progress,
          isAnime: isAnime);

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async =>
      anilistAuth.deleteMediaFromList(listId, isAnime: isAnime);

  @override
  RxList<TrackedMedia> get animeList => anilistAuth.animeList;

  @override
  Rx<TrackedMedia> get currentMedia => anilistAuth.currentMedia;

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    anilistAuth.setCurrentMedia(id, isManga: isManga);
  }

  @override
  RxList<TrackedMedia> get mangaList => anilistAuth.mangaList;

  @override
  Future<void> login() async {
    anilistAuth.login();
  }

  @override
  Future<void> logout() async {
    anilistAuth.logout();
  }

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
