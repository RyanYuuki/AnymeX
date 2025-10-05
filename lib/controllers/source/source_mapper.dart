import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:get/get.dart';

String _normalizeLight(String title) {
  return title.trim().toLowerCase();
}

String _normalizeHeavy(String title) {
  String normalized =
      title.replaceAll(RegExp(r'\bseason\s*', caseSensitive: false), '');

  normalized =
      normalized.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim().toLowerCase();
  return normalized;
}

int? _extractSeasonNumber(String title) {
  final patterns = [
    RegExp(r'\b(\d+)(?:th|st|nd|rd)?\s*season\b', caseSensitive: false),
    RegExp(r'\bseason\s*(\d+)\b', caseSensitive: false),
    RegExp(r'\s(\d+)\b(?!\s*[a-zA-Z])'),
    RegExp(r'\b(\d+)(nd|rd|th|st)\b'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(title);
    if (match != null && match.group(1) != null) {
      return int.tryParse(match.group(1)!);
    }
  }
  return null;
}

double _calculateMatchScore(
  String sourceTitle,
  String targetTitle,
  int? sourceSeason,
  int? targetSeason,
) {
  if (sourceTitle.isEmpty) return 0.0;

  final tst = tokenSetRatio(sourceTitle, targetTitle) / 100.0;
  final pr = partialRatio(sourceTitle, targetTitle) / 100.0;
  final r = ratio(sourceTitle, targetTitle) / 100.0;

  double score = (tst * 0.4) + (pr * 0.3) + (r * 0.3);

  if (targetSeason != null && sourceSeason != null) {
    score += (targetSeason == sourceSeason) ? 0.3 : -0.1;
  }

  return score.clamp(0.0, 1.0);
}

Future<Media?> mapMedia(
  List<String> animeId,
  RxString searchedTitle, {
  String? savedTitle,
}) async {
  final sourceController = Get.find<SourceController>();
  final isManga = animeId[0].split("*").last == "MANGA";
  final type = isManga ? ItemType.manga : ItemType.anime;

  String englishTitle = animeId[0].split("*").first;
  String romajiTitle = animeId[1] == '??' ? englishTitle : animeId[1];

  final activeSource = isManga
      ? sourceController.activeMangaSource.value
      : sourceController.activeSource.value;

  if (activeSource == null) {
    Logger.i("No active source found!");
    return null;
  }

  double bestScore = 0;
  dynamic bestMatch;
  List<DMedia> fallbackResults = [];

  Future<void> search(
      String query, String sourceTitle, bool isHeavyNormalized) async {
    searchedTitle.value = "Fetching results...";
    final results = (await activeSource.methods.search(query, 1, [])).list;
    if (results.isEmpty) return;

    final sourceSeason = _extractSeasonNumber(sourceTitle);

    for (final result in results) {
      final resultTitle = result.title ?? '';
      final normalizedResultTitle = isHeavyNormalized
          ? _normalizeHeavy(resultTitle.trim())
          : _normalizeLight(resultTitle.trim());

      searchedTitle.value = "Searching: $resultTitle";

      if (savedTitle != null &&
          _normalizeLight(resultTitle) == _normalizeLight(savedTitle)) {
        bestScore = 1.0;
        bestMatch = result;
        fallbackResults = results;
        print("Exact match with savedTitle: $resultTitle");
        return;
      }

      final resultSeason = _extractSeasonNumber(resultTitle);

      final score = _calculateMatchScore(
        isHeavyNormalized
            ? _normalizeHeavy(sourceTitle)
            : _normalizeLight(sourceTitle),
        normalizedResultTitle,
        sourceSeason,
        resultSeason,
      );

      print("Score: ${score.toStringAsFixed(3)} for '$resultTitle' "
          "(Heavy normalized: $isHeavyNormalized)");

      if (score >= 0.95) {
        bestScore = score;
        bestMatch = result;
        fallbackResults = results;
        print("Perfect match: $resultTitle");
        return;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = result;
        fallbackResults = results;
      }
    }
  }

  if (savedTitle != null && savedTitle.isNotEmpty) {
    await search(savedTitle, savedTitle, false);
    if (bestScore >= 1.0 && bestMatch != null) {
      searchedTitle.value = (bestMatch.title ?? '').toUpperCase();
      return Media.froDMedia(bestMatch, type);
    }
  }

  await search(englishTitle, englishTitle, false);

  if (bestScore < 0.95) {
    await search(romajiTitle, romajiTitle, false);
  }

  if (bestScore > 0.9 && bestMatch != null) {
    searchedTitle.value = (bestMatch.title ?? '').toUpperCase();
    print("Good match found: score ${bestScore.toStringAsFixed(3)}");
    return Media.froDMedia(bestMatch, type);
  }

  print("No good match found. Trying with heavy normalization...");
  bestScore = 0;
  bestMatch = null;

  if (savedTitle != null && savedTitle.isNotEmpty) {
    await search(_normalizeHeavy(savedTitle), savedTitle, true);
    if (bestScore >= 1.0 && bestMatch != null) {
      searchedTitle.value = (bestMatch.title ?? '').toUpperCase();
      return Media.froDMedia(bestMatch, type);
    }
  }

  await search(_normalizeHeavy(englishTitle), englishTitle, true);

  if (bestScore < 0.95) {
    await search(_normalizeHeavy(romajiTitle), romajiTitle, true);
  }

  if (bestScore >= 0.7 && bestMatch != null) {
    searchedTitle.value = (bestMatch.title ?? '').toUpperCase();
    print(
        "Final match with heavy normalization: score ${bestScore.toStringAsFixed(3)}");
    return Media.froDMedia(bestMatch, type);
  }

  print("No good match. Best: ${bestScore.toStringAsFixed(3)}");
  searchedTitle.value = fallbackResults.isNotEmpty
      ? fallbackResults.first.title ?? 'Unknown Title'
      : "No match found";

  return fallbackResults.isNotEmpty
      ? Media.froDMedia(fallbackResults.first, type)
      : Media(serviceType: ServicesType.anilist);
}
