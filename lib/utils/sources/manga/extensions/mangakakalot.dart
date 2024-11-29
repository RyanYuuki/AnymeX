import 'dart:developer';
import 'package:anymex/utils/sources/manga/helper/jaro_helper.dart';
import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class MangaKakalot implements SourceBase {
  @override
  String get baseUrl => 'https://chapmanganato.to/';

  @override
  String get sourceName => 'MangaKakalot';

  @override
  String get sourceVersion => '1.0';

  @override
  Future<Map<String, dynamic>> fetchMangaChapters(String mangaId) async {
    final String url = '$baseUrl$mangaId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final target = document.querySelector('.story-info-right');

        if (target == null) {
          log('Error: Could not find the story-info-right element.');
          return {};
        }

        final String title = target.querySelector('h1')?.text.trim() ?? 'N/A';
        final chapterElements =
            document.querySelectorAll('.panel-story-chapter-list .a-h');
        final List<Map<String, dynamic>> chapterList =
            chapterElements.map((element) {
          final title =
              element.querySelector('.chapter-name')?.text.trim() ?? 'N/A';
          final path =
              element.querySelector('.chapter-name')?.attributes['href'] ?? '';
          final views =
              element.querySelector('.chapter-view')?.text.trim() ?? 'N/A';
          final updatedAt =
              element.querySelector('.chapter-time')?.text.trim() ?? 'N/A';
          final number = path.split('/').last.split('-').last;

          return {
            'id': path.split('/').last,
            'title': title,
            'path': path,
            'views': views,
            'date': updatedAt,
            'number': number,
          };
        }).toList();

        final metaData = {
          'id': mangaId,
          'title': title,
          'chapterList': chapterList.reversed.toList(),
        };

        log('Scraped Manga Info: ${metaData.toString()}');
        return metaData;
      } else {
        throw Exception(
            'Failed to load manga information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error occurred while scraping manga info: ${e.toString()}');
      return {};
    }
  }

  @override
  Future<dynamic> fetchMangaSearchResults(String query) async {
    final String formattedQuery = query.replaceAll(' ', '_');
    final url = 'https://mangakakalot.com/search/story/$formattedQuery';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final mangaList = <Map<String, String>>[];

      document.querySelectorAll('.story_item').forEach((element) {
        final titleElement = element.querySelector('.story_name > a');
        final title = titleElement?.text.trim();
        final link = titleElement?.attributes['href'];
        final image = element.querySelector('img')?.attributes['src'];

        final author = element
            .querySelectorAll('span')[0]
            .text
            .replaceAll('Author(s) : ', '')
            .trim();
        final updated = element
            .querySelectorAll('span')[1]
            .text
            .replaceAll('Updated : ', '')
            .trim();
        final views = element
            .querySelectorAll('span')[2]
            .text
            .replaceAll('View : ', '')
            .trim();

        mangaList.add({
          'id': (link?.split('/')[3])!,
          'title': title!,
          'link': link!,
          'image': image!,
          'author': author,
          'updated': updated,
          'views': views,
        });
      });
      log(mangaList.toString());
      return mangaList;
    } else {
      throw Exception('Failed to load manga search results');
    }
  }

  @override
  Future<dynamic> mapToAnilist(String query) async {
    final mangaList = await fetchMangaSearchResults(query);
    String bestMatchId = findBestMatch(query, mangaList);
    if (bestMatchId.isNotEmpty) {
      return await fetchMangaChapters(bestMatchId);
    } else {
      throw Exception('No suitable match found for the query');
    }
  }

  @override
  Future<dynamic> fetchChapterImages({
    required String mangaId,
    required String chapterId,
  }) async {
    final url = 'https://chapmanganato.to/$mangaId/$chapterId';
    log(url);
    int index = 0;

    try {
      final response = await http.get(Uri.parse(url),
          headers: {'Referer': 'https://chapmanganato.to/'});
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final target = document.querySelector('.navi-change-chapter');

        final title = document
            .querySelector('.panel-chapter-info-top h1')
            ?.text
            .toLowerCase()
            .split('chapter')
            .first
            .trim()
            .toUpperCase();

        final currentChapter =
            'Chapter${document.querySelector('.panel-chapter-info-top h1')?.text.toLowerCase().split('chapter').last.toUpperCase()}';

        final chapterListIds = target?.querySelectorAll('option').map((option) {
              return {
                'id': 'chapter-${option.attributes['data-c']}',
                'name': option.text.trim(),
              };
            }).toList() ??
            [];

        final images = await Future.wait(document
            .querySelectorAll('.container-chapter-reader img')
            .map((img) async {
          final imgUrl = img.attributes['src'] ?? '';
          index++;
          return {
            'title': img.attributes['title'] ?? '',
            'image': imgUrl,
          };
        }).toList());
        final chapterNavLink =
            document.querySelector('.navi-change-chapter-btn');
        final nextChapterLink = chapterNavLink
                ?.querySelector('.navi-change-chapter-btn-next')
                ?.attributes['href'] ??
            '';
        final prevChapterLink = chapterNavLink
                ?.querySelector('.navi-change-chapter-btn-prev')
                ?.attributes['href'] ??
            '';

        final assets = {
          'title': title,
          'currentChapter': currentChapter,
          'nextChapterId': nextChapterLink.split('/').last,
          'prevChapterId': prevChapterLink.split('/').last,
          'chapterListIds': chapterListIds,
          'images': images,
          'totalImages': index,
        };
        log(assets.toString());
        return assets;
      } else {
        log('Failed to load chapter details, status code: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      log('Error: $e');
    }
    return {};
  }
}
