import 'dart:convert';
import 'dart:developer';

import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

class AniVibe implements SourceBase {
  @override
  String get sourceName => 'AniVibe';

  @override
  bool get isMulti => false;
  String baseUrl = 'https://anivibe.net';

  Dio dio = Dio();

  @override
  Future scrapeEpisodes(String url, {args}) async {
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      var document = parse(resp.data);
      var episodeListElements = document.querySelectorAll('.eplister ul li');

      var episodeList = [];
      for (var episode in episodeListElements) {
        var episodeId = episode.querySelector('a')?.attributes['href'];
        var episodeTitle = episode.querySelector('.epl-title')?.text;
        var number = episode.querySelector('.epl-num')?.text;

        episodeList.add({
          'episodeId': baseUrl + episodeId!,
          'title': episodeTitle?.trim(),
          'number': int.parse(number!)
        });
      }

      var data = {
        'title': document
                .querySelector('.entry-title.d-title')
                ?.attributes['data-en'] ??
            document.querySelector('.entry-title.d-title')?.text.trim(),
        'episodes': episodeList.reversed.toList(),
        'totalEpisodes': episodeList.length
      };

      log(data.toString());
      return data;
    }
  }

  @override
  Future scrapeEpisodesSrcs(String episodeId,
      {AnimeServers? server, String? category, String? lang}) async {
    final resp = await dio.get(episodeId);

    if (resp.statusCode == 200) {
      var document = parse(resp.data);
      var scriptTags = document.querySelectorAll('script');

      for (var script in scriptTags) {
        var scriptContent = script.text;

        if (scriptContent.contains('loadIframePlayer')) {
          var jsonStart = scriptContent.indexOf('loadIframePlayer(') + 18;
          var jsonEnd = scriptContent.indexOf(']', jsonStart) + 1;
          var jsonString = scriptContent.substring(jsonStart, jsonEnd);

          try {
            var jsonData = jsonDecode(jsonString) as List<dynamic>;

            for (var entry in jsonData) {
              if (entry['type'] == "DUB" && category == 'dub') {
                return {
                  "sources": [
                    {"url": entry['url']}
                  ]
                };
              } else if (entry['type'] == "SUB" && category == 'sub') {
                return {
                  "sources": [
                    {"url": entry['url']}
                  ]
                };
              }
            }
          } catch (e) {
            log('Error parsing JSON: $e');
          }

          break;
        }
      }
    }
  }

  @override
  Future scrapeSearchResults(String query) async {
    final resp =
        await dio.get('https://anivibe.net/search.html?keyword=$query');
    if (resp.statusCode == 200) {
      var document = parse(resp.data);

      var searchItems = document.querySelectorAll('.listupd article');
      var animeList = [];
      for (var anime in searchItems) {
        var id = anime.querySelector('a')?.attributes['href'];
        var name = anime.querySelector('img')?.attributes['title'];
        var poster = anime.querySelector('img')?.attributes['src'];
        animeList.add({
          'id': baseUrl + id!,
          'name': name,
          'poster': poster,
        });
      }
      log(animeList.toString());
      return animeList;
    }
  }
}
