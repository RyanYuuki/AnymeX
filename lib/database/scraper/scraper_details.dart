import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'dart:convert';

const String BASE_URL = 'https://hianime.to';

Future<Map<String, dynamic>> scrapeAnimeAboutInfo(String animeId) async {
  final result = <String, dynamic>{
    'id': animeId,
    'stats': {},
    'promotionalVideos': [],
    'charactersVoiceActors': [],
    'seasons': [],
    'mostPopularAnimes': [],
    'relatedAnimes': [],
    'recommendedAnimes': [],
  };

  try {
    final response = await http.get(Uri.parse('$BASE_URL/$animeId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load page');
    }

    final document = parse(response.body);

    try {
      final syncData = document.querySelector('#syncData')?.text;
      if (syncData != null) {
        final jsonData = json.decode(syncData);
        result['anilistId'] = jsonData['anilist_id'];
        result['malId'] = jsonData['mal_id'];
      }
    } catch (e) {
      log(e.toString());
    }

    const selector = '#ani_detail .container .anis-content';

    result['name'] = document
        .querySelector('$selector .anisc-detail .film-name.dynamic-name')
        ?.text
        .trim();
    result['description'] = document
        .querySelector('$selector .anisc-detail .film-description .text')
        ?.text
        .split('[')
        .first
        .trim();
    result['poster'] = document
        .querySelector('$selector .film-poster .film-poster-img')
        ?.attributes['src']
        ?.trim();

    result['stats']['rating'] = document
        .querySelector('$selector .film-stats .tick .tick-pg')
        ?.text
        .trim();
    result['stats']['quality'] = document
        .querySelector('$selector .film-stats .tick .tick-quality')
        ?.text
        .trim();
    result['stats']['episodes'] = {
      'sub': int.tryParse(document
              .querySelector('$selector .film-stats .tick .tick-sub')
              ?.text
              .trim() ??
          ''),
      'dub': int.tryParse(document
              .querySelector('$selector .film-stats .tick .tick-dub')
              ?.text
              .trim() ??
          ''),
    };
    final statsText = document
        .querySelector('$selector .film-stats .tick')
        ?.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ');
    result['stats']['type'] = statsText?.elementAt(statsText.length - 2);
    result['stats']['duration'] = statsText?.last;

    document
        .querySelectorAll(
            '.block_area.block_area-promotions .block_area-promotions-list .screen-items .item')
        .forEach((element) {
      result['promotionalVideos'].add({
        'title': element.attributes['data-title'],
        'source': element.attributes['data-src'],
        'thumbnail': element.querySelector('img')?.attributes['src'],
      });
    });

    document
        .querySelectorAll(
            '.block_area.block_area-actors .block-actors-content .bac-list-wrap .bac-item')
        .forEach((element) {
      result['charactersVoiceActors'].add({
        'character': {
          'id': element
              .querySelector('.per-info.ltr .pi-avatar')
              ?.attributes['href']
              ?.split('/')[2],
          'poster': element
              .querySelector('.per-info.ltr .pi-avatar img')
              ?.attributes['data-src'],
          'name': element.querySelector('.per-info.ltr .pi-detail a')?.text,
          'cast':
              element.querySelector('.per-info.ltr .pi-detail .pi-cast')?.text,
        },
        'voiceActor': {
          'id': element
              .querySelector('.per-info.rtl .pi-avatar')
              ?.attributes['href']
              ?.split('/')[2],
          'poster': element
              .querySelector('.per-info.rtl .pi-avatar img')
              ?.attributes['data-src'],
          'name': element.querySelector('.per-info.rtl .pi-detail a')?.text,
          'cast':
              element.querySelector('.per-info.rtl .pi-detail .pi-cast')?.text,
        },
      });
    });

    document
        .querySelectorAll(
            '$selector .anisc-info-wrap .anisc-info .item:not(.w-hide)')
        .forEach((element) {
      String key = element
              .querySelector('.item-head')
              ?.text
              .toLowerCase()
              .replaceAll(':', '')
              .trim() ??
          '';
      key = key.contains(' ') ? key.replaceAll(' ', '') : key;

      final value = element
          .querySelectorAll('*:not(.item-head)')
          .map((e) => e.text.trim())
          .join(', ');

      if (key == 'genres' || key == 'producers') {
        result[key] = value.split(',').map((e) => e.trim()).toList();
      } else {
        result[key] = value;
      }
    });

    document
        .querySelectorAll('#main-content .os-list a.os-item')
        .forEach((element) {
      result['seasons'].add({
        'id': element.attributes['href']?.substring(1).trim(),
        'name': element.attributes['title']?.trim(),
        'title': element.querySelector('.title')?.text.trim(),
        'poster': element
            .querySelector('.season-poster')
            ?.attributes['style']
            ?.split(' ')
            .last
            .split('(')
            .last
            .split(')')
            .first,
        'isCurrent': element.classes.contains('active'),
      });
    });

    final sidebarBlocks = document.querySelectorAll(
        '#main-sidebar .block_area.block_area_sidebar.block_area-realtime');
    if (sidebarBlocks.length >= 2) {
      result['relatedAnimes'] =
          extractMostPopularAnimes(sidebarBlocks[0], '.anif-block-ul ul li');
      result['mostPopularAnimes'] =
          extractMostPopularAnimes(sidebarBlocks[1], '.anif-block-ul ul li');
    }
    result['recommendedAnimes'] = extractAnimes(document,
        '#main-content .block_area.block_area_category .tab-content .flw-item');
    return result;
  } catch (e) {
    throw Exception('Failed to scrape anime info $e');
  }
}

List<Map<String, dynamic>> extractMostPopularAnimes(
    Element parentElement, String selector) {
  final animes = <Map<String, dynamic>>[];
  parentElement.querySelectorAll(selector).forEach((element) {
    animes.add({
      'id': element
          .querySelector('.film-detail .dynamic-name')
          ?.attributes['href']
          ?.substring(1)
          .trim(),
      'name': element.querySelector('.film-detail .dynamic-name')?.text.trim(),
      'jname': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.attributes['data-jname']
          ?.trim(),
      'poster': element
          .querySelector('.film-poster .film-poster-img')
          ?.attributes['data-src']
          ?.trim(),
      'episodes': {
        'sub': int.tryParse(
            element.querySelector('.fd-infor .tick .tick-sub')?.text.trim() ??
                ''),
        'dub': int.tryParse(
            element.querySelector('.fd-infor .tick .tick-dub')?.text.trim() ??
                ''),
      },
      'type': element
          .querySelector('.fd-infor .tick')
          ?.text
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .split(' ')
          .last,
    });
  });
  return animes;
}

List<Map<String, dynamic>> extractAnimes(Document document, String selector) {
  final animes = <Map<String, dynamic>>[];
  document.querySelectorAll(selector).forEach((element) {
    final animeId = element
        .querySelector('.film-detail .film-name .dynamic-name')
        ?.attributes['href']
        ?.substring(1)
        .split('?ref=search')[0];
    final fdiItems =
        element.querySelectorAll('.film-detail .fd-infor .fdi-item');
    final type = fdiItems.isNotEmpty ? fdiItems[0].text.trim() : null;
    final duration = fdiItems.length > 1 ? fdiItems[1].text.trim() : null;

    animes.add({
      'id': animeId,
      'name': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.text
          .trim(),
      'jname': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.attributes['data-jname']
          ?.trim(),
      'poster': element
          .querySelector('.film-poster .film-poster-img')
          ?.attributes['data-src']
          ?.trim(),
      'duration': duration,
      'type': type,
      'rating': element.querySelector('.film-poster .tick-rate')?.text.trim(),
      'episodes': {
        'sub': int.tryParse(element
                .querySelector('.film-poster .tick-sub')
                ?.text
                .trim()
                .split(' ')
                .last ??
            ''),
        'dub': int.tryParse(element
                .querySelector('.film-poster .tick-dub')
                ?.text
                .trim()
                .split(' ')
                .last ??
            ''),
      },
    });
  });
  return animes;
}
