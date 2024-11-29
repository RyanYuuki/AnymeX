import 'dart:convert';
import 'dart:developer';
import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class HiddenLeaf implements SourceBase {
  @override
  String get sourceName => 'HiddenLeaf';

  @override
  bool get isMulti => false;

  Dio dio = Dio();

  String formatTitle(String title) {
    String cleanedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    String formattedTitle =
        cleanedTitle.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return formattedTitle;
  }

  @override
  Future<dynamic> scrapeSearchResults(String query) async {
    const url = 'https://graphql.anilist.co/';
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'query': '''
    query (\$search: String) {
      Page (page: 1) {
        media (search: \$search, type: ANIME) {
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
          var title = anime['title']['english'] ??
              anime['title']['romaji'] ??
              anime['title']['native'] ??
              '??';
          return {
            'id': '${formatTitle(title)}-${anime['id']}',
            'name': title,
            'poster': anime['coverImage']['large'] ?? '',
            'episodes': {'sub': anime['episodes'] ?? 0, 'dub': '??'},
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

  @override
  Future<Map<String, dynamic>> scrapeEpisodesSrcs(String episodeId,
      {AnimeServers? server, String? category, String? lang}) async {
    var episodeKey = episodeId.split('/').last;
    var episodeUrl = episodeId.split('/$episodeKey').first;
    var resp = await dio.get(episodeUrl);

    if (resp.statusCode == 200) {
      var data = resp.data;

      Map<String, dynamic> sources = {"sources": [], "tracks": []};

      if (data.containsKey(episodeKey)) {
        var episodeData = data[episodeKey];

        var sourceUrls = episodeData['source']
                [category == 'dub' ? "DUBBED" : "SUBBED"]
            .values
            .toList();

        sources['sources']!.add({
          "url": sourceUrls[lang == 'HD-1' ? 0 : 1],
        });

        if (episodeData.containsKey('captions')) {
          episodeData['captions'].forEach((track) {
            sources['tracks'].add({
              'file': track['url'],
              'label': track['lang'],
              'kind': track['lang'] != 'Thumbnails' ? 'captions' : 'Thumbnails'
            });
          });
        }
      }

      return sources;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  Future scrapeEpisodes(String episodeId, {args}) async {
    log('EpisodeID :$episodeId');
    var url = 'https://data.hiddenleaf.to/assets/$episodeId.json';
    var resp = await dio.get(url);

    if (resp.statusCode == 200) {
      final data = resp.data;
      var episodes = [];
      data.forEach((key, value) {
        episodes.add({
          'episodeId': '$url/$key',
          'title': value['title'],
          'number': int.parse(key),
          'isFiller': value['isFiller'],
          'download': value['downloadLink']
        });
      });
      final tempArr = episodeId.split('-');
      tempArr.removeLast();

      final episodesData = {
        'title': tempArr.join(' '),
        'episodes': episodes,
        'totalEpisodes': episodes.length
      };
      log(episodesData.toString());
      return episodesData;
    }
  }
}
