import 'dart:developer';

import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:dio/dio.dart';

class YugenAnime implements SourceBase {
  Dio dio = Dio();
  @override
  bool get isMulti => false;

  @override
  Future scrapeEpisodes(String id, {args}) async {
    final List<dynamic> allEpisodes = [];
    String? nextUrl;
    String? animeTitle;
    String url = 'https://beta.yugenanime.tv/api/v2/anime/$id/episodes';

    do {
      final resp = await dio.get(url);
      if (resp.statusCode == 200) {
        final data = resp.data['results'];
        animeTitle = data[0]['anime']['title'];
        final episodes = data.map((episode) {
          return {
            "episodeId": '$id/${episode['episodeNum']}',
            "title": episode['title'],
            "number": episode['episodeNum'],
            "isFiller": episode['filler'],
            "image": episode?['thumbnail'] ?? episode['anime']['poster'],
          };
        }).toList();

        allEpisodes.addAll(episodes);

        nextUrl = resp.data['next'];
        if (nextUrl != null) {
          url = nextUrl;
        }
      } else {
        log('Failed to fetch episodes, status code: ${resp.statusCode}');
        break;
      }
    } while (nextUrl != null);

    final animeWithEpisodes = {
      "title": animeTitle,
      "episodes": allEpisodes,
      "totalEpisodes": allEpisodes.length,
    };

    log(animeWithEpisodes.toString());
    return animeWithEpisodes;
  }

  @override
  Future scrapeEpisodesSrcs(String episodeId,
      {AnimeServers? server, String? category, String? lang}) async {
    final url = 'https://beta.yugenanime.tv/api/v2/watch/$episodeId';
    final resp = await dio.get(url);

    if (resp.statusCode == 200) {
      final data = resp.data['results'];
      if (category == "dub" && data['dub'] != null) {
        return {
          "sources": [
            {
              "url": data['videos']['dub']['hls'][0],
            }
          ]
        };
      } else {
        return {
          "sources": [
            {
              "url": data['videos']['sub']['hls'][0],
            }
          ]
        };
      }
    }
  }

  @override
  Future scrapeSearchResults(String query) async {
    final url = 'https://beta.yugenanime.tv/api/v2/discover?q=$query';
    log(url);
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      log(resp.data.toString());
      final data = resp.data;
      final results = data['results'];
      List<Map<String, dynamic>> searchData = [];
      for (var anime in results) {
        searchData.add({
          "id": '${anime['id']}/${anime['slug']}',
          "name": anime['title'],
          "episodes": {"sub": anime['episodes'], "dub": anime['episodes_dub']},
          "poster": anime['poster']
        });
      }
      return searchData;
    }
  }

  @override
  String get sourceName => "YugenAnime";
}
