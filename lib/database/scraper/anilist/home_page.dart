import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchAnilistHomepage() async {
  const String url = 'https://graphql.anilist.co';

  const String query = '''
  query {
    upcomingAnime: Page(page: 1, perPage: 10) {
      media(type: ANIME, status: NOT_YET_RELEASED) {
        id
        title {
          romaji
          english
          native
        }
        startDate {
          year
          month
          day
        }
        coverImage {
          large
        }
      }
    }
    trendingAnime: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: TRENDING_DESC) {
        id
        title {
          romaji
          english
          native
        }
        bannerImage
        averageScore
        popularity
        coverImage {
          large
        }
      }
    }
    top10Today: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY]) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
      }
    }
    top10Week: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY]) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
      }
    }
    top10Month: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [POPULARITY]) {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          large
        }
      }
    }
    latestAnime: Page(page: 1, perPage: 10) {
      media(type: ANIME, sort: [START_DATE]) {
        id
        title {
          romaji
          english
          native
        }
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

  final response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: json.encode({
      'query': query,
    }),
  );

  if (response.statusCode == 200) {
    final dynamic responseData = json.decode(response.body);

    return responseData['data'];
  } else {
    throw Exception('Failed to load AniList data: ${response.statusCode}');
  }
}
