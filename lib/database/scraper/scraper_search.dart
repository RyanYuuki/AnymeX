import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

import 'package:html/dom.dart';

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
          ?.trim();

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

      final type =
          fdInfoElements.isNotEmpty ? fdInfoElements[0].text.trim() : 'Unknown';

      final duration =
          fdInfoElements.length > 1 ? fdInfoElements[1].text.trim() : 'Unknown';

      final rating =
          element.querySelector('.film-poster .tick-rate')?.text?.trim() ??
              'N/A';

      final subEpisodes = int.tryParse(element
              .querySelector('.film-poster .tick-sub')
              ?.text
              ?.trim()
              ?.split(" ")
              .last ??
          '0');

      final dubEpisodes = int.tryParse(element
              .querySelector('.film-poster .tick-dub')
              ?.text
              ?.trim()
              ?.split(" ")
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

Future<List<Map<String, dynamic>>> scrapeAnimeSearch(String query,
    {int page = 1}) async {
  const String baseUrl = 'https://hianime.to/';
  final String url = '${baseUrl}search?keyword=$query&page=$page&sort=default';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = html.parse(response.body);
      final animes = extractAnimes(
          document, '#main-content .tab-content .film_list-wrap .flw-item');
      log(animes.toString());
      return animes;
    } else {
      throw Exception(
          'Failed to load search results. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch anime search results: $e');
  }
}
