import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:aurora/utils/sources/novel/base/source_base.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class NovelBuddy implements NovelSourceBase {
  @override
  final baseUrl = 'https://novelbuddy.com';

  Future<dynamic> scrapeNovelsHomePage() async {
    String url = 'https://novelbuddy.com/popular?status=completed';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Document document = parse(response.body);
        List<Map<String, dynamic>> novelsData = [];

        var novelItems = document.querySelectorAll('.book-item');

        for (var novelItem in novelItems) {
          var link = novelItem.querySelector('h3 a')?.attributes['href'];
          var title = novelItem.querySelector('h3 a')?.text ?? 'No title';
          novelItem.querySelector('.rating .score i')?.remove();
          var rating =
              novelItem.querySelector('.rating .score')?.text ?? 'No rating';
          var summary =
              novelItem.querySelector('.summary p')?.text ?? 'No summary';
          var image =
              novelItem.querySelector('.thumb a img')?.attributes['data-src'];

          Map<String, dynamic> novelData = {
            'id': 'https://novelbuddy.com$link',
            'title': title,
            'image': 'https:$image',
            'description': summary,
            'rating': (double.parse(rating) * 2).toString(),
          };
          novelsData.add(novelData);
        }
        log(novelsData.toString());
        return novelsData;
      } else {
        log('Failed to load the page, status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> scrapeNovelDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    dynamic novelData = [];
    if (response.statusCode == 200) {
      final document = parse(response.body);

      final title =
          document.querySelector('.detail .name h1')?.text.trim() ?? '';
      final alternativeTitle =
          document.querySelector('.detail .name h2')?.text.trim() ?? '';
      final coverImage = document
              .querySelector('#cover .img-cover img')
              ?.attributes['data-src'] ??
          '';
      final metaElements = document.querySelector('.meta')?.children ?? [];
      final authors = metaElements.isNotEmpty
          ? metaElements[0]
              .querySelectorAll('a span')
              .map((e) => e.text.trim())
              .toList()
          : [];
      final status = metaElements.length > 1
          ? metaElements[1].querySelector('a span')?.text.trim() ?? ''
          : '';
      final genres = metaElements.length > 2
          ? metaElements[2]
              .querySelectorAll('a')
              .map((e) => e.text.trim().replaceAll(',', '').trimRight())
              .toSet()
              .toList()
          : [];
      final chapters = metaElements.length > 3
          ? metaElements[3].querySelector('span')?.text.trim() ?? ''
          : '';
      final lastUpdate = metaElements.length > 4
          ? metaElements[4].querySelector('span')?.text.trim() ?? ''
          : '';
      var description =
          document.querySelector('.section-body.summary p')?.text.trim();

      final ratingElement = document.querySelector('.rating .score');
      final rating = ratingElement != null
          ? ratingElement.text.trim() == ''
              ? '??'
              : ratingElement.text.trim()
          : '??';

      var novelId = document.querySelector('.layout script')?.text;
      final bookIdMatch = RegExp(r'var bookId = (\d+);').firstMatch(novelId!);
      final bookId =
          bookIdMatch != null ? int.parse(bookIdMatch.group(1)!) : null;
      final newResp = await http.get(Uri.parse(
          'https://novelbuddy.com/api/manga/$bookId/chapters?source=detail'));
      if (newResp.statusCode == 200) {
        final pageContent = parse(newResp.body);
        var chapterListElements = pageContent.querySelectorAll('li');
        List<Map<String, dynamic>> chapterList = [];

        for (var chapter in chapterListElements) {
          final String? href = chapter.querySelector('a')?.attributes['href'];
          final String? title = chapter.querySelector('a')?.attributes['title'];

          if (href != null) {
            chapterList.add({
              'id': '$baseUrl$href',
              'title': title ?? 'Untitled Chapter',
            });
          }
        }

        chapterList = chapterList.reversed.toList();
        for (int i = 0; i < chapterList.length; i++) {
          chapterList[i]['number'] = i + 1;
        }

        novelData = {
          'id': url,
          'title': title,
          'alternativeTitle': alternativeTitle,
          'coverImage': 'https:$coverImage',
          'description': description,
          'authors': authors,
          'status': status,
          'genres': genres,
          'chapters': chapters,
          'lastUpdate': lastUpdate,
          'rating': rating,
          'chapterList': chapterList,
        };
      }

      return novelData;
    } else {
      throw Exception("Failed to load novel details");
    }
  }

  @override
  Future<Map<String, dynamic>> scrapeNovelWords(String url) async {
    final resp = await http.get(Uri.parse(url));

    if (resp.statusCode == 200) {
      Document document = parse(resp.body);
      var title =
          document.querySelector('.chapter-info a')?.attributes['title'];
      var chapterTitle = document.querySelector('#chapter__content h1')?.text;
      var prevChapterLink =
          document.querySelector('#btn-prev')?.attributes['href'] == '#'
              ? ''
              : document.querySelector('#btn-prev')?.attributes['href'];
      var nextChapterLink =
          document.querySelector('#btn-next')?.attributes['href'] == '#'
              ? ''
              : document.querySelector('#btn-next')?.attributes['href'];
      var wordsEl =
          document.querySelectorAll('#chapter__content .content-inner p');
      final words = [];
      for (var word in wordsEl) {
        words.add(word.text.trim());
      }
      final data = {
        'title': title,
        'chapterTitle': chapterTitle?.split('-').last,
        'nextChapterId':
            nextChapterLink == '' ? '' : baseUrl + nextChapterLink!,
        'prevChapterId':
            prevChapterLink == '' ? '' : baseUrl + prevChapterLink!,
        'words': words
      };
      return data;
    }
    return {};
  }

  @override
  Future<dynamic> scrapeNovelSearchData(String query) async {
    String url = 'https://novelbuddy.com/search?q=$query';

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Document document = parse(response.body);
        List<Map<String, String>> novelsData = [];

        var novelItems = document.querySelectorAll('.book-item');

        for (var novelItem in novelItems) {
          var link = novelItem.querySelector('h3 a')?.attributes['href'];
          var title = novelItem.querySelector('h3 a')?.text ?? 'No title';
          novelItem.querySelector('.rating .score i')?.remove();
          var rating =
              novelItem.querySelector('.rating .score')?.text ?? 'No rating';
          var summary =
              novelItem.querySelector('.summary p')?.text ?? 'No summary';
          var image =
              novelItem.querySelector('.thumb a img')?.attributes['data-src'];
          var views = novelItem.querySelector('.views span')?.text.trim();

          Map<String, String> novelData = {
            'id': 'https://novelbuddy.com$link',
            'title': title,
            'image': 'https:$image',
            'description': summary,
            'rating': (double.parse(rating) * 2).toString(),
            'views': views ?? '??'
          };
          novelsData.add(novelData);
        }
        return novelsData;
      } else {
        log('Failed to load the page, status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  @override
  String get sourceName => 'NovelBuddy';

  @override
  String get sourceVersion => 'v1.0';
}
