import 'dart:developer';

import 'package:aurora/utils/sources/novel/base/source_base.dart';
import 'package:aurora/utils/sources/novel/extensions/novel_buddy.dart';
import 'package:aurora/utils/sources/novel/extensions/wuxia_click.dart';

class NovelSourcesHandler {
  final Map<String, NovelSourceBase> sourceMap = {
    "NovelBuddy": NovelBuddy(),
    "WuxiaClick": WuxiaClick(),
  };

  String? selectedSourceName;

  void setSelectedSource(String sourceName) {
    if (sourceMap.containsKey(sourceName)) {
      selectedSourceName = sourceName;
      log("Selected source set to $sourceName");
    } else {
      log("Source $sourceName does not exist in sourceMap");
    }
  }

  NovelSourceBase? get selectedSource {
    if (selectedSourceName == null) {
      return sourceMap['NovelBuddy'];
    }
    return sourceMap[selectedSourceName];
  }

  String getSelectedSourceName() {
    if (selectedSourceName == null) {
      return "NovelBuddy";
    }
    return selectedSourceName!;
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

  NovelSourceBase? _getSource([String? sourceName]) {
    return sourceName != null ? sourceMap[sourceName] : selectedSource;
  }

  Future<dynamic> fetchNovelWords(String url, String sourceName) async {
    final source = _getSource(sourceName);
    if (source != null) {
      return await source.scrapeNovelWords(url);
    } else {
      log("No source available or selected to fetch manga chapters");
    }
  }

  Future<dynamic> fetchNovelSearchResults(String query, sourceName) async {
    final source = _getSource(sourceName);
    if (source != null) {
      return await source.scrapeNovelSearchData(query);
    } else {
      log("No source available or selected to fetch search results");
    }
  }

  Future<dynamic> fetchNovelDetails({
    required String url,
    String? sourceName,
  }) async {
    final source = _getSource(sourceName);
    if (source != null) {
      return await source.scrapeNovelDetails(url);
    } else {
      log("No source available or selected to fetch chapter images");
    }
  }
}
