abstract class NovelSourceBase {
  String get sourceName;
  String get sourceVersion;
  String get baseUrl;

  Future<dynamic> scrapeNovelDetails(String url);
  Future<dynamic> scrapeNovelSearchData(String query);
  Future<dynamic> scrapeNovelWords(String url);
}