import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';

abstract class SourceBase {
  String get sourceName;
  bool get isMulti;
  Future<dynamic> scrapeSearchResults(String query) async {}
  Future<dynamic> scrapeEpisodes(String url, {dynamic args}) async {}
  Future<dynamic> scrapeEpisodesSrcs(String episodeId,
      {AnimeServers? server, String? category, String? lang}) async {}
}
