import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> searchManga(String query) async {
  final url = Uri.parse(
      "https://api.comick.fun/v1.0/search?q=${Uri.encodeComponent(query)}&limit=25&page=1");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Map<String, dynamic>> results = [];

    for (var item in data) {
      results.add({
        'id': item['slug'],
        'title': item['title'] ?? item['slug'],
        'link': "${item['slug']}",
        'image': item['md_covers'] != null && item['md_covers'].isNotEmpty
            ? "https://meo.comick.pictures/${item['md_covers'][0]['b2key']}"
            : null,
        'rating': item['rating'] ?? 0,
        'author': item['author'] ?? "Unknown",
        'updatedAt': item['created_at'] ?? "",
        'views': item['view_count'] ?? 0,
      });
    }
    log(results.toString());
    return results;
  } else {
    throw Exception("Failed to load manga search results");
  }
}

Future<Map<String, dynamic>> fetchMangaDetails(String mangaId) async {
  final url = Uri.parse("https://api.comick.fun/comic/$mangaId");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body)['comic'];

    List<Map<String, dynamic>> chapterList = [];
    for (var chapter in data['chapters']) {
      chapterList.add({
        'id': chapter['hid'] ?? "",
        'title': chapter['title'] ?? "Unknown",
        'path': "/comic/$mangaId/chapter/${chapter['hid']}",
        'views': chapter['view_count'] ?? 0,
        'date': chapter['updated_at'] ?? "",
        'number': chapter['chap'] ?? 0,
      });
    }

    return {
      'id': mangaId,
      'title': data['title'] ?? "Unknown",
      'chapterList': chapterList.reversed.toList(),
    };
  } else {
    throw Exception("Failed to load manga details");
  }
}

Future<Map<String, dynamic>> fetchChapterImages(String chapterId) async {
  final url = Uri.parse("https://api.comick.fun/chapter/$chapterId");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body)['chapter'];
    List<String> images = [];

    for (var img in data['md_images']) {
      images.add("https://meo.comick.pictures/${img['b2key']}");
    }

    return {
      'title': data['title'] ?? "Unknown",
      'currentChapter': chapterId,
      'nextChapterId': data['next_chapter_id'] ?? "",
      'prevChapterId': data['prev_chapter_id'] ?? "",
      'chapterListIds': data['chapter_list_ids'] ?? [],
      'images': images,
      'totalImages': images.length,
    };
  } else {
    throw Exception("Failed to load chapter images");
  }
}
