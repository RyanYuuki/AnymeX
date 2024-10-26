import 'dart:developer';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchAnimeInfo(int animeId) async {
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
    'id': animeId,
  };

  final Map<String, dynamic> body = {
    'query': query,
    'variables': variables,
  };

  try {
    final response = await http.post(
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

      final updatedMedia = {
        'id': media['id'] as int? ?? '?',
        'jname': media['title']?['romaji'] as String? ?? '?',
        'cover': media['bannerImage'] as String? ?? '',
        'name': media['title']?['english'] ??
            media['title']?['romaji'] ??
            media['title']?['native'] ??
            '?',
        'english': media['title']?['english'] as String? ?? '?',
        'japanese': media['title']?['native'] as String? ?? '?',
        'description': media['description'] as String? ?? '?',
        'poster': media['coverImage']?['large'] as String? ?? '?',
        'totalEpisodes': (media['episodes'] as int?)?.toString() ?? '?',
        'type': media['type'] as String? ?? '?',
        'season': media['season'] as String? ?? '?',
        'premiered':
            '${media['season'] as String? ?? '?'} ${media['seasonYear'] as int? ?? '?'}',
        'duration': '${media['duration'] as int? ?? '?'}m',
        'status': media['status'] as String? ?? '?',
        'rating': ((media['averageScore'] ?? 0) / 10)?.toString() ?? "??",
        'quality': media['format'] as String? ?? '?',
        'aired': aired.toString(),
        'studios': (media['studios']?['nodes'] as List?) ?? '?',
        'genres':
            (media['genres'] as List?) ?? ['Action', 'Adventure', 'Fantasy'],
        'characters': (media['characters']['edges'] as List?) ?? '?',
        'relations': (media['relations']['edges'] as List?) ?? '?',
        'recommendations': (media['recommendations']['edges'] as List?) ?? '?',
        'popularity': media?['popularity']?.toString() ?? '6900',
      };

      return updatedMedia;
    } else {
      throw Exception('Failed to fetch anime info');
    }
  } catch (e) {
    log('Error: $e');
    throw Exception('Error fetching anime info');
  }
}
