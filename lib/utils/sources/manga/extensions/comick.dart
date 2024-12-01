import 'dart:convert';
import 'dart:developer';
import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:anymex/utils/sources/manga/helper/jaro_helper.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class Comick implements SourceBase {
  @override
  Future<List<Map<String, dynamic>>> fetchMangaSearchResults(
      String query) async {
    final url = Uri.parse(
        "https://api.comick.fun/v1.0/search?q=${Uri.encodeComponent(query)}&limit=25&page=1");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, String>> results = [];

      for (var item in data) {
        results.add({
          'id': item['slug'],
          'title': item['title'] ?? item['slug'],
          'link': "${item['slug']}",
          'image': item['md_covers'] != null && item['md_covers'].isNotEmpty
              ? "https://meo.comick.pictures/${item['md_covers'][0]['b2key']}"
              : '',
          'rating': item['rating']?.toString() ?? '0.0',
          'author': item['author'] ?? "Unknown",
          'updatedAt': item['created_at']?.toString() ?? "",
          'views': item['view_count']?.toString() ?? '0.0',
        });
      }
      log(results.toString());
      return results;
    } else {
      throw Exception("Failed to load manga search results");
    }
  }

  Future<Map<String, String>> getComicId(String comickId) async {
    Dio dio = Dio();
    try {
      final resp = await dio.get('https://api.comick.fun/comic/$comickId');
      final data = resp.data;
      var id = data['comic']['hid'];
      var title = data['comic']['title'];
      return {'id': id, 'title': title ?? '?'};
    } catch (e) {
      log('Error fetching comic data: $e');
      return {};
    }
  }

  List<String> addScanGroup(List<String> group, String groupName) {
    bool isAvailable = group.any((entry) => entry == groupName);
    if (isAvailable) {
      return group;
    } else {
      group.add(groupName);
      return group;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchMangaChapters(String mangaId) async {
    Map<String, String> id = await getComicId(mangaId);

    final url = Uri.parse(
        "https://api.comick.fun/comic/${id['id']}/chapters?lang=en&page=0&limit=1000000");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<Map<String, dynamic>> chapterList = [];
      List<String> groupNames = [];

      for (var chapter in data['chapters']) {
        var chapterTitle = chapter?['title'] != null
            ? 'Chapter ${chapter['chap'] ?? '?'}: ${chapter['title']}'
            : 'Chapter ${chapter['chap'] ?? '?'}';
        chapterTitle = chapterTitle == 'Chapter ?' && chapter['vol'] != null
            ? 'Volume ${chapter['vol']}'
            : chapterTitle;
        bool credible =
            chapter['chap'] != null && chapter['group_name'] != null;

        if (credible) {
          String formattedGroup = chapter['group_name']
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '');
          final chapterData = {
            'id': chapter['hid'] ?? "",
            'title': chapterTitle,
            'path': "/comic/$mangaId/chapter/${chapter['hid']}",
            'views': chapter['up_count']?.toString() ?? '0.0',
            'date': formattedGroup,
            'number': chapter['chap']?.toString() ?? '0',
          };
          addScanGroup(groupNames, formattedGroup);
          chapterList.add(chapterData);
        }
      }

      List<String> filteredGroups =
          groupNames.where((group) => group != 'null' && group != '').toList();

      final manga = {
        'id': mangaId,
        'title': id['title'] ?? '??',
        'chapterList': chapterList.reversed.toList(),
        'groups': filteredGroups,
        'hasGroups': filteredGroups.isNotEmpty,
      };
      return manga;
    } else {
      throw Exception("Failed to load manga details");
    }
  }

  @override
  Future<Map<String, dynamic>> fetchChapterImages(
      {String? chapterId, String? mangaId}) async {
    final url = Uri.parse("https://api.comick.fun/chapter/$chapterId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = jsonDecode(response.body);
      final data = document['chapter'];
      List<Map<String, String>> images = [];

      for (var img in data['md_images']) {
        images.add({'image': "https://meo.comick.pictures/${img['b2key']}"});
      }
      final mangaData = {
        'title': data?['md_comics']?['title'] ?? "Unknown",
        'currentChapter': 'Chapter ${data['chap']}',
        'nextChapterId': document?['next']?['hid'] ?? "",
        'prevChapterId': document?['prev']?['hid'] ?? "",
        'chapterListIds': document?['chapters'] ?? [],
        'images': images,
        'totalImages': images.length,
      };
      return mangaData;
    } else {
      throw Exception("Failed to load chapter images");
    }
  }

  @override
  String get baseUrl => 'https://comick.io/';

  @override
  Future<dynamic> mapToAnilist(String id, {int page = 1}) async {
    final mangaList = await fetchMangaSearchResults(id);
    String bestMatchId = findBestMatch(id, mangaList);
    if (bestMatchId.isNotEmpty) {
      return await fetchMangaChapters(bestMatchId);
    } else {
      throw Exception('No suitable match found for the query');
    }
  }

  @override
  String get sourceName => 'ComicK';

  @override
  String get sourceVersion => '1.0';
}
