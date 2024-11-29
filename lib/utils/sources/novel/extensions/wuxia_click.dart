import 'dart:developer';

import 'package:anymex/utils/sources/novel/base/source_base.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class WuxiaClick implements NovelSourceBase {
  @override
  final baseUrl = 'https://wuxia.click';

  Future<dynamic> scrapeHomePageData() async {
    const url = 'https://wuxia.click/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parse(response.body);

      List<Map<String, dynamic>> novels = [];
      var items =
          document.getElementsByClassName('mantine-Grid-col mantine-c2tp9s');
      for (var item in items) {
        var link = item.querySelector('a')?.attributes['href']?.trim();
        var titleElement =
            item.querySelector('.mantine-Text-root.mantine-pdrfb7');
        var title = titleElement?.text.trim() ?? '';

        var imageElement = item.querySelector('img.mantine-Image-image');
        var imageUrl = imageElement?.attributes['src'] ?? '';

        var ratingElement = item.querySelector(
            '.mantine-Badge-root.mantine-807m0k .mantine-Badge-inner');
        var rating = ratingElement?.text.trim().split(' ').last ?? '';

        var rankElement = item.querySelector(
            '.mantine-Badge-root.mantine-1s2uyct .mantine-Badge-inner');
        var rank = rankElement?.text.trim().split(' ').last ?? '';

        var viewsElement =
            item.querySelector('.mantine-Text-root.mantine-w7z63c');
        var views = viewsElement?.text.trim().split(' ').last ?? '';

        var chaptersElement =
            item.querySelector('.mantine-Text-root.mantine-175mpop');
        var chapters = chaptersElement?.text.trim().split(' ').last ?? '';

        if (imageUrl.isNotEmpty) {
          novels.add({
            'id': baseUrl + link!,
            'title': title,
            'image': imageUrl.replaceFirst('70', '100'),
            'rating': (double.parse(rating) * 2).toString(),
            'rank': rank,
            'views': views,
            'chapters': chapters,
          });
        }
      }
      return novels;
    }
  }

  @override
  Future<dynamic> scrapeNovelDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    int index = 0;
    if (response.statusCode == 200) {
      var document = parse(response.body);

      dynamic novelDetailsList;
      var titleElement = document.querySelector(
          '.mantine-Text-root.mantine-Title-root.mantine-1ra9ysm');
      var title = titleElement?.text.trim() ?? '';
      var authorElement =
          document.querySelector('.mantine-Text-root.mantine-ss2azu');
      var author = authorElement?.text.trim() ?? '';
      var statusElement =
          document.querySelector('.mantine-Text-root.mantine-1huvzos');
      var status = statusElement?.text.trim() ?? '';
      var viewsElement = document
          .querySelector('.mantine-Text-root.mantine-1huvzos:nth-child(1)');
      var views = viewsElement?.text.trim().split(' ').first ?? '';
      var chaptersElement = document
          .querySelector(
              '.mantine-Paper-root.mantine-Card-root.mantine-1x5ubwi > .mantine-Group-root.mantine-1emc9ft')
          ?.children[0];
      var chaptersCount = chaptersElement?.text.trim().split(' ').first ?? '';
      var ratingElement = document
          .querySelector('.mantine-Text-root.mantine-19n0k2t:nth-child(1)');
      var rating =
          ratingElement?.text.trim().split(' ').first.substring(1, 5) ?? '';
      var reviewsElement = document
          .querySelector('.mantine-Text-root.mantine-19n0k2t:nth-child(2)');
      var reviews =
          reviewsElement?.text.trim().trimLeft().split(' ').first ?? '';
      var imageElement = document.querySelector('img.mantine-Image-image');
      var imageUrl = imageElement?.attributes['src'] ?? '';
      var descriptionElement =
          document.querySelector('.mantine-Text-root.mantine-tpna8b');
      var description = descriptionElement?.text.trim() ?? '';
      List<Map<String, dynamic>> chapterList = [];

      for (int i = 1; i <= int.parse(chaptersCount); i++) {
        chapterList.add({
          'id': '${url.replaceAll('novel', 'chapter')}-$i',
          'title': 'Chapter $i',
        });
      }

      chapterList = chapterList.reversed.toList();
      for (int i = 0; i < chapterList.length; i++) {
        chapterList[i]['number'] = i + 1;
      }

      novelDetailsList = {
        'id': url,
        'title': title,
        'author': author,
        'status': status,
        'views': views,
        'chapters': chaptersCount,
        'rating': (double.parse(rating) * 2).toString(),
        'reviews': reviews,
        'image': imageUrl,
        'description': description,
        'chapterList': chapterList,
      };
      return novelDetailsList;
    } else {
      log('Failed to load page: ${response.statusCode}');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> scrapeNovelWords(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parse(response.body);
      String? title = document
          .querySelector('.mantine-Text-root.mantine-Title-root.mantine-3i9n9a')
          ?.text;
      var previousChapterElement = document.querySelector('#previousChapter');
      var previousChapterLink =
          previousChapterElement?.parent?.parent?.attributes['href'];

      if (previousChapterLink != null &&
          previousChapterLink.contains('novel')) {
        previousChapterLink = '';
      } else {
        previousChapterLink = '$baseUrl$previousChapterLink';
      }

      var nextChapterElement = document.querySelector('#nextChapter');
      var nextChapterLink =
          nextChapterElement?.parent?.parent?.attributes['href'];

      if (nextChapterLink != null) {
        var lastPart = nextChapterLink.split('-').last;
        if (int.tryParse(lastPart) == null) {
          nextChapterLink = '';
        } else {
          nextChapterLink =
              '$baseUrl${nextChapterElement?.parent?.parent?.attributes['href']}';
        }
      }
      var currentChapter = document
          .querySelector(
              'h1.mantine-Text-root.mantine-Title-root.mantine-3i9n9a')
          ?.text;
      var wordElements =
          document.querySelectorAll('.mantine-Text-root#chapterText');
      List<String> words = [];
      for (var element in wordElements) {
        var textContent = element.text.trim();
        words.add(textContent);
      }

      final novelData = {
        'title': title,
        'chapterTitle': currentChapter ?? 'Chapter ?',
        'prevChapterId': previousChapterLink ?? '',
        'nextChapterId': nextChapterLink ?? '',
        'words': words,
      };

      log(novelData.toString());

      return novelData;
    } else {
      print('Failed to load page: ${response.statusCode}');
      return {};
    }
  }

  @override
  Future<dynamic> scrapeNovelSearchData(String query) async {
    final formattedQuery = query.replaceAll(' ', '%20');
    final url = 'https://wuxia.click/search/$formattedQuery?page=1&order_by=';

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36'
    });

    final document = parse(response.body);

    List<Map<String, String>> scrapedData = [];

    final novelContainers =
        document.getElementsByClassName('mantine-Grid-col mantine-c2tp9s');

    for (var container in novelContainers) {
      final title = container
              .querySelector('.mantine-Text-root.mantine-pdrfb7')
              ?.text
              .trim() ??
          'N/A';
      final imageUrl = container
              .querySelector('img.mantine-fp9t1o.mantine-Image-image')
              ?.attributes['src'] ??
          'N/A';
      final rating = container
              .querySelector(
                  '.mantine-Badge-root.mantine-807m0k .mantine-1t45alw.mantine-Badge-inner')
              ?.text
              .trim()
              .split(':')
              .last
              .substring(2, 6) ??
          'N/A';
      final rank = container
              .querySelector(
                  '.mantine-Badge-root.mantine-1s2uyct .mantine-1t45alw.mantine-Badge-inner')
              ?.text
              .trim()
              .split(':')
              .last
              .trim() ??
          'N/A';
      final views = container
              .querySelector('.mantine-Text-root.mantine-w7z63c')
              ?.text
              .replaceAll('👁️ Views: ', '')
              .trim() ??
          'N/A';
      final chapters = container
              .querySelector('.mantine-Text-root.mantine-175mpop')
              ?.text
              .replaceAll('🔢 Chapters: ', '')
              .trim() ??
          'N/A';
      final link = container.querySelector('a')?.attributes['href'];

      Map<String, String> data = {
        'id': '$baseUrl$link',
        'title': title,
        'image':
            (imageUrl.isEmpty) ? 'https://placehold.co/200x250.png' : imageUrl,
        'rating': (double.parse(rating) * 2).toString(),
        'rank': rank,
        'views': views,
        'chapters': chapters
      };

      scrapedData.add(data);
    }

    return scrapedData;
  }

  @override
  String get sourceName => 'WuxiaClick';

  @override
  String get sourceVersion => 'v1.0';
}
