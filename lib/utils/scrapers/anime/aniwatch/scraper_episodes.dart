// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:convert';

class HttpError implements Exception {
  final int statusCode;
  final String message;

  HttpError(this.statusCode, this.message);

  @override
  String toString() => 'HttpError: $statusCode $message';
}

Future<Map<String, dynamic>> scrapeAnimeEpisodes(String animeId) async {
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
