import 'package:algorithmic/algorithmic.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Search/search.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:get/get.dart';

Future<Media> mapMedia(List<String> animeId, RxString searchedTitle) async {
  final sourceController = Get.find<SourceController>();
  final isManga = animeId[0].split("*").last == "MANGA";
  final type = isManga ? MediaType.manga : MediaType.anime;
  final romajiTitle = animeId[1];
  final englishTitle = animeId[0].split("*").first;

  final activeSource = isManga
      ? sourceController.activeMangaSource.value
      : sourceController.activeSource.value;

  if (activeSource == null) {
    throw Exception("No active source found!");
  }

  double highestSimilarity = 0.0;
  String? bestMatch;
  List searchResults = [];

  Future<void> searchAndCompare(String query) async {
    final results = await search(
          source: activeSource,
          query: query,
          page: 1,
          filterList: [],
        ) ??
        [];
    if (results.isEmpty) return;

    for (final result in results) {
      final resultTitle = (result?.name ?? '').trim();
      final cleanedQuery = query.trim();
      searchedTitle.value = "Searching: $resultTitle";

      double similarity2 =
          jaroWinklerSimilarityOf(cleanedQuery, romajiTitle, threshold: 0.5);
      double similarity =
          jaroWinklerSimilarityOf(cleanedQuery, englishTitle, threshold: 0.5);
      if (similarity2 > similarity) {
        similarity = similarity2;
      }

      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatch = resultTitle;
        searchResults = results;
      }
    }
  }

  await searchAndCompare(romajiTitle);
  if (highestSimilarity < 0.98) {
    await searchAndCompare(englishTitle);
  }

  if (highestSimilarity >= 0.85 && bestMatch != null) {
    searchedTitle.value = bestMatch!;
    final matchingResult = searchResults.firstWhere(
      (result) => result.name == bestMatch,
      orElse: () => MManga(),
    );

    return Media.fromManga(matchingResult ?? MManga(), type);
  }

  searchedTitle.value =
      searchResults.isNotEmpty ? searchResults.first.name : "No match found";
  return searchResults.isNotEmpty
      ? Media.fromManga(searchResults.first, type)
      : Media();
}

// import 'dart:developer';

// import 'package:algorithmic/algorithmic.dart';
// import 'package:anymex/controllers/source/source_controller.dart';
// import 'package:anymex/core/Eval/dart/model/m_manga.dart';
// import 'package:anymex/core/Search/search.dart';
// import 'package:anymex/models/Media/media.dart';
// import 'package:get/get.dart';

// Future<Media> mapMedia(List<String> animeId, RxString searchedTitle) async {
//   final sourceController = Get.find<SourceController>();
//   final isManga = animeId[0].split("*").last == "MANGA";
//   final type = isManga ? MediaType.manga : MediaType.anime;
//   final romajiTitle = animeId[1];
//   final englishTitle = animeId[0].split("*").first;

//   final activeSource = isManga
//       ? sourceController.activeMangaSource.value
//       : sourceController.activeSource.value;

//   if (activeSource == null) {
//     throw Exception("No active extension found!");
//   }

//   double highestSimilarity = 0.0;
//   String? bestMatch;
//   List searchResults = [];

//   Future<void> searchAndCompare(String query) async {
//     searchedTitle.value = "Searching: $query";

//     final results = await search(
//           source: activeSource,
//           query: query,
//           page: 1,
//           filterList: [],
//         ) ??
//         [];
//     if (results.isEmpty) return;

//     for (final result in results) {
//       final resultTitle = (result?.name ?? '').trim();
//       final cleanedQuery = query.trim();
//       final similarity =
//           jaroWinklerSimilarityOf(cleanedQuery, resultTitle, threshold: 0.5);

//       if (similarity > highestSimilarity) {
//         highestSimilarity = similarity;
//         bestMatch = resultTitle;
//         searchResults = results;
//       }
//     }
//   }

//   await searchAndCompare(romajiTitle);
//   if (highestSimilarity < 0.85) {
//     await searchAndCompare(englishTitle);
//   }

//   if (highestSimilarity >= 0.85 && bestMatch != null) {
//     final matchingResult = searchResults.firstWhere(
//       (result) => result.name == bestMatch,
//       orElse: () => MManga(),
//     );

//     return Media.fromManga(matchingResult ?? MManga(), type);
//   }
//   return searchResults.isNotEmpty
//       ? Media.fromManga(searchResults.first, type)
//       : Media();
// }
