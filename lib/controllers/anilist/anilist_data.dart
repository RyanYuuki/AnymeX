import 'dart:convert';
import 'dart:developer';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_popular.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Anilist/anime_media_small.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart' as fbm;
import 'package:anymex/utils/fallback/fallback_anime.dart' as fb;
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

class AnilistData extends GetxController {
  // Anime Data
  RxList<AnilistMediaSmall> upcomingAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> popularAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> trendingAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> latestAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Today = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Week = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Month = <AnilistMediaSmall>[].obs;

  // Manga Data
  RxList<AnilistMediaSmall> popularMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> morePopularMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> latestMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> mostFavoriteMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topRatedMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topUpdatedMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topOngoingMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> trendingMangas = <AnilistMediaSmall>[].obs;

  // Novel Data
  Map<Source, List<MManga>?> novelData = {};

  @override
  void onInit() {
    super.onInit();
    _initFallback();
    fetchAnilistHomepage();
    fetchAnilistMangaPage();
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

  Future<void> fetchDataForAllSources() async {
    final sources = Get.find<SourceController>().installedNovelExtensions;
    await Future.wait(
      sources.map((source) async {
        try {
          List<MManga>? data = await getPopular(source: source);
          novelData[source] = data;
          update();
        } catch (error) {
          snackBar('Error fetching data for ${source.name}: $error',
              duration: 1000);
        }
      }),
    );
  }

  Future<void> fetchAnilistHomepage() async {
    const String url = 'https://graphql.anilist.co';

    const String query = '''
  query {
    upcomingAnimes: Page(page: 1, perPage: 15) {
      media(type: ANIME, status: NOT_YET_RELEASED) {
        id
        title {
          romaji
          english
          native
        }
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
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Today: Page(page: 1, perPage: 15) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Week: Page(page: 2, perPage: 15) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    top10Month: Page(page: 3, perPage: 15) {
      media(type: ANIME, sort: [POPULARITY_DESC]) {
        id
        title {
          romaji
          english
          native
        }
        episodes
        averageScore
        coverImage {
          large
        }
      }
    }
    latestAnimes: Page(page: 1, perPage: 15) {
      media(type: ANIME, sort: [START_DATE]) {
        id
        title {
          romaji
          english
          native
        }
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
      top10Today.value = parseMediaList(responseData['top10Today']['media']);
      top10Week.value = parseMediaList(responseData['top10Week']['media']);
      top10Month.value = parseMediaList(responseData['top10Month']['media']);
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
        averageScore
      }
    }

    # Latest Mangas (Page 1)
    latestMangas: Page(page: 1, perPage: \$perPage) {
      media(sort: START_DATE_DESC, type: MANGA) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
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

  List<AnilistMediaSmall> parseMediaList(List<dynamic> mediaList) {
    return mediaList.map((media) {
      return AnilistMediaSmall(
          id: media['id'].toString(),
          title: media['title']['english'] ??
              media['title']['romaji'] ??
              media['title']['native'],
          averageScore:
              (double.tryParse(media?['averageScore']?.toString() ?? "0")! /
                  10),
          chapters: media['chapters']?.toString() ?? "0",
          poster: media['coverImage']['large'],
          cover: media['bannerImage'],
          description: (media['description'] ?? "No Description Available")
              .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
          episodes: media['episodes']);
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

  static Future<List<AnilistMediaSmall>> anilistSearch({
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
      'isAdult': false, // This ensures NSFW content is excluded
    };

    // Common fields for both anime and manga
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

        final mappedData = mediaList.map<AnilistMediaSmall>((media) {
          return AnilistMediaSmall(
            id: media['id'].toString(),
            title: media['title']['english'] ?? media['title']['romaji'] ?? '',
            poster: media['coverImage']['large'] ?? '',
            episodes: isManga ? media['chapters'] ?? 0 : media['episodes'] ?? 0,
            averageScore: ((media['averageScore'] ?? 0) / 10),
          );
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

  static Future<AnilistMediaData> fetchAnimeInfo(String animeId) async {
    log("Anime ID: $animeId");
    const String url = 'https://graphql.anilist.co/';

    const String query = '''
    query (\$id: Int) {
      Media(id: \$id) {
        id
        title {
          romaji
          english
          native
        }
        description
        coverImage {
          large   
        }
        bannerImage
        averageScore
        episodes
        type
        season
        seasonYear
        duration
        status
        chapters
        format
        popularity
        startDate {
          year
          month
          day
        }
        endDate {
          year
          month
          day
        }
        genres
        studios {
          nodes {
            name
          }
        }
        characters {
          edges {
            node {
              name {
                full
              }
              favourites
              image {
                large
              }
            }
            voiceActors(language: JAPANESE) {
              name {
                full
              }
              image {
                large
              }
            }
          }
        }
        relations {
          edges {
            node {
              id
              title {
                romaji
                english
              }
              coverImage {
                large
              }
              type
              averageScore
            }
          }
        }
        recommendations {
          edges {
            node {
              mediaRecommendation {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                averageScore
              }
            }
          }
        }
        nextAiringEpisode {
          airingAt
          timeUntilAiring
        }
        rankings {
          rank
          type
          year
        }
      }
    }
  ''';

    final Map<String, dynamic> variables = {
      'id': int.parse(animeId),
    };

    final Map<String, dynamic> body = {
      'query': query,
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

        final startDate = media['startDate'];
        final endDate = media['endDate'];
        String aired = '';
        if (startDate != null) {
          aired =
              '${startDate['year']}-${startDate['month']?.toString().padLeft(2, '0')}-${startDate['day']?.toString().padLeft(2, '0')}';
          if (endDate != null && endDate['year'] != null) {
            aired +=
                ' to ${endDate['year']}-${endDate['month']?.toString().padLeft(2, '0')}-${endDate['day']?.toString().padLeft(2, '0')}';
          }
        }

        return AnilistMediaData.fromJson(media);
      } else {
        throw Exception('Failed to fetch anime info, Network Error');
      }
    } catch (e) {
      log('Error: $e');
      throw Exception('Error fetching anime info');
    }
  }
}
