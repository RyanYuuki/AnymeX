// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'dart:convert';
import 'dart:developer';
import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/deps/scraper_megacloud.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';

class HttpError implements Exception {
  final int statusCode;
  final String message;

  HttpError(this.statusCode, this.message);

  @override
  String toString() => 'HttpError: $statusCode $message';
}

String formatAnimeTitle(String animeId) {
  var arr = animeId.split('-').toList();
  arr.removeLast();
  var animeTitle =
      arr.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  return animeTitle;
}

class HiAnime implements SourceBase {
  @override
  Future<Map<String, dynamic>> scrapeEpisodes(String animeId,
      {dynamic args}) async {
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

  @override
  Future<dynamic> scrapeEpisodesSrcs(
    String episodeId, {
    String? lang,
    AnimeServers? server = AnimeServers.MegaCloud,
    String? category = 'sub',
  }) async {
    log('Starting scrapeAnimeEpisodeSources with episodeId: $episodeId, server: $server, category: $category');

    const int maxRetries = 5;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        log('Attempt ${attempt + 1} of $maxRetries');

        if (episodeId.startsWith('http')) {
          log('episodeId is a URL, processing accordingly');
          final serverUrl = Uri.parse(episodeId);

          switch (server) {
            case AnimeServers.VidStreaming:
            case AnimeServers.MegaCloud:
              log('Processing MegaCloud');
              final megaCloud = MegaCloud();
              final extractedData = await megaCloud.extract(serverUrl);
              log(extractedData.toString());
              return extractedData;
            default:
              throw Exception('Unsupported server: $server');
          }
        }

        final epId = Uri.parse('$SRC_BASE_URL/watch/$episodeId').toString();
        log('Constructed epId: $epId');

        final episodeIdParam =
            Uri.encodeComponent(epId.split("?ep=").lastOrNull ?? '');
        final serverUrl = Uri.parse(
            '$SRC_AJAX_URL/v2/episode/servers?episodeId=$episodeIdParam');
        log('Fetching episode servers from: $serverUrl');

        final resp = await http.get(serverUrl);
        if (resp.statusCode != 200) {
          log('Failed to fetch episode servers. Status code: ${resp.statusCode}');
          throw HttpErrors(resp.statusCode, 'Failed to fetch episode servers',
              responseBody: resp.body);
        }

        final jsonResponse = json.decode(resp.body);
        final document = parse(jsonResponse['html']);
        log('Parsed HTML document');

        String? serverId;
        log('Attempting to retrieve server ID for $server');
        switch (server!) {
          case AnimeServers.VidCloud:
            serverId = retrieveServerId(document, 1, category!);
            if (serverId == null) throw Exception('RapidCloud not found');
            break;
          case AnimeServers.VidStreaming:
            serverId = retrieveServerId(document, 4, category!);
            if (serverId == null) throw Exception('VidStreaming not found');
            break;
          case AnimeServers.StreamSB:
            serverId = retrieveServerId(document, 5, category!);
            if (serverId == null) throw Exception('StreamSB not found');
            break;
          case AnimeServers.StreamTape:
            serverId = retrieveServerId(document, 3, category!);
            if (serverId == null) throw Exception('StreamTape not found');
            break;
          case AnimeServers.MegaCloud:
            serverId = retrieveServerId(document, 1, category!);
            if (serverId == null) throw Exception('MegaCloud not found');
            break;
        }
        log('Retrieved serverId: $serverId');

        final sourceUrl =
            Uri.parse('$SRC_AJAX_URL/v2/episode/sources?id=$serverId');
        log('Fetching episode sources from: $sourceUrl');

        final sourceResp = await http.get(sourceUrl);
        if (sourceResp.statusCode != 200) {
          log('Failed to fetch episode sources. Status code: ${sourceResp.statusCode}');
          throw HttpErrors(
              sourceResp.statusCode, 'Failed to fetch episode sources',
              responseBody: sourceResp.body);
        }

        final sourceJson = json.decode(sourceResp.body);
        final link = sourceJson['link'];
        log('Retrieved source link: $link');

        return await scrapeEpisodesSrcs(link, server: server);
      } catch (err) {
        attempt++;
        log('Error in scrapeAnimeEpisodeSources (Attempt $attempt): $err');

        if (attempt >= maxRetries) {
          log('Max retries reached. Throwing error.');
          if (err is HttpError) {
            rethrow;
          }
          throw HttpError(
              500, 'Something went wrong after multiple retries: $err');
        }

        log('Retrying scrapeAnimeEpisodeSources... Attempts left: ${maxRetries - attempt}');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw HttpError(500, 'Unexpected error: This point should not be reached');
  }

  @override
  String get sourceName => 'HiAnime (Scrapper)';

  @override
  bool get isMulti => false;
}

const String SRC_BASE_URL = 'https://hianime.to';
const String SRC_AJAX_URL = '$SRC_BASE_URL/ajax/';
const String USER_AGENT_HEADER =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36';

enum AnimeServers { VidStreaming, VidCloud, StreamSB, StreamTape, MegaCloud }

class ScrapedAnimeEpisodesSources {
  final Map<String, String> headers;
  final dynamic sources;
  final dynamic tracks;

  ScrapedAnimeEpisodesSources(
      {required this.headers, required this.sources, this.tracks});
}

class HttpErrors implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  HttpErrors(this.statusCode, this.message, {this.responseBody});

  @override
  String toString() =>
      'HttpError: $statusCode - $message\nResponse: $responseBody';
}
