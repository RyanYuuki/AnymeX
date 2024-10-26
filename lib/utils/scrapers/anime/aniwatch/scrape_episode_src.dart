import 'dart:convert';
import 'dart:developer';
import 'package:aurora/utils/scrapers/anime/aniwatch/deps/scraper_rapidcloud.dart';
import 'package:aurora/utils/scrapers/anime/aniwatch/deps/scraper_streamsb.dart';
import 'package:aurora/utils/scrapers/anime/aniwatch/deps/scraper_megacloud.dart';
import 'package:aurora/utils/scrapers/anime/aniwatch/deps/scraper_streamtap.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

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

class HttpError implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  HttpError(this.statusCode, this.message, {this.responseBody});

  @override
  String toString() =>
      'HttpError: $statusCode - $message\nResponse: $responseBody';
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

Future<ScrapedAnimeEpisodesSources> scrapeAnimeEpisodeSources(
  String episodeId, {
  AnimeServers server = AnimeServers.MegaCloud,
  String category = 'sub',
}) async {
  log('Starting scrapeAnimeEpisodeSources with episodeId: $episodeId, server: $server, category: $category');

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
        return ScrapedAnimeEpisodesSources(
          headers: {
            'Referer': serverUrl.toString(),
            'User-Agent': USER_AGENT_HEADER,
          },
          tracks: extractedData['tracks'],
          sources: extractedData['sources']
              .map((s) => {
                    'url': s['url'],
                    'quality': 'auto',
                    'isM3U8': s['type'] == 'hls',
                  })
              .toList(),
        );

      case AnimeServers.StreamSB:
        log('Processing StreamSB');
        final streamSB = StreamSB();
        final sources = await streamSB.extract(serverUrl);
        return ScrapedAnimeEpisodesSources(
          headers: {
            'Referer': serverUrl.toString(),
            'watchsb': 'streamsb',
            'User-Agent': USER_AGENT_HEADER,
          },
          sources: sources
              .map((s) => {
                    'url': s.url,
                    'quality': s.quality,
                    'isM3U8': s.isM3U8,
                  })
              .toList(),
        );

      case AnimeServers.StreamTape:
        log('Processing StreamTape');
        final streamTape = StreamTape();
        final sources = await streamTape.extract(serverUrl);
        log(sources.toString());
        return ScrapedAnimeEpisodesSources(
            headers: {
              'Referer': serverUrl.toString(),
              'User-Agent': USER_AGENT_HEADER,
            },
            sources: sources
                .map((source) => {
                      'url': source['url'],
                      'quality': 'auto',
                      'isM3U8': source['isM3U8'],
                    })
                .toList());

      case AnimeServers.VidCloud:
        log('Processing VidCloud');
        final rapidCloud = RapidCloud();
        final extractedData = await rapidCloud.extract(serverUrl);
        log(extractedData.toString());
        return ScrapedAnimeEpisodesSources(
          headers: {
            'Referer': serverUrl.toString(),
          },
          sources: extractedData['sources']
              .map((s) => {
                    'url': s['url'],
                    'quality': s['quality'] ?? 'auto',
                    'isM3U8': s['isM3U8'] ?? false,
                  })
              .toList(),
        );

      default:
        throw Exception('Unsupported server: $server');
    }
  }

  final epId = Uri.parse('$SRC_BASE_URL/watch/$episodeId').toString();
  log('Constructed epId: $epId');

  try {
    final episodeIdParam =
        Uri.encodeComponent(epId.split("?ep=").lastOrNull ?? '');
    final serverUrl =
        Uri.parse('$SRC_AJAX_URL/v2/episode/servers?episodeId=$episodeIdParam');
    log('Fetching episode servers from: $serverUrl');

    final resp = await http.get(serverUrl);

    if (resp.statusCode != 200) {
      log('Failed to fetch episode servers. Status code: ${resp.statusCode}');
      throw HttpError(resp.statusCode, 'Failed to fetch episode servers',
          responseBody: resp.body);
    }

    final jsonResponse = json.decode(resp.body);
    final document = parser.parse(jsonResponse['html']);
    log('Parsed HTML document');

    String? serverId;
    try {
      log('Attempting to retrieve server ID for $server');
      switch (server) {
        case AnimeServers.VidCloud:
          serverId = retrieveServerId(document, 1, category);
          if (serverId == null) throw Exception('RapidCloud not found');
          break;
        case AnimeServers.VidStreaming:
          serverId = retrieveServerId(document, 4, category);
          if (serverId == null) throw Exception('VidStreaming not found');
          break;
        case AnimeServers.StreamSB:
          serverId = retrieveServerId(document, 5, category);
          if (serverId == null) throw Exception('StreamSB not found');
          break;
        case AnimeServers.StreamTape:
          serverId = retrieveServerId(document, 3, category);
          if (serverId == null) throw Exception('StreamTape not found');
          break;
        case AnimeServers.MegaCloud:
          serverId = retrieveServerId(document, 1, category);
          if (serverId == null) throw Exception('MegaCloud not found');
          break;
      }
      log('Retrieved serverId: $serverId');
    } catch (err) {
      log('Failed to retrieve server ID: $err');
      throw HttpError(404, 'Couldn\'t find server. Try another server');
    }

    final sourceUrl =
        Uri.parse('$SRC_AJAX_URL/v2/episode/sources?id=$serverId');
    log('Fetching episode sources from: $sourceUrl');

    final sourceResp = await http.get(sourceUrl);
    if (sourceResp.statusCode != 200) {
      log('Failed to fetch episode sources. Status code: ${sourceResp.statusCode}');
      throw HttpError(sourceResp.statusCode, 'Failed to fetch episode sources',
          responseBody: sourceResp.body);
    }

    final sourceJson = json.decode(sourceResp.body);
    final link = sourceJson['link'];
    log('Retrieved source link: $link');

    return await scrapeAnimeEpisodeSources(link, server: server);
  } catch (err) {
    log('Error in scrapeAnimeEpisodeSources: $err');
    if (err is HttpError) {
      rethrow;
    }
    throw HttpError(500, 'Something went wrong: $err');
  }
}
