// ignore_for_file: constant_identifier_names, unused_local_variable

import 'dart:convert';
import 'dart:developer';
import 'package:aurora/utils/sources/anime/base/source_base.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

String proxyUrl = "";
String consumetUrl = "${dotenv.get('CONSUMET_URL')}meta/anilist/";
String aniwatchUrl = "${dotenv.get('ANIME_URL')}anime/";

class HiAnimeApi implements SourceBase {
  Future<dynamic>? fetchHomePageAniwatch() async {
    final response = await http.get(Uri.parse('$proxyUrl${aniwatchUrl}home'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      log('Error fetching data from Aniwatch API: $response.statusCode');
      return [];
    }
  }

  Future<dynamic>? fetchStreamingDataConsumet(String id) async {
    final resp =
        await http.get(Uri.parse('$proxyUrl${consumetUrl}episodes/$id'));
    if (resp.statusCode == 200) {
      final tempData = jsonDecode(resp.body);
      return tempData;
    }
  }

  Future<dynamic>? fetchStreamingDataAniwatch(String id) async {
    final resp =
        await http.get(Uri.parse('$proxyUrl${aniwatchUrl}episodes/$id'));
    if (resp.statusCode == 200) {
      final tempData = jsonDecode(resp.body);
      return tempData;
    }
  }

  Future<dynamic> fetchStreamingLinksAniwatch(
      String id, String server, String category) async {
    try {
      final url =
          '${aniwatchUrl}episode-srcs?id=$id?server=$server&category=$category';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final tempData = jsonDecode(resp.body);
        return tempData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<dynamic>? fetchStreamingLinksConsumet(String id) async {
    final resp = await http.get(Uri.parse('$proxyUrl${consumetUrl}watch/$id'));
    if (resp.statusCode == 200) {
      final tempData = jsonDecode(resp.body);
      return tempData;
    }
  }

  @override
  bool get isMulti => false;

  @override
  Future<Map<String, dynamic>> scrapeEpisodes(String animeId) async {
    const String srcBaseUrl = 'https://hianime.to';
    const String srcAjaxUrl = 'https://hianime.to/ajax/v2/episode/list';
    const String acceptHeader =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7';
    const String userAgentHeader =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    const String acceptEncodingHeader = 'gzip, deflate, br';

    try {
      final response = await http.get(
        Uri.parse('$srcAjaxUrl/${animeId.split('-').last}'),
        headers: {
          'Accept': acceptHeader,
          'User-Agent': userAgentHeader,
          'X-Requested-With': 'XMLHttpRequest',
          'Accept-Encoding': acceptEncodingHeader,
          'Referer': '$srcBaseUrl/watch/$animeId',
        },
      );

      if (response.statusCode != 200) {
        throw HttpError(response.statusCode, 'Failed to fetch episodes');
      }

      final jsonResponse = json.decode(response.body);
      final document = parse(jsonResponse['html']);

      final episodeElements =
          document.querySelectorAll('.detail-infor-content .ss-list a');
      final totalEpisodes = episodeElements.length;

      final episodes = episodeElements.map((element) {
        return {
          'title': element.attributes['title']?.trim(),
          'episodeId': element.attributes['href']?.split('/').last,
          'number': int.tryParse(element.attributes['data-number'] ?? '') ?? 0,
          'isFiller': element.classes.contains('ssl-item-filler'),
        };
      }).toList();

      final scrapedData = {
        'title': formatAnimeTitle(animeId),
        'totalEpisodes': totalEpisodes,
        'episodes': episodes,
      };
      return scrapedData;
    } catch (e) {
      if (e is http.ClientException) {
        throw HttpError(500, 'Network error: ${e.message}');
      } else if (e is HttpError) {
        rethrow;
      } else {
        throw HttpError(500, 'Internal server error: ${e.toString()}');
      }
    }
  }

  @override
  Future scrapeEpisodesSrcs(String episodeId,
      {AnimeServers? server, String? category, String? lang}) async {
    try {
      final url =
          '${aniwatchUrl}episode-srcs?id=$episodeId?server=$lang&category=$category';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final tempData = jsonDecode(resp.body);
        return tempData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> scrapeSearchResults(String query,
      {int page = 1}) async {
    const String baseUrl = 'https://hianime.to/';
    final String url =
        '${baseUrl}search?keyword=$query&page=$page&sort=default';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final animes = extractAnimes(
            document, '#main-content .tab-content .film_list-wrap .flw-item');
        return animes;
      } else {
        throw Exception(
            'Failed to load search results. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch anime search results: $e');
    }
  }

  String? retrieveServerId(Document document, int index, String category) {
    final serverItems = document.querySelectorAll(
        '.ps_-block.ps_-block-sub.servers-$category > .ps__-list .server-item');

    for (var el in serverItems) {
      if (el.attributes['data-server-id'] == index.toString()) {
        return el.attributes['data-id'];
      }
    }
    return null;
  }

  List<Map<String, dynamic>> extractAnimes(Document document, String selector) {
    try {
      List<Map<String, dynamic>> animes = [];

      document.querySelectorAll(selector).forEach((element) {
        final animeId = element
            .querySelector('.film-detail .film-name .dynamic-name')
            ?.attributes['href']
            ?.replaceFirst('/', '')
            .split('?ref=search')[0];

        final name = element
            .querySelector('.film-detail .film-name .dynamic-name')
            ?.text
            .trim();

        final jname = element
            .querySelector('.film-detail .film-name .dynamic-name')
            ?.attributes['data-jname']
            ?.trim();

        final poster = element
            .querySelector('.film-poster .film-poster-img')
            ?.attributes['data-src']
            ?.trim();

        final fdInfoElements =
            element.querySelectorAll('.film-detail .fd-infor .fdi-item');

        final type = fdInfoElements.isNotEmpty
            ? fdInfoElements[0].text.trim()
            : 'Unknown';

        final duration = fdInfoElements.length > 1
            ? fdInfoElements[1].text.trim()
            : 'Unknown';

        final rating =
            element.querySelector('.film-poster .tick-rate')?.text.trim() ??
                'N/A';

        final subEpisodes = int.tryParse(element
                .querySelector('.film-poster .tick-sub')
                ?.text
                .trim()
                .split(" ")
                .last ??
            '0');

        final dubEpisodes = int.tryParse(element
                .querySelector('.film-poster .tick-dub')
                ?.text
                .trim()
                .split(" ")
                .last ??
            '0');

        animes.add({
          'id': animeId,
          'name': name ?? 'Unknown',
          'jname': jname ?? 'Unknown',
          'poster': poster ?? '',
          'duration': duration,
          'type': type,
          'rating': rating,
          'episodes': {
            'sub': subEpisodes,
            'dub': dubEpisodes,
          },
        });
      });

      return animes;
    } catch (e) {
      throw Exception('Failed to extract animes: $e');
    }
  }

  @override
  String get sourceName => "HiAnime (API)";
}
