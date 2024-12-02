import 'dart:developer';

import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:dio/dio.dart';

class MangaDex implements SourceBase {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mangadex.org',
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    },
  ));

  final String defaultLanguage = 'en';
  final bool reverseChaptersOrder = false;

  Future<Response> _request(String endpoint) async {
    try {
      return await _dio.get(endpoint);
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  @override
  Future<dynamic> fetchMangaSearchResults(String keyword) async {
    const offset = (1 - 1) * 30;
    final response = await _request(
        '/manga?title=$keyword&limit=30&offset=$offset&includes[]=cover_art');

    final data = response.data['data'];
    final searchData = data.map<Map<String, dynamic>>((item) {
      final mangaId = item['id'];
      final coverArt = item['relationships']
              .firstWhere((rel) => rel['type'] == 'cover_art')['attributes']
          ['fileName'];

      return {
        'id': mangaId,
        'title': item['attributes']['title'].values.first ?? 'Unknown Title',
        'image':
            'https://uploads.mangadex.org/covers/$mangaId/$coverArt.256.jpg',
      };
    }).toList();
    log(searchData.toString());
    return searchData;
  }

  @override
  Future<dynamic> fetchMangaChapters(String mangaId) async {
    final response = await _request('/manga/$mangaId?includes[]=cover_art');
    final manga = response.data['data'];

    final coverArt = manga['relationships']
            .firstWhere((rel) => rel['type'] == 'cover_art')['attributes']
        ['fileName'];

    final chaptersResponse = await _request(
        '/manga/$mangaId/feed');
    final chapters = chaptersResponse.data['data'];

    if (reverseChaptersOrder) {
      chapters.reverse();
    }

    final Map<String, List<Map<String, dynamic>>> chaptersByLanguage = {};

    for (var chapter in chapters) {
      final lang = chapter['attributes']['translatedLanguage'];
      final chapterInfo = {
        'name': 'Chapter ${chapter['attributes']['chapter']}',
        'url': chapter['id'],
      };

      chaptersByLanguage.putIfAbsent(lang, () => []).add(chapterInfo);
    }

    final sortedChapters = chaptersByLanguage.entries.toList()
      ..sort((a, b) {
        if (a.key == defaultLanguage) return -1;
        if (b.key == defaultLanguage) return 1;
        return a.key.compareTo(b.key);
      });

    final episodes = sortedChapters.map((entry) {
      return {
        'title': entry.key,
        'urls': entry.value,
      };
    }).toList();
    log({
      'title': manga['attributes']['title']['en'],
      'image': 'https://uploads.mangadex.org/covers/$mangaId/$coverArt',
      'chapterList': chapters,
    }.toString());
    log("Chapters : " + episodes.length.toString());
    return {
      'title': manga['attributes']['title']['en'],
      'cover': 'https://uploads.mangadex.org/covers/$mangaId/$coverArt',
      'desc': manga['attributes']['description']['en'].trim(),
      'episodes': episodes,
    };
  }

  @override
  Future<dynamic> fetchChapterImages(
      {String? chapterId, String? mangaId}) async {
    final response = await _request('/at-home/server/$chapterId');
    final baseUrl = response.data['baseUrl'];
    final chapterHash = response.data['chapter']['hash'];
    final filenames = List<String>.from(response.data['chapter']['data']);

    return filenames.map((file) => '$baseUrl/data/$chapterHash/$file').toList();
  }

  @override
  String get baseUrl => "https://mangadex.org";

  @override
  String get sourceName => "MangaDex";

  @override
  String get sourceVersion => "v1.0";
}
