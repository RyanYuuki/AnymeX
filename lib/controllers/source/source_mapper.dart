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
  String romajiTitle = animeId[1];
  String englishTitle = animeId[0].split("*").first;

  // Normalize titles: remove non-alphanumeric characters and trim whitespace
  String normalize(String title) {
    return title.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim().toLowerCase();
  }

  // If romajiTitle is '??', use englishTitle
  if (romajiTitle == '??') {
    romajiTitle = englishTitle;
  }

  // Normalize both titles
  romajiTitle = normalize(romajiTitle);
  englishTitle = normalize(englishTitle);

  // Get the active source based on media type
  final activeSource = isManga
      ? sourceController.activeMangaSource.value
      : sourceController.activeSource.value;

  if (activeSource == null) {
    throw Exception("No active source found!");
  }

  double highestSimilarity = 0;
  String? bestMatch;
  List searchResults = [];

  // Function to search and compare titles
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
      final resultTitle = normalize((result?.name ?? '').trim());
      final cleanedQuery = normalize(query.trim());
      searchedTitle.value = "Searching: $resultTitle";
      print("Matching '$resultTitle' with '$cleanedQuery'");

      // Exact match check
      if (resultTitle == cleanedQuery) {
        highestSimilarity = 1.0; // Perfect match
        bestMatch = resultTitle;
        searchResults = results;
        return; // Exit early for perfect match
      }

      // Calculate similarity scores
      double similarityRomaji =
          jaroWinklerSimilarityOf(cleanedQuery, romajiTitle);
      double similarityEnglish =
          jaroWinklerSimilarityOf(cleanedQuery, englishTitle);
      double similarity = similarityRomaji > similarityEnglish
          ? similarityRomaji
          : similarityEnglish;

      // Debug similarity score
      print("Similarity: $similarity for '$resultTitle'");

      // Update best match if this result has a higher similarity
      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatch = resultTitle;
        searchResults = results;
      }
    }
  }

  // First search using englishTitle
  await searchAndCompare(englishTitle);

  // If no perfect match was found, try searching with romajiTitle
  if (highestSimilarity < 1) {
    await searchAndCompare(romajiTitle);
  }

  // If we found a match with high enough similarity, return it
  if (highestSimilarity >= 0.95 && bestMatch != null) {
    searchedTitle.value = bestMatch!.toUpperCase();
    final matchingResult = searchResults.firstWhere(
      (result) => normalize(result.name) == bestMatch,
      orElse: () => MManga(),
    );
    return Media.fromManga(matchingResult ?? MManga(), type);
  }

  // If no good match was found, return the first result or an empty Media object
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
