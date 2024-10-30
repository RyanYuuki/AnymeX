import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchMangaBySearch(String query) async {
  const url = 'https://graphql.anilist.co/';
  final headers = {'Content-Type': 'application/json'};

  final body = jsonEncode({
    'query': '''
    query (\$search: String) {
      Page (page: 1) {
        media (search: \$search, type: MANGA) {
          id
          title {
            english
            romaji
            native
          }
          chapters
          coverImage {
            large
          }
          type
          averageScore
        }
      }
    }
    ''',
    'variables': {'search': query}
  });

  try {
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final mediaList = jsonData['data']['Page']['media'];

      final mappedData = mediaList.map<Map<String, dynamic>>((anime) {
        return {
          'id': anime['id'],
          'title': anime['title']['english'] ?? anime['title']['romaji'] ?? '',
          'jname': anime['title']['romaji'],
          'image': anime['coverImage']['large'] ?? '',
          'episodes': anime['episodes'] ?? 0,
          'type': anime['type'] ?? '',
          'ratings': ((anime['averageScore'] ?? 0) / 10)?.toString() ?? '0.0',
        };
      }).toList();

      return mappedData;
    } else {
      log('Failed to fetch anime data. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    log('Error occurred while fetching anime data: $e');
    return [];
  }
}
