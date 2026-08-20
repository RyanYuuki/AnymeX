import 'dart:math';

import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';

class Matchmaker {
  static const _watchStatsWeight = 0.25;
  static const _releaseYearWeight = 0.80;
  static const _genreWeight = 1.50;
  static const _tagWeight = 1.50;
  static const _perfectAnimeWeight = 2.00;
  static const _favouriteAnimeWeight = 4.00;
  static const _favouriteCharWeight = 0.80;
  static const _voiceActorWeight = 0.50;
  static const _studioWeight = 0.90;

  static CompatibilityResult compute(
    Profile user1,
    Profile user2, {
    List<int>? user1PerfectIds,
    List<int>? user2PerfectIds,
  }) {
    final a = user1.stats?.animeStats;
    final b = user2.stats?.animeStats;
    final f1 = user1.favourites;
    final f2 = user2.favourites;

    // ---- Heuristic 1: Watch Stats ----
    final watchStatsScore = a != null && b != null ? _watchStats(a, b) : 0.0;
    final watchStatsDesc = a != null && b != null
        ? _watchStatsDesc(a, b)
        : 'Insufficient data';

    // ---- Heuristic 2: Release Year Stats ----
    final releaseYearScore =
        a != null && b != null ? _releaseYearOverlap(a, b) : 0.0;
    final releaseYearDesc = a != null && b != null
        ? _releaseYearDesc(a, b)
        : 'Insufficient data';

    // ---- Heuristic 3: Common Genres ----
    final (genreScore, commonGenresList) =
        a != null && b != null ? _genreOverlap(a, b) : (0.0, <String>[]);
    final genreDesc =
        '${commonGenresList.length} shared top genres';

    // ---- Heuristic 4: Common Tags ----
    final (tagScore, commonTagsList) =
        a != null && b != null ? _tagOverlap(a, b) : (0.0, <String>[]);
    final tagDesc =
        '${commonTagsList.length} shared top tags';

    // ---- Heuristic 5: Common Perfect Anime ----
    final (perfectScore, perfectCount) = (user1PerfectIds != null &&
            user2PerfectIds != null &&
            user1PerfectIds.isNotEmpty &&
            user2PerfectIds.isNotEmpty)
        ? _jaccardIds(user1PerfectIds, user2PerfectIds)
        : (0.0, 0);
    final perfectDesc =
        '$perfectCount shared 10/10 anime';

    // ---- Heuristic 6: Common Favourite Anime ----
    final (favAnimeScore, favAnimeIds, favAnimeCount) =
        f1 != null && f2 != null
            ? _favouriteAnimeOverlap(f1, f2)
            : (0.0, <int>[], 0);
    final favAnimeDesc =
        '$favAnimeCount shared favourite anime';

    // ---- Heuristic 7: Common Favourite Characters ----
    final (favCharScore, favCharIds, favCharCount) =
        f1 != null && f2 != null
            ? _favouriteCharacterOverlap(f1, f2)
            : (0.0, <int>[], 0);
    final favCharDesc =
        '$favCharCount shared favourite characters';

    // ---- Heuristic 8: Common Voice Actors ----
    final (vaScore, vaNames) =
        a != null && b != null ? _voiceActorOverlap(a, b) : (0.0, <String>[]);
    final vaDesc =
        '${vaNames.length} shared top voice actors';

    // ---- Heuristic 9: Common Studios ----
    final (studioScore, studioNames) =
        a != null && b != null ? _studioOverlap(a, b) : (0.0, <String>[]);
    final studioDesc =
        '${studioNames.length} shared top studios';

    // ---- Compute weighted average ----
    final scores = [
      (watchStatsScore, _watchStatsWeight),
      (releaseYearScore, _releaseYearWeight),
      (genreScore, _genreWeight),
      (tagScore, _tagWeight),
      (perfectScore, _perfectAnimeWeight),
      (favAnimeScore, _favouriteAnimeWeight),
      (favCharScore, _favouriteCharWeight),
      (vaScore, _voiceActorWeight),
      (studioScore, _studioWeight),
    ];

    double totalWeight = 0;
    double weightedSum = 0;
    for (final (score, weight) in scores) {
      weightedSum += score * weight;
      totalWeight += weight;
    }
    final percentage = totalWeight > 0 ? (weightedSum / totalWeight) * 100 : 0.0;
    final clampedPct = percentage.clamp(0.0, 100.0);
    final rank = getRankForScore(clampedPct);

    // ---- Build breakdown ----
    final breakdown = [
      HeuristicScore(
        key: 'watchStats',
        label: 'Watch Stats',
        description: watchStatsDesc,
        score: watchStatsScore,
        weight: _watchStatsWeight,
        weightedScore: watchStatsScore * _watchStatsWeight,
      ),
      HeuristicScore(
        key: 'releaseYear',
        label: 'Release Years',
        description: releaseYearDesc,
        score: releaseYearScore,
        weight: _releaseYearWeight,
        weightedScore: releaseYearScore * _releaseYearWeight,
      ),
      HeuristicScore(
        key: 'genres',
        label: 'Common Genres',
        description: genreDesc,
        score: genreScore,
        weight: _genreWeight,
        weightedScore: genreScore * _genreWeight,
      ),
      HeuristicScore(
        key: 'tags',
        label: 'Common Tags',
        description: tagDesc,
        score: tagScore,
        weight: _tagWeight,
        weightedScore: tagScore * _tagWeight,
      ),
      HeuristicScore(
        key: 'perfectAnime',
        label: 'Perfect Anime',
        description: perfectDesc,
        score: perfectScore,
        weight: _perfectAnimeWeight,
        weightedScore: perfectScore * _perfectAnimeWeight,
      ),
      HeuristicScore(
        key: 'favouriteAnime',
        label: 'Favourite Anime',
        description: favAnimeDesc,
        score: favAnimeScore,
        weight: _favouriteAnimeWeight,
        weightedScore: favAnimeScore * _favouriteAnimeWeight,
      ),
      HeuristicScore(
        key: 'favouriteCharacters',
        label: 'Fav Characters',
        description: favCharDesc,
        score: favCharScore,
        weight: _favouriteCharWeight,
        weightedScore: favCharScore * _favouriteCharWeight,
      ),
      HeuristicScore(
        key: 'voiceActors',
        label: 'Voice Actors',
        description: vaDesc,
        score: vaScore,
        weight: _voiceActorWeight,
        weightedScore: vaScore * _voiceActorWeight,
      ),
      HeuristicScore(
        key: 'studios',
        label: 'Studios',
        description: studioDesc,
        score: studioScore,
        weight: _studioWeight,
        weightedScore: studioScore * _studioWeight,
      ),
    ];

    return CompatibilityResult(
      percentage: clampedPct,
      rank: rank.name,
      rankDescription: rank.description,
      breakdown: breakdown,
      commonFavouriteAnimeIds: favAnimeIds,
      commonFavouriteCharacterIds: favCharIds,
      commonGenres: commonGenresList,
      commonTags: commonTagsList,
      commonStudios: studioNames,
      commonVoiceActors: vaNames,
    );
  }

  // ============================================================
  // Heuristic 1: Watch Stats (×0.25)
  // Compares completed count, episodes watched, hours, mean score
  // ============================================================

  static double _watchStats(AnimeStats a, AnimeStats b) {
    final aCount = _parseD(a.animeCount);
    final bCount = _parseD(b.animeCount);
    final aEps = _parseD(a.episodesWatched);
    final bEps = _parseD(b.episodesWatched);
    final aMins = _parseD(a.minutesWatched);
    final bMins = _parseD(b.minutesWatched);
    final aScore = _parseD(a.meanScore);
    final bScore = _parseD(b.meanScore);

    final countSim = _dimSimilarity(aCount, bCount);
    final epsSim = _dimSimilarity(aEps, bEps);
    final minsSim = _dimSimilarity(aMins, bMins);
    final scoreSim = 1 - (aScore - bScore).abs() / 100;

    return (countSim + epsSim + minsSim + scoreSim) / 4;
  }

  static String _watchStatsDesc(AnimeStats a, AnimeStats b) {
    return '${_parseI(a.animeCount)} vs ${_parseI(b.animeCount)} anime';
  }

  // ============================================================
  // Heuristic 2: Release Year Stats (×0.80)
  // Decade bucket comparison
  // ============================================================

  static double _releaseYearOverlap(AnimeStats a, AnimeStats b) {
    final aDecades = _toDecadeDistribution(a.releaseYears);
    final bDecades = _toDecadeDistribution(b.releaseYears);

    if (aDecades.isEmpty || bDecades.isEmpty) return 0.0;

    final allDecades = {...aDecades.keys, ...bDecades.keys}.toList()..sort();
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (final decade in allDecades) {
      final va = aDecades[decade] ?? 0.0;
      final vb = bDecades[decade] ?? 0.0;
      dotProduct += va * vb;
      normA += va * va;
      normB += vb * vb;
    }

    final denom = sqrt(normA) * sqrt(normB);
    return denom > 0 ? (dotProduct / denom).clamp(0.0, 1.0) : 0.0;
  }

  static String _releaseYearDesc(AnimeStats a, AnimeStats b) {
    final aTop = _topDecade(a.releaseYears);
    final bTop = _topDecade(b.releaseYears);
    return aTop != null && bTop != null
        ? '${_decadeLabel(aTop)} vs ${_decadeLabel(bTop)}'
        : 'Insufficient data';
  }

  static int? _topDecade(List<YearStat> years) {
    if (years.isEmpty) return null;
    return years.reduce((a, b) => a.count > b.count ? a : b).year;
  }

  static String _decadeLabel(int year) {
    final decade = (year ~/ 10) * 10;
    return '${decade}s';
  }

  static Map<int, double> _toDecadeDistribution(List<YearStat> years) {
    final total = years.fold<int>(0, (s, y) => s + y.count);
    if (total == 0) return {};
    final map = <int, double>{};
    for (final y in years) {
      final decade = (y.year ~/ 10) * 10;
      map[decade] = (map[decade] ?? 0) + y.count / total;
    }
    return map;
  }

  // ============================================================
  // Heuristic 3: Common Genres (×1.50)
  // Top 5 above-average genres, Jaccard
  // ============================================================

  static (double, List<String>) _genreOverlap(AnimeStats a, AnimeStats b) {
    final aAvg = _parseD(a.meanScore);
    final bAvg = _parseD(b.meanScore);

    final aTop = _aboveAverageGenres(a.genres, aAvg);
    final bTop = _aboveAverageGenres(b.genres, bAvg);

    final aSet = aTop.take(5).map((g) => g.genre.toLowerCase()).toSet();
    final bSet = bTop.take(5).map((g) => g.genre.toLowerCase()).toSet();

    if (aSet.isEmpty || bSet.isEmpty) return (0.0, []);

    final common = aSet.intersection(bSet).toList();
    final union = aSet.union(bSet).length;
    return (common.length / union, common);
  }

  // ============================================================
  // Heuristic 4: Common Tags (×1.50)
  // Top 10 above-average tags, Jaccard
  // ============================================================

  static (double, List<String>) _tagOverlap(AnimeStats a, AnimeStats b) {
    final aAvg = _parseD(a.meanScore);
    final bAvg = _parseD(b.meanScore);

    final aTop = _aboveAverageTags(a.tags, aAvg);
    final bTop = _aboveAverageTags(b.tags, bAvg);

    final aSet = aTop.take(10).map((t) => t.tag.toLowerCase()).toSet();
    final bSet = bTop.take(10).map((t) => t.tag.toLowerCase()).toSet();

    if (aSet.isEmpty || bSet.isEmpty) return (0.0, []);

    final common = aSet.intersection(bSet).toList();
    final union = aSet.union(bSet).length;
    return (common.length / union, common);
  }

  // ============================================================
  // Heuristic 5: Common Perfect Anime (×2.00)
  // Jaccard on 10/10 scored anime IDs
  // ============================================================

  static (double, int) _jaccardIds(List<int> a, List<int> b) {
    final aSet = a.toSet();
    final bSet = b.toSet();
    final common = aSet.intersection(bSet).length;
    final union = aSet.union(bSet).length;
    if (union == 0) return (0.0, 0);
    return (common / union, common);
  }

  // ============================================================
  // Heuristic 6: Common Favourite Anime (×4.00)
  // Jaccard on favourite anime IDs
  // ============================================================

  static (double, List<int>, int) _favouriteAnimeOverlap(
      ProfileFavourites f1, ProfileFavourites f2) {
    final aIds = f1.anime.map((a) => int.tryParse(a.id ?? '') ?? 0).toSet();
    final bIds = f2.anime.map((a) => int.tryParse(a.id ?? '') ?? 0).toSet();

    final common = aIds.intersection(bIds);
    final union = aIds.union(bIds);

    if (union.isEmpty) return (0.0, [], 0);
    return (common.length / union.length, common.toList(), common.length);
  }

  // ============================================================
  // Heuristic 7: Common Favourite Characters (×0.80)
  // Jaccard on favourite character IDs
  // ============================================================

  static (double, List<int>, int) _favouriteCharacterOverlap(
      ProfileFavourites f1, ProfileFavourites f2) {
    final aIds =
        f1.characters.map((c) => int.tryParse(c.id ?? '') ?? 0).toSet();
    final bIds =
        f2.characters.map((c) => int.tryParse(c.id ?? '') ?? 0).toSet();

    final common = aIds.intersection(bIds);
    final union = aIds.union(bIds);

    if (union.isEmpty) return (0.0, [], 0);
    return (common.length / union.length, common.toList(), common.length);
  }

  // ============================================================
  // Heuristic 8: Common Voice Actors (×0.50)
  // Above-average VAs, Jaccard on IDs
  // ============================================================

  static (double, List<String>) _voiceActorOverlap(AnimeStats a, AnimeStats b) {
    final aAvg = _parseD(a.meanScore);
    final bAvg = _parseD(b.meanScore);

    final aTop = a.voiceActors
        .where((v) => v.meanScore > aAvg && aAvg > 0)
        .toList()
      ..sort((x, y) => y.count.compareTo(x.count));
    final bTop = b.voiceActors
        .where((v) => v.meanScore > bAvg && bAvg > 0)
        .toList()
      ..sort((x, y) => y.count.compareTo(x.count));

    final aSet =
        aTop.take(10).map((v) => v.id ?? '').where((id) => id.isNotEmpty).toSet();
    final bSet =
        bTop.take(10).map((v) => v.id ?? '').where((id) => id.isNotEmpty).toSet();

    if (aSet.isEmpty || bSet.isEmpty) return (0.0, []);

    final commonIds = aSet.intersection(bSet);
    final commonNames = <String>[];
    for (final va in aTop) {
      if (commonIds.contains(va.id)) {
        commonNames.add(va.name);
      }
    }
    final union = aSet.union(bSet).length;
    return (commonIds.length / union, commonNames);
  }

  // ============================================================
  // Heuristic 9: Common Studios (×0.90)
  // Above-average studios, Jaccard on IDs
  // ============================================================

  static (double, List<String>) _studioOverlap(AnimeStats a, AnimeStats b) {
    final aAvg = _parseD(a.meanScore);
    final bAvg = _parseD(b.meanScore);

    final aTop = a.studios
        .where((s) => s.meanScore > aAvg && aAvg > 0)
        .toList()
      ..sort((x, y) => y.count.compareTo(x.count));
    final bTop = b.studios
        .where((s) => s.meanScore > bAvg && bAvg > 0)
        .toList()
      ..sort((x, y) => y.count.compareTo(x.count));

    final aSet =
        aTop.take(5).map((s) => s.id ?? '').where((id) => id.isNotEmpty).toSet();
    final bSet =
        bTop.take(5).map((s) => s.id ?? '').where((id) => id.isNotEmpty).toSet();

    if (aSet.isEmpty || bSet.isEmpty) return (0.0, []);

    final commonIds = aSet.intersection(bSet);
    final commonNames = <String>[];
    for (final s in aTop) {
      if (commonIds.contains(s.id)) {
        commonNames.add(s.name);
      }
    }
    final union = aSet.union(bSet).length;
    return (commonIds.length / union, commonNames);
  }

  // ============================================================
  // Helpers
  // ============================================================

  static double _parseD(String? s) => double.tryParse(s ?? '') ?? 0.0;
  static int _parseI(String? s) => int.tryParse(s ?? '') ?? 0;

  static double _dimSimilarity(double a, double b) {
    final maxVal = [a, b, 1.0].reduce((x, y) => x > y ? x : y);
    return 1 - (a - b).abs() / maxVal;
  }

  static List<GenreStat> _aboveAverageGenres(
      List<GenreStat> genres, double avg) {
    if (avg <= 0) return genres.toList()..sort((a, b) => b.count.compareTo(a.count));
    final filtered = genres.where((g) => g.meanScore > avg).toList();
    if (filtered.isEmpty) return genres.toList()..sort((a, b) => b.count.compareTo(a.count));
    filtered.sort((a, b) => b.count.compareTo(a.count));
    return filtered;
  }

  static List<TagStat> _aboveAverageTags(List<TagStat> tags, double avg) {
    if (avg <= 0) return tags.toList()..sort((a, b) => b.count.compareTo(a.count));
    final filtered = tags.where((t) => t.meanScore > avg).toList();
    if (filtered.isEmpty) return tags.toList()..sort((a, b) => b.count.compareTo(a.count));
    filtered.sort((a, b) => b.count.compareTo(a.count));
    return filtered;
  }
}
