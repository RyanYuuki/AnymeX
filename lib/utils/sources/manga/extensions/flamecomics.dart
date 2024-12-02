import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';

class FlameComics implements SourceBase {
  Dio dio = Dio();
  @override
  String get baseUrl => "https://flamecomics.xyz";

  @override
  Future fetchChapterImages(
      {required String mangaId, required String chapterId}) {
    throw "Not yet avail";
  }

  @override
  Future fetchMangaChapters(String id) {
    throw "Not yet avail";
  }

  @override
  Future fetchMangaSearchResults(String query) async {
    var url = 'https://flamecomics.xyz/browse?search=$query';
    var resp = await dio.get(url);
    if(resp.statusCode == 200) {
      var document = parse(resp.data);
      var comicItems = document.querySelectorAll("");
    }
  }

  @override
  String get sourceName => "FlameComics";

  @override
  String get sourceVersion => "v1.0";
}
