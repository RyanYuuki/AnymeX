import 'dart:developer';

import 'package:aurora/utils/sources/novel/base/source_base.dart';
import 'package:aurora/utils/sources/novel/extensions/novel_buddy.dart';
import 'package:aurora/utils/sources/novel/extensions/wuxia_click.dart';

class NovelSourcesHandler {
  final Map<String, NovelSourceBase> sourceMap = {
    "NovelBuddy": NovelBuddy(),
    "WuxiaClick": WuxiaClick(),
  };

  String selectedSourceName = "";

  NovelSourcesHandler() {
    selectedSourceName = getSelectedSource();
    log("Initialized with selected source: $selectedSourceName");
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

  void setSelectedSource(String sourceName) {
    if (sourceMap.containsKey(sourceName)) {
      selectedSourceName = sourceName;
      log("Selected source changed to $selectedSourceName");
    } else {
      log("Source $sourceName does not exist in sourceMap");
    }
  }

  String getSelectedSource() {
    log("getSelectedSource called, current selectedSourceName: $selectedSourceName");
    if (selectedSourceName.isNotEmpty) {
      return selectedSourceName;
    }
    log("Selected source name was empty. Defaulting to the first source.");
    return sourceMap.entries.first.key;
  }

  NovelSourceBase? _getSource() {
    log("_getSource called, using source: ${getSelectedSource()}");
    return sourceMap[getSelectedSource()];
  }

  Future<dynamic> fetchNovelWords(String url) async {
    final source = _getSource();
    if (source != null) {
      return await source.scrapeNovelWords(url);
    } else {
      log("No source available or selected to fetch novel words");
    }
  }

  Future<dynamic> fetchNovelSearchResults(String query) async {
    final source = _getSource();
    if (source != null) {
      return await source.scrapeNovelSearchData(query);
    } else {
      log("No source available or selected to fetch search results");
    }
  }

  Future<dynamic> fetchNovelDetails({
    required String url,
  }) async {
    final source = _getSource();
    if (source != null) {
      return await source.scrapeNovelDetails(url);
    } else {
      log("No source available or selected to fetch novel details");
    }
  }
}
