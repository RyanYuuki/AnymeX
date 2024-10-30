abstract class SourceBase {
  String get sourceName;
  String get sourceVersion;
  String get baseUrl;

  Future<dynamic> fetchMangaChapters(String id);
  Future<dynamic> fetchMangaSearchResults(String query);
  Future<dynamic> fetchChapterImages(
      {required String mangaId, required String chapterId});
  Future<dynamic> mapToAnilist(String query);
}