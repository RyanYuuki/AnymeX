import 'dart:developer';

import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

class Asurascans implements SourceBase {
  Dio dio = Dio();
  @override
  String get baseUrl => "https://asuracomic.net";

  @override
  Future fetchChapterImages(
      {required String mangaId, required String chapterId}) async {
    var resp = await dio.get(chapterId);
    if (resp.statusCode == 200) {
      var document = parse(resp.data);
      var temp = document.querySelector('h2')!.text.split('Chapter');
      var title = temp[0].trim();
      var currentChapter = 'Chapter ${temp[1].trim()}';
      var images = document.querySelectorAll("div.w-full.mx-auto.center > img").map((el) {
        return {'img': el.attributes['src']};
      }).toList();
      log(images.toString());
    }
  }

  @override
  Future fetchMangaChapters(String id) async {
    var resp = await dio.get(id);
    if (resp.statusCode == 200) {
      var document = parse(resp.data);
      var title = document.querySelector('.text-xl.font-bold')?.text;
      final chapterListEls = document
          .querySelectorAll(".overflow-y-auto.scrollbar-thumb-themecolor div");
      var chapterList = [];
      for (var chapter in chapterListEls) {
        var id = chapter.querySelector('a')?.attributes['href'];
        var title = chapter.querySelector("a")?.text;
        chapterList.add({'id': '$baseUrl/series/$id', "title": title});
      }
      final newChapterList =
          chapterList.where((element) => element['title'] != null).toList();
      final fullData = {"title": title, "chapterList": newChapterList};
      log(fullData.toString());
      return fullData;
    }
  }

  @override
  Future fetchMangaSearchResults(String query) async {
    var url = '$baseUrl/series?page=1&name=$query';
    var resp = await dio.get(url);
    if (resp.statusCode == 200) {
      var document = parse(resp.data);
      var comicItems =
          document.querySelectorAll(".grid.grid-cols-2.gap-3.p-4 a");
      var searchData = [];

      for (var item in comicItems) {
        searchData.add({
          "id": '$baseUrl/${item.attributes['href']}',
          "title": item.querySelectorAll('.font-bold')[1].text.trim(),
          "image": item.querySelector('img')?.attributes['src']
        });
      }
      return searchData;
    } else {
      log("Fetch Failed");
    }
  }

  @override
  String get sourceName => "AsuraScans";

  @override
  String get sourceVersion => "v1.0";
}
