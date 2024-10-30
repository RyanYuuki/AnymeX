// ignore_for_file: constant_identifier_names

import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

const String SRC_HOME_URL = 'https://hianime.to/home';
Future<Map<String, dynamic>> scrapeHomePage() async {
  final Map<String, dynamic> res = {
    'spotlightAnimes': [],
    'trendingAnimes': [],
    'latestEpisodeAnimes': [],
    'topUpcomingAnimes': [],
    'top10Animes': {
      'today': [],
      'week': [],
      'month': [],
    },
    'topAiringAnimes': [],
    'mostPopularAnimes': [],
    'mostFavoriteAnimes': [],
    'latestCompletedAnimes': [],
    'genres': [],
  };

  try {
    final response = await http.get(Uri.parse(SRC_HOME_URL));
    if (response.statusCode != 200) {
      throw Exception('Failed to load page: ${response.statusCode}');
    }

    final document = parse(response.body);

    res['spotlightAnimes'] = extractSpotlightAnimes(document);
    res['trendingAnimes'] = extractTrendingAnimes(document);
    res['latestEpisodeAnimes'] = extractAnimes(document,
        '#main-content .block_area_home .tab-content .film_list-wrap .flw-item');
    res['topUpcomingAnimes'] = extractAnimes(document,
        '#main-content .block_area_home .tab-content .film_list-wrap .flw-item',
        index: 2);
    res['genres'] = extractGenres(document);
    res['top10Animes'] = extractTop10Animes(document);
    res['topAiringAnimes'] = extractMostPopularAnimes(
        document, "#anime-featured .row div .anif-block-ul ul li",
        index: 0);
    res['mostPopularAnimes'] = extractMostPopularAnimes(
        document, "#anime-featured .row div .anif-block-ul ul li",
        index: 1);
    res['mostFavoriteAnimes'] = extractMostPopularAnimes(
        document, "#anime-featured .row div .anif-block-ul ul li",
        index: 2);
    res['latestCompletedAnimes'] = extractMostPopularAnimes(
        document, "#anime-featured .row div .anif-block-ul ul li",
        index: 3);
  } catch (e) {
    log('Error scraping homepage: $e');
    throw Exception('Failed to scrape homepage: $e');
  }
  log(res.toString());
  return res;
}

List<Map<String, dynamic>> extractSpotlightAnimes(Document document) {
  final spotlightAnimes = <Map<String, dynamic>>[];
  final elements =
      document.querySelectorAll("#slider .swiper-wrapper .swiper-slide");

  for (var el in elements) {
    final otherInfo = el
        .querySelectorAll(".deslide-item-content .sc-detail .scd-item")
        .map((e) => e.text.trim())
        .toList();

    spotlightAnimes.add({
      'rank': int.tryParse(el
              .querySelector(".deslide-item-content .desi-sub-text")
              ?.text
              .trim()
              .split(" ")[0]
              .substring(1) ??
          ''),
      'id': el
          .querySelector(".deslide-item-content .desi-buttons a")
          ?.attributes['href']
          ?.substring(1)
          .trim(),
      'name': el
          .querySelector(".deslide-item-content .desi-head-title.dynamic-name")
          ?.text
          .trim(),
      'description': el
          .querySelector(".deslide-item-content .desi-description")
          ?.text
          .split("[")
          .first
          .trim(),
      'poster': el
          .querySelector(".deslide-cover .deslide-cover-img .film-poster-img")
          ?.attributes['data-src']
          ?.trim(),
      'jname': el
          .querySelector(".deslide-item-content .desi-head-title.dynamic-name")
          ?.attributes['data-jname']
          ?.trim(),
      'episodes': {
        'sub': int.tryParse(el
                .querySelector(
                    ".deslide-item-content .sc-detail .scd-item .tick-item.tick-sub")
                ?.text
                .trim() ??
            ''),
        'dub': int.tryParse(el
                .querySelector(
                    ".deslide-item-content .sc-detail .scd-item .tick-item.tick-dub")
                ?.text
                .trim() ??
            ''),
      },
      'otherInfo': otherInfo,
    });
  }

  return spotlightAnimes;
}

List<Map<String, dynamic>> extractTrendingAnimes(Document document) {
  final trendingAnimes = <Map<String, dynamic>>[];
  final elements =
      document.querySelectorAll("#trending-home .swiper-wrapper .swiper-slide");

  for (var el in elements) {
    trendingAnimes.add({
      'rank': int.tryParse(
          el.querySelector(".item .number")?.children.first.text.trim() ?? ''),
      'id': el
          .querySelector(".item .film-poster")
          ?.attributes['href']
          ?.substring(1)
          .trim(),
      'name': el
          .querySelector(".item .number .film-title.dynamic-name")
          ?.text
          .trim(),
      'jname': el
          .querySelector(".item .number .film-title.dynamic-name")
          ?.attributes['data-jname']
          ?.trim(),
      'poster': el
          .querySelector(".item .film-poster .film-poster-img")
          ?.attributes['data-src']
          ?.trim(),
    });
  }

  return trendingAnimes;
}

List<Map<String, dynamic>> extractAnimes(Document document, String selector,
    {int index = 0}) {
  final animes = <Map<String, dynamic>>[];
  final blockAreas =
      document.querySelectorAll('#main-content .block_area_home');
  if (index < blockAreas.length) {
    final elements = blockAreas[index].querySelectorAll(selector);

    for (var el in elements) {
      animes.add({
        'id':
            el.querySelector(".dynamic-name")?.attributes['href']?.substring(1),
        'name': el.querySelector(".dynamic-name")?.text.trim(),
        'jname':
            el.querySelector(".dynamic-name")?.attributes['data-jname']?.trim(),
        'poster': el
            .querySelector(".film-poster-img")
            ?.attributes['data-src']
            ?.trim(),
        'duration': el.querySelector(".fd-infor .duration")?.text.trim(),
        'type': el.querySelector(".fd-infor .type")?.text.trim(),
        'rating': el.querySelector(".fd-infor .rating")?.text.trim(),
        'episodes': {
          'sub': int.tryParse(
              el.querySelector(".tick-item.tick-sub")?.text.trim() ?? ''),
          'dub': int.tryParse(
              el.querySelector(".tick-item.tick-dub")?.text.trim() ?? ''),
        }
      });
    }
  }

  return animes;
}

List<String> extractGenres(Document document) {
  return document
      .querySelectorAll(
          "#main-sidebar .block_area.block_area_sidebar.block_area-genres .sb-genre-list li")
      .map((el) => el.text.trim())
      .toList();
}

Map<String, List<Map<String, dynamic>>> extractTop10Animes(Document document) {
  final top10Animes = {
    'today': <Map<String, dynamic>>[],
    'week': <Map<String, dynamic>>[],
    'month': <Map<String, dynamic>>[],
  };

  final elements = document.querySelectorAll(
      '#main-sidebar .block_area-realtime [id^="top-viewed-"]');

  for (var el in elements) {
    final period = el.id.split("-").last.trim();

    final animes = el
        .querySelectorAll("ul li")
        .map((li) => {
              'id': li
                  .querySelector(".film-detail .dynamic-name")
                  ?.attributes['href']
                  ?.substring(1)
                  .trim(),
              'rank': int.tryParse(
                  li.querySelector(".film-number span")?.text.trim() ?? ''),
              'name':
                  li.querySelector(".film-detail .dynamic-name")?.text.trim(),
              'jname': li
                  .querySelector(".film-detail .dynamic-name")
                  ?.attributes['data-jname']
                  ?.trim(),
              'poster': li
                  .querySelector(".film-poster .film-poster-img")
                  ?.attributes['data-src']
                  ?.trim(),
              'episodes': {
                'sub': int.tryParse(li
                        .querySelector(
                            ".film-detail .fd-infor .tick-item.tick-sub")
                        ?.text
                        .trim() ??
                    ''),
                'dub': int.tryParse(li
                        .querySelector(
                            ".film-detail .fd-infor .tick-item.tick-dub")
                        ?.text
                        .trim() ??
                    ''),
              },
            })
        .toList();

    if (period == 'day') {
      top10Animes['today'] = animes;
    } else if (period == 'week') {
      top10Animes['week'] = animes;
    } else if (period == 'month') {
      top10Animes['month'] = animes;
    }
  }

  return top10Animes;
}

List<Map<String, dynamic>> extractMostPopularAnimes(
    Document document, String selector,
    {required int index}) {
  final animes = <Map<String, dynamic>>[];
  final rows = document.querySelectorAll("#anime-featured .row div");
  if (index < rows.length) {
    final elements = rows[index].querySelectorAll(selector);

    for (var el in elements) {
      animes.add({
        'id': el
            .querySelector(".film-detail .dynamic-name")
            ?.attributes['href']
            ?.substring(1)
            .trim(),
        'name': el.querySelector(".film-detail .dynamic-name")?.text.trim(),
        'jname': el
            .querySelector(".film-detail .film-name .dynamic-name")
            ?.attributes['data-jname']
            ?.trim(),
        'poster': el
            .querySelector(".film-poster .film-poster-img")
            ?.attributes['data-src']
            ?.trim(),
        'episodes': {
          'sub': int.tryParse(
              el.querySelector(".fd-infor .tick .tick-sub")?.text.trim() ?? ''),
          'dub': int.tryParse(
              el.querySelector(".fd-infor .tick .tick-dub")?.text.trim() ?? ''),
        },
        'type': el
            .querySelector(".fd-infor .tick")
            ?.text
            .trim()
            .split(RegExp(r'\s+'))
            .last,
      });
    }
  }

  return animes;
}
