import 'dart:convert';
import 'dart:developer';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Anilist/anime_media_small.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';

class AnilistData extends GetxController {
  RxList<AnilistMediaSmall> upcomingAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> popularAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> trendingAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> latestAnimes = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Today = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Week = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> top10Month = <AnilistMediaSmall>[].obs;

  RxList<AnilistMediaSmall> popularMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> morePopularMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> latestMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> mostFavoriteMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topRatedMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topUpdatedMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> topOngoingMangas = <AnilistMediaSmall>[].obs;
  RxList<AnilistMediaSmall> trendingMangas = <AnilistMediaSmall>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnilistHomepage();
    fetchAnilistMangaPage();
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
          description: media['description'],
          episodes: media['episodes']);
    }).toList();
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
