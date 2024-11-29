// ignore_for_file: unused_local_variable, prefer_const_declarations
import 'dart:developer';
import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class AnimeWorld implements SourceBase {
  final dio = Dio();

  @override
  Future<dynamic> scrapeEpisodesSrcs(String url,
      {String? lang, String? category, AnimeServers? server}) async {
    dynamic streamUrls = {};

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final document = parse(response.data);
        final iframeElement = document.querySelector('iframe');
        if (iframeElement != null) {
          final iframeSrc = iframeElement.attributes['src'];
          if (iframeSrc != null) {
            final newResp = await http.get(Uri.parse(iframeSrc));
            if (newResp.statusCode == 200) {
              final newDoc = parse(newResp.body);
              final scriptTag =
                  newDoc.querySelector('#playerbase')?.nextElementSibling?.text;
              if (scriptTag != null) {
                final idRegex = RegExp(r'"([a-f0-9]{32})"');
                final match = idRegex.firstMatch(scriptTag);
                if (match != null) {
                  final id = match.group(1);
                  final tracks =
                      'https://beta.awstream.net/subs/m3u8/$id/subtitles-eng.vtt';
                  final m3u8Url =
                      'https://beta.awstream.net/m3u8/$id/master.txt?s=1';
                  final m3u8Content =
                      'https://m3u8-ryan.vercel.app/api/convert?url=$m3u8Url';
                  streamUrls = {
                    'sources': [
                      {'url': m3u8Content, 'type': 'hls'}
                    ],
                    'tracks': [
                      {'label': 'English', 'file': tracks, 'kind': 'captions'}
                    ]
                  };
                }
              }
            }
          }
        }
      }
    } catch (e) {
      log('Request failed: $e');
    }

    return streamUrls;
  }

  @override
  Future<dynamic> scrapeEpisodes(String url, {dynamic args}) async {
    final resp = await dio.get(url);
    if (resp.statusCode == 200) {
      final document = parse(resp.data);

      var title = document.querySelector('.entry-title')?.text.trim();
      var availLanguages = [];
      var availLanguagesTags = document
          .querySelectorAll('.loadactor a')
          .forEach((lang) => availLanguages.add(lang.text));
      var moreThanOneSeason =
          document.querySelectorAll('.sel-temp a').length > 1;
      var episodes =
          document.querySelectorAll('#episode_by_temp li').map((episode) {
        var id = document.querySelector('.lnk-blk')?.attributes['href'];
        final title = episode.querySelector('.entry-title')?.text;
        final image = episode.querySelector('img')?.attributes['src'];
        final number = episode.querySelector('.num-epi')?.text.split('x').last;

        return {
          'episodeId': id,
          'title': title,
          'image': image!.startsWith('//') ? 'https:$image' : image,
          'number': int.parse(number!),
        };
      }).toList();
      final animeEpisodes = {
        'id': url,
        'title': title,
        'episodes': episodes,
        'totalEpisodes': episodes.length
      };
      log(animeEpisodes.toString());
      return animeEpisodes;
    }
    return {};
  }

  @override
  String get sourceName => 'AnimeWorld';

  @override
  Future scrapeSearchResults(String query) async {
    final url = 'https://anime-world.in/?s=$query';
    final resp = await dio.get(url);
    dynamic searchData = [];
    if (resp.statusCode == 200) {
      final data = resp.data;
      final document = parse(data);

      var cardTags = document.querySelectorAll('.post-lst li');

      for (var card in cardTags) {
        card.querySelector('.vote span')?.remove();
        var id = card.querySelector('a')?.attributes['href'];
        var title = card.querySelector('.entry-title')?.text.trim();
        var rating = card.querySelector('.vote')?.text.trim();
        var poster = card.querySelector('img')?.attributes['src'];

        searchData.add({
          'id': id,
          'name': title,
          'rating': rating,
          'poster': 'https:$poster'
        });
      }
    }
    log(searchData.toString());
    return searchData;
  }

  @override
  bool get isMulti => true;
}
