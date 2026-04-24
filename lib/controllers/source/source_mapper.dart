import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:get/get.dart';

class SourceMapper {
  static String? _currentMappingToken;

  static String _normalizeLight(String title) {
    return title.trim().toLowerCase();
  }

  static bool _isInvalidTitle(String? title) {
    final value = (title ?? '').trim().toLowerCase();
    return value.isEmpty || value == '?' || value == '??' || value == 'null';
  }

  static String _normalizeHeavy(String title) {
    String normalized =
        title.replaceAll(RegExp(r'\bseason\s*', caseSensitive: false), '');

    normalized = normalized
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .toLowerCase();
    return normalized;
  }

  static int? _extractSeasonNumber(String title) {
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

  static double _calculateMatchScore(
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

  static Media createMediaFromExtension(DMedia data, ItemType type) {
    return Media(
      id: data.url ?? '',
      title: data.title ?? '',
      poster: data.cover ?? '',
      mediaType: type,
      serviceType: ServicesType.extensions,
    );
  }

  static Future<Media?> mapMedia(
    List<String> titles,
    RxString searchedTitle, {
    required String mediaId,
    required ItemType type,
    String? savedTitle,
    List<String> synonyms = const [],
  }) async {
    final sourceController = Get.find<SourceController>();
    final isManga = type == ItemType.manga;

    String englishTitle = titles[0].split("*").first.trim();
    String romajiTitle = (titles.length > 1 ? titles[1] : '').trim();

    if (_isInvalidTitle(englishTitle)) englishTitle = '';
    if (_isInvalidTitle(romajiTitle)) romajiTitle = '';
    if (englishTitle.isEmpty && romajiTitle.isNotEmpty) {
      englishTitle = romajiTitle;
    }
    if (romajiTitle.isEmpty && englishTitle.isNotEmpty) {
      romajiTitle = englishTitle;
    }

    searchedTitle.value =
        "Searching: ${englishTitle.isNotEmpty ? englishTitle : romajiTitle}";

    final stickySource = sourceController.getSavedSource(mediaId, type);
    if (stickySource != null) {
      sourceController.setActiveSource(stickySource);
    }

    final mappingToken = DateTime.now().millisecondsSinceEpoch.toString();
    _currentMappingToken = mappingToken;

    bool isInterrupted() => _currentMappingToken != mappingToken;

    final activeSource = type == ItemType.manga
        ? sourceController.activeMangaSource.value
        : sourceController.activeSource.value;

    if (activeSource == null) {
      Logger.i("No active source found!");
      searchedTitle.value = "No active source";
      return null;
    }

    double bestScore = 0;
    dynamic bestMatch;
    List<DMedia> fallbackResults = [];

    Future<void> search(
        String query, String sourceTitle, bool isHeavyNormalized) async {
      if (isInterrupted() || bestScore >= 0.98) return;

      searchedTitle.value = "Searching: $sourceTitle";
      final token = "map_${mappingToken}_${query.hashCode}";
      sourceController.updateToken(isManga ? 'manga_search' : 'search', token);

      final results = (await activeSource.methods.search(
        query,
        1,
        [],
        parameters: SourceParams(cancelToken: token),
      ))
          .list;

      if (results.isEmpty || isInterrupted()) return;

      final allTargetTitles = {
        if (englishTitle.isNotEmpty) englishTitle,
        if (romajiTitle.isNotEmpty) romajiTitle,
        ...synonyms.take(3),
      }.toList();

      for (final result in results) {
        if (isInterrupted()) return;

        final resultTitle = result.title ?? '';
        searchedTitle.value = "Finding: $resultTitle";

        await Future.delayed(const Duration(milliseconds: 5));

        if (savedTitle != null &&
            _normalizeLight(resultTitle) == _normalizeLight(savedTitle)) {
          bestScore = 2.0;
          bestMatch = result;
          fallbackResults = results;
          return;
        }

        final resultSeason = _extractSeasonNumber(resultTitle);

        for (final targetTitle in allTargetTitles) {
          final normalizedTarget = isHeavyNormalized
              ? _normalizeHeavy(targetTitle)
              : _normalizeLight(targetTitle);
          final normalizedResult = isHeavyNormalized
              ? _normalizeHeavy(resultTitle)
              : _normalizeLight(resultTitle);

          final score = _calculateMatchScore(
            normalizedTarget,
            normalizedResult,
            _extractSeasonNumber(targetTitle),
            resultSeason,
          );

          if (score > bestScore) {
            bestScore = score;
            bestMatch = result;
            fallbackResults = results;
          }
          if (bestScore >= 0.98) break;
        }

        if (bestScore >= 0.98) break;
      }
    }

    if (savedTitle != null && savedTitle.isNotEmpty) {
      await search(savedTitle, savedTitle, false);
      if (bestScore >= 0.7 && bestMatch != null) {
        searchedTitle.value = "Found: ${bestMatch.title ?? ''}";
        return Media.froDMedia(bestMatch, type);
      }
    }

    if (englishTitle.isNotEmpty) {
      await search(englishTitle, englishTitle, false);
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        searchedTitle.value = "Found: ${bestMatch.title ?? ''}";
        return Media.froDMedia(bestMatch, type);
      }
    }

    if (bestScore < 0.95 &&
        romajiTitle.isNotEmpty &&
        _normalizeLight(romajiTitle) != _normalizeLight(englishTitle)) {
      await search(romajiTitle, romajiTitle, false);
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        searchedTitle.value = "Found: ${bestMatch.title ?? ''}";
        return Media.froDMedia(bestMatch, type);
      }
    }

    if (bestScore < 0.9 && synonyms.isNotEmpty) {
      Logger.i(
          "Confidence low (${bestScore.toStringAsFixed(2)}). Trying synonyms...");
      final limitedSynonyms = synonyms.take(3);
      for (final synonym in limitedSynonyms) {
        if (isInterrupted() || bestScore >= 0.95) break;
        if (_isInvalidTitle(synonym)) continue;
        await search(synonym, synonym, false);
      }
      if (isInterrupted()) return null;
      if (bestScore >= 0.98) {
        searchedTitle.value = "Found: ${bestMatch.title ?? ''}";
        return Media.froDMedia(bestMatch, type);
      }
    }

    if (bestScore < 0.7) {
      Logger.i("No good match. Trying heavy normalization...");
      if (englishTitle.isNotEmpty) {
        await search(_normalizeHeavy(englishTitle), englishTitle, true);
      }
      if (bestScore < 0.8 && romajiTitle.isNotEmpty) {
        await search(_normalizeHeavy(romajiTitle), romajiTitle, true);
      }
    }

    if (bestScore >= 0.7 && bestMatch != null) {
      searchedTitle.value = "Found: ${bestMatch.title ?? ''}";
      return Media.froDMedia(bestMatch, type);
    }

    searchedTitle.value = fallbackResults.isNotEmpty
        ? "Found: ${fallbackResults.first.title ?? 'Unknown Title'}"
        : "No Match Found";

    return fallbackResults.isNotEmpty
        ? Media.froDMedia(fallbackResults.first, type)
        : (isManga
            ? Media(
                serviceType: ServicesType.anilist, mediaType: ItemType.manga)
            : Media(serviceType: ServicesType.anilist));
  }

  static void interruptMapping() {
    _currentMappingToken =
        "interrupted_${DateTime.now().millisecondsSinceEpoch}";
  }
}
