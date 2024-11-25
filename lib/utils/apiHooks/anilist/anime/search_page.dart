import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchAnimeBySearch({
  String? query, // Made optional
  String? sort, // e.g., 'SCORE_DESC'
  String? season, // e.g., 'WINTER'
  String? status, // e.g., 'FINISHED'
  String? format, // e.g., 'TV'
  List<String>? genres, // e.g., ['Action', 'Adventure']
}) async {
  const url = 'https://graphql.anilist.co/';
  final headers = {'Content-Type': 'application/json'};

  final Map<String, dynamic> variables = {
    if (query != null && query.isNotEmpty)
      'search': query, // Include only if query is not empty
    if (sort != null) 'sort': [sort],
    if (season != null) 'season': season.toUpperCase(),
    if (status != null) 'status': status.toUpperCase(),
    if (format != null) 'format': format.replaceAll(' ', '_').toUpperCase(),
    if (genres != null && genres.isNotEmpty) 'genre_in': genres,
  };
  dynamic body;
  if (query != null && query.isNotEmpty) {
    body = jsonEncode({
      'query': '''
    query (\$search: String, \$sort: [MediaSort], \$season: MediaSeason, \$status: MediaStatus, \$format: MediaFormat, \$genre_in: [String]) {
      Page (page: 1) {
        media (
          ${query != null && query.isNotEmpty ? 'search: \$search,' : ''}
          type: ANIME,
          sort: \$sort,
          season: \$season,
          status: \$status,
          format: \$format,
          genre_in: \$genre_in
        ) {
          id
          title {
            english
            romaji
            native
          }
          episodes
          coverImage {
            large
          }
          type
          averageScore
        }
      }
    }
    ''',
      'variables': variables,
    });
  } else {
    body = jsonEncode({
      'query': '''
    query (\$sort: [MediaSort], \$season: MediaSeason, \$status: MediaStatus, \$format: MediaFormat, \$genre_in: [String]) {
      Page (page: 1) {
        media (
          type: ANIME,
          sort: \$sort,
          season: \$season,
          status: \$status,
          format: \$format,
          genre_in: \$genre_in
        ) {
          id
          title {
            english
            romaji
            native
          }
          episodes
          coverImage {
            large
          }
          type
          averageScore
        }
      }
    }
    ''',
      'variables': variables,
    });
  }

  try {
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final mediaList = jsonData['data']['Page']['media'];

      final mappedData = mediaList.map<Map<String, dynamic>>((anime) {
        return {
          'id': anime['id'],
          'name': anime['title']['english'] ?? anime['title']['romaji'] ?? '',
          'jname': anime['title']['romaji'],
          'poster': anime['coverImage']['large'] ?? '',
          'episodes': anime['episodes'] ?? 0,
          'type': anime['type'] ?? '',
          'rating':
              ((anime['averageScore'] ?? 0) / 10).toStringAsFixed(1) ?? '0.0',
        };
      }).toList();
      return mappedData;
    } else {
      log('Failed to fetch anime data. Status code: ${response.statusCode} \n response body : ${response.body}');
      return [];
    }
  } catch (e) {
    log('Error occurred while fetching anime data: $e');
    return [];
  }
}
