import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:get/get.dart';

class AnimeMatchResult {
  final bool isMatch;
  final double score;
  final String matchedTitle;
  final double englishScore;
  final double romajiScore;
  final AnimeMatchDetails details;

  AnimeMatchResult({
    required this.isMatch,
    required this.score,
    required this.matchedTitle,
    required this.englishScore,
    required this.romajiScore,
    required this.details,
  });

  @override
  String toString() {
    return 'AnimeMatchResult(isMatch: $isMatch, score: $score, matchedTitle: $matchedTitle)';
  }
}

class AnimeMatchDetails {
  final double levenshtein;
  final double jaroWinkler;
  final double wordMatch;
  final double seasonBonus;

  AnimeMatchDetails({
    required this.levenshtein,
    required this.jaroWinkler,
    required this.wordMatch,
    required this.seasonBonus,
  });

  @override
  String toString() {
    return 'AnimeMatchDetails(levenshtein: $levenshtein, jaroWinkler: $jaroWinkler, wordMatch: $wordMatch, seasonBonus: $seasonBonus)';
  }
}

class _SimilarityResult {
  final double levRatio;
  final double jw;
  final double wordMatchRatio;
  final double seasonBonus;
  final double finalScore;

  _SimilarityResult({
    required this.levRatio,
    required this.jw,
    required this.wordMatchRatio,
    required this.seasonBonus,
    required this.finalScore,
  });
}

AnimeMatchResult matchAnimeTitle(
  String? sourceEnglishTitle,
  String? sourceRomajiTitle,
  String targetTitle, {
  double threshold = 0.9,
}) {
  // Normalize strings
  String normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .trim();
  }

  final String normalizedEnglish = normalize(sourceEnglishTitle ?? '');
  final String normalizedRomaji = normalize(sourceRomajiTitle ?? '');
  final String normalizedTarget = normalize(targetTitle);

  // Check for exact matches first
  if (normalizedEnglish == normalizedTarget ||
      normalizedRomaji == normalizedTarget) {
    return AnimeMatchResult(
      isMatch: true,
      score: 1.0,
      matchedTitle:
          normalizedEnglish == normalizedTarget ? 'english' : 'romaji',
      englishScore: normalizedEnglish == normalizedTarget ? 1.0 : 0.0,
      romajiScore: normalizedRomaji == normalizedTarget ? 1.0 : 0.0,
      details: AnimeMatchDetails(
        levenshtein: 1.0,
        jaroWinkler: 1.0,
        wordMatch: 1.0,
        seasonBonus: 0.0,
      ),
    );
  }

  // Extract season numbers from titles using regular expressions
  int? extractSeasonInfo(String title) {
    final List<RegExp> seasonPatterns = [
      RegExp(r'\b(\d+)(?:th|st|nd|rd)?\s*season\b', caseSensitive: false),
      RegExp(r'\bseason\s*(\d+)\b', caseSensitive: false),
      RegExp(r'\s(\d+)\b(?!\s*[a-zA-Z])'),
      RegExp(r'\b(\d+)(nd|rd|th|st)\b'),
    ];

    for (final pattern in seasonPatterns) {
      final match = pattern.firstMatch(title);
      if (match != null && match.group(1) != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    return null;
  }

  final int? targetSeasonNumber = extractSeasonInfo(normalizedTarget);
  final int? englishSeasonNumber = extractSeasonInfo(normalizedEnglish);
  final int? romajiSeasonNumber = extractSeasonInfo(normalizedRomaji);

  // Levenshtein distance implementation
  int levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final List<List<int>> matrix = List.generate(
      b.length + 1,
      (i) => List.filled(a.length + 1, 0),
    );

    for (int i = 0; i <= b.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= a.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= b.length; i++) {
      for (int j = 1; j <= a.length; j++) {
        final int cost = a[j - 1] == b[i - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[b.length][a.length];
  }

  // Jaro-Winkler distance implementation
  double jaroWinkler(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final int matchDistance =
        (s1.length > s2.length ? s1.length : s2.length) ~/ 2 - 1;
    if (matchDistance < 0) return s1 == s2 ? 1.0 : 0.0;

    final List<bool> s1Matches = List.filled(s1.length, false);
    final List<bool> s2Matches = List.filled(s2.length, false);

    int matches = 0;

    // Find matches
    for (int i = 0; i < s1.length; i++) {
      final int start = i - matchDistance > 0 ? i - matchDistance : 0;
      final int end =
          i + matchDistance + 1 < s2.length ? i + matchDistance + 1 : s2.length;

      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    // Calculate transpositions
    int transpositions = 0;
    int j = 0;

    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (j < s2.length && !s2Matches[j]) {
          j++;
        }
        if (j < s2.length && s1[i] != s2[j]) transpositions++;
        j++;
      }
    }

    final double jaro = (1 / 3) *
        (matches / s1.length +
            matches / s2.length +
            (matches - transpositions / 2) / matches);

    // Winkler modification: boost score for strings that share a prefix
    const double p = 0.1; // scaling factor
    int l = 0; // length of common prefix up to 4 chars

    final int minLength = s1.length < s2.length ? s1.length : s2.length;
    final int prefixLength = minLength < 4 ? minLength : 4;

    for (int i = 0; i < prefixLength; i++) {
      if (s1[i] == s2[i]) {
        l++;
      } else {
        break;
      }
    }

    return jaro + l * p * (1 - jaro);
  }

  // Calculate similarity metrics for a single title
  _SimilarityResult calculateSimilarity(
    String source,
    String target,
    int? sourceSeasonNum,
    int? targetSeasonNum,
  ) {
    if (source.isEmpty) {
      return _SimilarityResult(
        levRatio: 0,
        jw: 0,
        wordMatchRatio: 0,
        seasonBonus: 0,
        finalScore: 0,
      );
    }

    final double levRatio = 1 -
        levenshtein(source, target) /
            (source.length > target.length ? source.length : target.length);
    final double jw = jaroWinkler(source, target);

    // Word level matching (for handling word order differences)
    final List<String> sourceWords =
        source.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final List<String> targetWords =
        target.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    int wordMatches = 0;
    for (final String sWord in sourceWords) {
      if (targetWords.contains(sWord)) wordMatches++;
    }

    final double wordMatchRatio =
        sourceWords.isNotEmpty && targetWords.isNotEmpty
            ? wordMatches /
                (sourceWords.length > targetWords.length
                    ? sourceWords.length
                    : targetWords.length)
            : 0;

    // Season number matching bonus
    double seasonBonus = 0;
    if (targetSeasonNum != null && sourceSeasonNum != null) {
      // Exact match gets full bonus
      if (targetSeasonNum == sourceSeasonNum) {
        seasonBonus = 0.3;
      } else {
        // Partial bonus for being close (helps with "Season 4" matching "4th Season")
        seasonBonus = 0.1;
      }
    }

    // Combined score with weighted components
    final double finalScore =
        levRatio * 0.3 + jw * 0.3 + wordMatchRatio * 0.2 + seasonBonus;

    return _SimilarityResult(
      levRatio: levRatio,
      jw: jw,
      wordMatchRatio: wordMatchRatio,
      seasonBonus: seasonBonus,
      finalScore: finalScore,
    );
  }

  // Get scores for both titles
  final _SimilarityResult englishSimilarity = calculateSimilarity(
    normalizedEnglish,
    normalizedTarget,
    englishSeasonNumber,
    targetSeasonNumber,
  );
  final _SimilarityResult romajiSimilarity = calculateSimilarity(
    normalizedRomaji,
    normalizedTarget,
    romajiSeasonNumber,
    targetSeasonNumber,
  );

  // Determine the best match
  final double bestScore =
      englishSimilarity.finalScore > romajiSimilarity.finalScore
          ? englishSimilarity.finalScore
          : romajiSimilarity.finalScore;
  final String matchedTitle =
      englishSimilarity.finalScore >= romajiSimilarity.finalScore
          ? 'english'
          : 'romaji';

  final _SimilarityResult bestSimilarity =
      matchedTitle == 'english' ? englishSimilarity : romajiSimilarity;

  return AnimeMatchResult(
    isMatch: bestScore >= threshold,
    score: bestScore,
    matchedTitle: matchedTitle,
    englishScore: englishSimilarity.finalScore,
    romajiScore: romajiSimilarity.finalScore,
    details: AnimeMatchDetails(
      levenshtein: bestSimilarity.levRatio,
      jaroWinkler: bestSimilarity.jw,
      wordMatch: bestSimilarity.wordMatchRatio,
      seasonBonus: bestSimilarity.seasonBonus,
    ),
  );
}

Future<Media?> mapMedia(List<String> animeId, RxString searchedTitle) async {
  final sourceController = Get.find<SourceController>();
  final isManga = animeId[0].split("*").last == "MANGA";
  final type = isManga ? ItemType.manga : ItemType.anime;
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
    Logger.i("No active source found!");
    return null;
  }

  double highestSimilarity = 0;
  String? bestMatch;
  List<DMedia> searchResults = [];
  dynamic bestMatchResult;

  Future<void> searchAndCompare(String query) async {
    final results = (await activeSource.methods.search(query, 1, [])).list;

    if (results.isEmpty) return;

    for (final result in results) {
      final resultTitle = normalize((result.title ?? '').trim());
      searchedTitle.value = "Searching: $resultTitle";
      print("Matching '$resultTitle' with query '$query'");

      // Use the advanced anime title matcher
      final matchResult = matchAnimeTitle(
        englishTitle,
        romajiTitle,
        resultTitle,
        threshold: 0.7, // Lower threshold for more flexible matching
      );

      print(
          "Match score: ${matchResult.score.toStringAsFixed(3)} for '$resultTitle'");
      print(
          "Match details: English(${matchResult.englishScore.toStringAsFixed(3)}) Romaji(${matchResult.romajiScore.toStringAsFixed(3)})");

      // Perfect match check
      if (matchResult.score >= 0.95) {
        highestSimilarity = matchResult.score;
        bestMatch = resultTitle;
        bestMatchResult = result;
        searchResults = results;
        print("Perfect match found: $resultTitle");
        return; // Exit early for near-perfect match
      }

      // Update best match if this result has a higher similarity
      if (matchResult.score > highestSimilarity) {
        highestSimilarity = matchResult.score;
        bestMatch = resultTitle;
        bestMatchResult = result;
        searchResults = results;
        print(
            "New best match: $resultTitle with score ${matchResult.score.toStringAsFixed(3)}");
      }
    }
  }

  // First search using englishTitle
  await searchAndCompare(englishTitle);

  // If no perfect match was found, try searching with romajiTitle
  if (highestSimilarity < 0.95) {
    await searchAndCompare(romajiTitle);
  }

  // If we found a match with high enough similarity, return it
  if (highestSimilarity >= 0.7 &&
      bestMatch != null &&
      bestMatchResult != null) {
    searchedTitle.value = bestMatch!.toUpperCase();
    print(
        "Final match selected: $bestMatch with score ${highestSimilarity.toStringAsFixed(3)}");
    return Media.froDMedia(bestMatchResult, type);
  }

  print(
      "No good match found. Highest similarity: ${highestSimilarity.toStringAsFixed(3)}");
  searchedTitle.value = searchResults.isNotEmpty
      ? searchResults.first.title ?? 'Unknown Title'
      : "No match found";
  return searchResults.isNotEmpty
      ? Media.froDMedia(searchResults.first, type)
      : Media(serviceType: ServicesType.anilist);
}
