import 'dart:developer';
import 'package:anymex/utils/sources/manga/extensions/comick.dart';
import 'package:anymex/utils/sources/manga/extensions/mangabat.dart';
import 'package:anymex/utils/sources/manga/extensions/mangafire.dart';
import 'package:anymex/utils/sources/manga/extensions/mangakakalot.dart';
import 'package:anymex/utils/sources/manga/extensions/mangakakalot_unofficial.dart';
import 'package:anymex/utils/sources/manga/extensions/manganato.dart';
import 'package:hive/hive.dart';
import '../base/source_base.dart';

class MangaSourceHandler {
  final Map<String, SourceBase> sourceMap = {
    "MangaKakalotUnofficial": MangaKakalotUnofficial(),
    "MangaKakalot": MangaKakalot(),
    "MangaBat": MangaBat(),
    "MangaNato": MangaNato(),
    "ComicK": Comick(),
    "MangaFire": MangaFire(),
  };

  String? selectedSourceName = "";
  int? sourceIndex;

  MangaSourceHandler() {
    sourceIndex = Hive.box('app-data').get('mangaSourceIndex', defaultValue: 4);
    selectedSourceName = sourceMap.entries.elementAt(sourceIndex!).key;
  }

  void setSelectedSource(String sourceName) {
    if (sourceMap.containsKey(sourceName)) {
      selectedSourceName = sourceName;
      int index = sourceMap.keys.toList().indexOf(sourceName);
      Hive.box('app-data').put('mangaSourceIndex', index);
      sourceIndex = index;
    } else {
      log("Source $sourceName does not exist in sourceMap");
    }
  }

  List<Map<String, String>> getAvailableSources() {
    return sourceMap.entries.map((entry) {
      final source = entry.value;
      return {
        "name": source.sourceName,
        "version": source.sourceVersion,
        "baseUrl": source.baseUrl,
      };
    }).toList();
  }

  SourceBase? _getSource([String? sourceName]) {
    return sourceMap[sourceName];
  }

  Future<dynamic> fetchMangaChapters(String mangaId) async {
    final source = _getSource(selectedSourceName);
    if (source != null) {
      return await source.fetchMangaChapters(mangaId);
    } else {
      log("No source available or selected to fetch manga chapters");
    }
  }

  Future<dynamic> fetchMangaSearchResults(String query) async {
    final source = _getSource(selectedSourceName);
    if (source != null) {
      return await source.fetchMangaSearchResults(query);
    } else {
      log("No source available or selected to fetch search results");
    }
  }

  Future<dynamic> fetchChapterImages({
    required String mangaId,
    required String chapterId,
  }) async {
    final source = _getSource(selectedSourceName);
    if (source != null) {
      return await source.fetchChapterImages(
          mangaId: mangaId, chapterId: chapterId);
    } else {
      log("No source available or selected to fetch chapter images");
    }
  }

  Future<dynamic> mapToAnilist(String query) async {
    final source = _getSource(selectedSourceName);
    if (source != null) {
      return await source.mapToAnilist(query);
    } else {
      log("No source available or selected to fetch chapter images");
    }
  }
}
