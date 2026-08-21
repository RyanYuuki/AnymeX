import 'dart:math';

import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';

class Matchmaker {
  // ============================================================
  // Anime weights
  // ============================================================
  static CompatibilitySection _toSection(_SectionResult r) => r.toSection();

  static const _watchStatsWeight = 0.25;
  static const _releaseYearWeight = 0.80;
  static const _genreWeight = 1.50;
  static const _tagWeight = 1.50;
  static const _perfectAnimeWeight = 2.00;
  static const _favouriteAnimeWeight = 4.00;
  static const _favouriteCharWeight = 0.80;
  static const _voiceActorWeight = 0.50;
  static const _studioWeight = 0.90;

  // ============================================================
  // Manga & Novels weights
  // ============================================================
  static const _mangaReadStatsWeight = 0.25;
  static const _mangaReleaseYearWeight = 0.80;
  static const _mangaGenreWeight = 1.50;
  static const _mangaTagWeight = 1.50;
  static const _favouriteMangaWeight = 4.00;

  // ============================================================
  // Main entry point
  // ============================================================

  static CompatibilityResult compute(
    Profile user1,
    Profile user2, {
    List<int>? user1PerfectIds,
    List<int>? user2PerfectIds,
  }) {
    final a = user1.stats?.animeStats;
    final b = user2.stats?.animeStats;
    final m1 = user1.stats?.mangaStats;
    final m2 = user2.stats?.mangaStats;
    final f1 = user1.favourites;
    final f2 = user2.favourites;

    // ---- Anime section ----
    final animeResult = _computeAnimeSection(a, b, f1, f2, user1PerfectIds, user2PerfectIds);

    // ---- Manga & Novels section ----
    final mangaResult = _computeMangaSection(m1, m2, f1, f2);

    // ---- Compute overall (weighted average of sections that have data) ----
    final double overallPct;
    if (animeResult.hasData && mangaResult.hasData) {
      // Weight anime slightly more since it has more signals
      overallPct = (animeResult.percentage * 0.55) + (mangaResult.percentage * 0.45);
    } else if (animeResult.hasData) {
      overallPct = animeResult.percentage;
    } else if (mangaResult.hasData) {
      overallPct = mangaResult.percentage;
    } else {
      overallPct = 0.0;
    }
    final clampedPct = overallPct.clamp(0.0, 100.0);
    final overallRank = getRankForScore(clampedPct);

    // ---- Build flat breakdown (all heuristics combined) ----
    final allBreakdown = <HeuristicScore>[
      ...animeResult.breakdown,
      ...mangaResult.breakdown,
    ];

    // ---- Format splits ----
    final u1Split = _mangaFormatSplit(m1);
    final u2Split = _mangaFormatSplit(m2);

    return CompatibilityResult(
      percentage: clampedPct,
      rank: overallRank.name,
      rankDescription: overallRank.description,
      animeSection: _toSection(animeResult),
      mangaSection: _toSection(mangaResult),
      breakdown: allBreakdown,
      commonFavouriteAnimeIds: animeResult._favAnimeIds,
      commonFavouriteMangaIds: mangaResult._favMangaIds,
      commonFavouriteCharacterIds: animeResult._favCharIds,
      commonStaffIds: animeResult._staffIds,
      commonGenres: animeResult._genreNames,
      commonTags: animeResult._tagNames,
      commonStudios: animeResult._studioNames,
      commonVoiceActors: animeResult._vaNames,
      commonMangaGenres: mangaResult._genreNames,
      commonMangaTags: mangaResult._tagNames,
      user1FormatSplit: u1Split,
      user2FormatSplit: u2Split,
    );
  }

  // ============================================================
  // ANIME SECTION (9 heuristics)
  // ============================================================

  static _SectionResult _computeAnimeSection(
    AnimeStats? a,
    AnimeStats? b,
    ProfileFavourites? f1,
    ProfileFavourites? f2,
    List<int>? user1PerfectIds,
    List<int>? user2PerfectIds,
  ) {
    if (a == null || b == null) {
      return _SectionResult.noData();
    }

    // H1: Watch Stats
    final watchStatsScore = _watchStats(a, b);
    final watchStatsDesc = _watchStatsDesc(a, b);

    // H2: Release Years
    final releaseYearScore = _releaseYearOverlap(a, b);
    final releaseYearDesc = _releaseYearDesc(a, b);

    // H3: Genres
    final (genreScore, commonGenresList) = _genreOverlap(a, b);

    // H4: Tags
    final (tagScore, commonTagsList) = _tagOverlap(a, b);

    // H5: Perfect Anime
    final (perfectScore, perfectCount) =
        (user1PerfectIds != null &&
                user2PerfectIds != null &&
                user1PerfectIds.isNotEmpty &&
                user2PerfectIds.isNotEmpty)
            ? _jaccardIds(user1PerfectIds, user2PerfectIds)
            : (0.0, 0);

    // H6: Favourite Anime
    final (favAnimeScore, favAnimeIds, favAnimeCount) =
        f1 != null && f2 != null
            ? _favouriteAnimeOverlap(f1, f2)
            : (0.0, <int>[], 0);

    // H7: Favourite Characters
    final (favCharScore, favCharIds, favCharCount) =
        f1 != null && f2 != null
            ? _favouriteCharacterOverlap(f1, f2)
            : (0.0, <int>[], 0);

    // H8: Voice Actors
    final (vaScore, vaNames) = _voiceActorOverlap(a, b);

    // H9: Studios
    final (studioScore, studioNames) = _studioOverlap(a, b);

    // H10: Favourite Staff (shared, but stored in anime section)
    final (staffScore, staffNames) =
        f1 != null && f2 != null ? _favouriteStaffOverlap(f1, f2) : (0.0, <String>[]);

    // Build scores
    final scores = [
      _H(watchStatsScore, _watchStatsWeight),
      _H(releaseYearScore, _releaseYearWeight),
      _H(genreScore, _genreWeight),
      _H(tagScore, _tagWeight),
      _H(perfectScore, _perfectAnimeWeight),
      _H(favAnimeScore, _favouriteAnimeWeight),
      _H(favCharScore, _favouriteCharWeight),
      _H(vaScore, _voiceActorWeight),
      _H(studioScore, _studioWeight),
      _H(staffScore, 0.50),
    ];

    final (pct, rank) = _weightedResult(scores);

    final breakdown = [
      _hs('watchStats', 'Watch Stats', watchStatsDesc, watchStatsScore, _watchStatsWeight),
      _hs('releaseYear', 'Release Years', releaseYearDesc, releaseYearScore, _releaseYearWeight),
      _hs('genres', 'Common Genres', '${commonGenresList.length} shared top genres', genreScore, _genreWeight),
      _hs('tags', 'Common Tags', '${commonTagsList.length} shared top tags', tagScore, _tagWeight),
      _hs('perfectAnime', 'Perfect Anime', '$perfectCount shared 10/10 anime', perfectScore, _perfectAnimeWeight),
      _hs('favouriteAnime', 'Fav Anime', '$favAnimeCount shared favourite anime', favAnimeScore, _favouriteAnimeWeight),
      _hs('favouriteCharacters', 'Fav Characters', '$favCharCount shared favourite characters', favCharScore, _favouriteCharWeight),
      _hs('voiceActors', 'Voice Actors', '${vaNames.length} shared top VAs', vaScore, _voiceActorWeight),
      _hs('studios', 'Studios', '${studioNames.length} shared top studios', studioScore, _studioWeight),
      _hs('staff', 'Fav Staff', '${staffNames.length} shared favourite staff', staffScore, 0.50),
    ];

    return _SectionResult(
      percentage: pct,
      rank: rank.name,
      rankDescription: rank.description,
      breakdown: breakdown,
      favAnimeIds: favAnimeIds,
      favCharIds: favCharIds,
      staffIds: staffNames,
      genreNames: commonGenresList,
      tagNames: commonTagsList,
      studioNames: studioNames,
      vaNames: vaNames,
    );
  }

  // ============================================================
  // MANGA & NOVELS SECTION (5 heuristics)
  // ============================================================

  static _SectionResult _computeMangaSection(
    MangaStats? m1,
    MangaStats? m2,
    ProfileFavourites? f1,
    ProfileFavourites? f2,
  ) {
    if (m1 == null || m2 == null) {
      return _SectionResult.noData();
    }

    // MH1: Read Stats
    final readStatsScore = _mangaReadStats(m1, m2);
    final readStatsDesc = _mangaReadStatsDesc(m1, m2);

    // MH2: Release Years
    final releaseYearScore = _mangaReleaseYearOverlap(m1, m2);
    final releaseYearDesc = _mangaReleaseYearDesc(m1, m2);

    // MH3: Genres
    final (genreScore, commonGenresList) = _mangaGenreOverlap(m1, m2);

    // MH4: Tags
    final (tagScore, commonTagsList) = _mangaTagOverlap(m1, m2);

    // MH5: Favourite Manga
    final (favMangaScore, favMangaIds, favMangaCount) =
        f1 != null && f2 != null
            ? _favouriteMangaOverlap(f1, f2)
            : (0.0, <int>[], 0);

    final scores = [
      _H(readStatsScore, _mangaReadStatsWeight),
      _H(releaseYearScore, _mangaReleaseYearWeight),
      _H(genreScore, _mangaGenreWeight),
      _H(tagScore, _mangaTagWeight),
      _H(favMangaScore, _favouriteMangaWeight),
    ];

    final (pct, rank) = _weightedResult(scores);

    final breakdown = [
      _hs('mangaReadStats', 'Read Stats', readStatsDesc, readStatsScore, _mangaReadStatsWeight),
      _hs('mangaReleaseYear', 'Release Years', releaseYearDesc, releaseYearScore, _mangaReleaseYearWeight),
      _hs('mangaGenres', 'Common Genres', '${commonGenresList.length} shared top genres', genreScore, _mangaGenreWeight),
      _hs('mangaTags', 'Common Tags', '${commonTagsList.length} shared top tags', tagScore, _mangaTagWeight),
      _hs('favouriteManga', 'Fav Manga', '$favMangaCount shared favourite manga', favMangaScore, _favouriteMangaWeight),
    ];

    return _SectionResult(
      percentage: pct,
      rank: rank.name,
      rankDescription: rank.description,
      breakdown: breakdown,
      favMangaIds: favMangaIds,
      genreNames: commonGenresList,
      tagNames: commonTagsList,
    );
  }

  // ============================================================
  // ANIME HEURISTICS (same as before)
  // ============================================================

  // H1: Watch Stats
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

  // H2: Release Year Stats
  static double _releaseYearOverlap(AnimeStats a, AnimeStats b) {
    final aDecades = _toDecadeDistribution(a.releaseYears);
    final bDecades = _toDecadeDistribution(b.releaseYears);
    return _cosineSimilarity(aDecades, bDecades);
  }

  static String _releaseYearDesc(AnimeStats a, AnimeStats b) {
    final aTop = _topDecade(a.releaseYears);
    final bTop = _topDecade(b.releaseYears);
    return aTop != null && bTop != null
        ? '${_decadeLabel(aTop)} vs ${_decadeLabel(bTop)}'
        : 'Insufficient data';
  }

  // H3: Genres
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

  // H4: Tags
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

  // H5: Perfect Anime
  static (double, int) _jaccardIds(List<int> a, List<int> b) {
    final aSet = a.toSet();
    final bSet = b.toSet();
    final common = aSet.intersection(bSet).length;
    final union = aSet.union(bSet).length;
    if (union == 0) return (0.0, 0);
    return (common / union, common);
  }

  // H6: Favourite Anime
  static (double, List<int>, int) _favouriteAnimeOverlap(
      ProfileFavourites f1, ProfileFavourites f2) {
    final aIds = f1.anime.map((a) => int.tryParse(a.id ?? '') ?? 0).toSet();
    final bIds = f2.anime.map((a) => int.tryParse(a.id ?? '') ?? 0).toSet();
    final common = aIds.intersection(bIds);
    final union = aIds.union(bIds);
    if (union.isEmpty) return (0.0, [], 0);
    return (common.length / union.length, common.toList(), common.length);
  }

  // H7: Favourite Characters
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

  // H8: Voice Actors
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
      if (commonIds.contains(va.id)) commonNames.add(va.name);
    }
    final union = aSet.union(bSet).length;
    return (commonIds.length / union, commonNames);
  }

  // H9: Studios
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
      if (commonIds.contains(s.id)) commonNames.add(s.name);
    }
    final union = aSet.union(bSet).length;
    return (commonIds.length / union, commonNames);
  }

  // H10: Favourite Staff
  static (double, List<String>) _favouriteStaffOverlap(
      ProfileFavourites f1, ProfileFavourites f2) {
    final aIds = f1.staff.map((s) => s.id ?? '').where((id) => id.isNotEmpty).toSet();
    final bIds = f2.staff.map((s) => s.id ?? '').where((id) => id.isNotEmpty).toSet();
    if (aIds.isEmpty || bIds.isEmpty) return (0.0, []);
    final commonIds = aIds.intersection(bIds);
    final commonNames = <String>[];
    for (final s in f1.staff) {
      if (commonIds.contains(s.id)) commonNames.add(s.name ?? 'Unknown');
    }
    final union = aIds.union(bIds).length;
    return (commonIds.length / union, commonNames);
  }

  // ============================================================
  // MANGA HEURISTICS
  // ============================================================

  // MH1: Read Stats
  static double _mangaReadStats(MangaStats a, MangaStats b) {
    final aCount = _parseD(a.mangaCount);
    final bCount = _parseD(b.mangaCount);
    final aChaps = _parseD(a.chaptersRead);
    final bChaps = _parseD(b.chaptersRead);
    final aVols = _parseD(a.volumesRead);
    final bVols = _parseD(b.volumesRead);
    final aScore = _parseD(a.meanScore);
    final bScore = _parseD(b.meanScore);

    final countSim = _dimSimilarity(aCount, bCount);
    final chapsSim = _dimSimilarity(aChaps, bChaps);
    final volsSim = _dimSimilarity(aVols, bVols);
    final scoreSim = 1 - (aScore - bScore).abs() / 100;

    return (countSim + chapsSim + volsSim + scoreSim) / 4;
  }

  static String _mangaReadStatsDesc(MangaStats a, MangaStats b) {
    return '${_parseI(a.mangaCount)} vs ${_parseI(b.mangaCount)} entries';
  }

  // MH2: Release Years (cosine on decade distributions)
  static double _mangaReleaseYearOverlap(MangaStats a, MangaStats b) {
    final aDecades = _toDecadeDistribution(a.releaseYears);
    final bDecades = _toDecadeDistribution(b.releaseYears);
    return _cosineSimilarity(aDecades, bDecades);
  }

  static String _mangaReleaseYearDesc(MangaStats a, MangaStats b) {
    final aTop = _topDecade(a.releaseYears);
    final bTop = _topDecade(b.releaseYears);
    return aTop != null && bTop != null
        ? '${_decadeLabel(aTop)} vs ${_decadeLabel(bTop)}'
        : 'Insufficient data';
  }

  // MH3: Genres
  static (double, List<String>) _mangaGenreOverlap(MangaStats a, MangaStats b) {
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

  // MH4: Tags
  static (double, List<String>) _mangaTagOverlap(MangaStats a, MangaStats b) {
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

  // MH5: Favourite Manga
  static (double, List<int>, int) _favouriteMangaOverlap(
      ProfileFavourites f1, ProfileFavourites f2) {
    final aIds =
        f1.manga.map((m) => int.tryParse(m.id ?? '') ?? 0).toSet();
    final bIds =
        f2.manga.map((m) => int.tryParse(m.id ?? '') ?? 0).toSet();
    final common = aIds.intersection(bIds);
    final union = aIds.union(bIds);
    if (union.isEmpty) return (0.0, [], 0);
    return (common.length / union.length, common.toList(), common.length);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double _parseD(String? s) => double.tryParse(s ?? '') ?? 0.0;
  static int _parseI(String? s) => int.tryParse(s ?? '') ?? 0;

  static double _dimSimilarity(double a, double b) {
    final maxVal = [a, b, 1.0].reduce((x, y) => x > y ? x : y);
    return 1 - (a - b).abs() / maxVal;
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

  static double _cosineSimilarity(Map<int, double> a, Map<int, double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final allKeys = {...a.keys, ...b.keys}.toList()..sort();
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    for (final key in allKeys) {
      final va = a[key] ?? 0.0;
      final vb = b[key] ?? 0.0;
      dotProduct += va * vb;
      normA += va * va;
      normB += vb * vb;
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom > 0 ? (dotProduct / denom).clamp(0.0, 1.0) : 0.0;
  }

  static List<GenreStat> _aboveAverageGenres(
      List<GenreStat> genres, double avg) {
    if (avg <= 0)
      return genres.toList()..sort((a, b) => b.count.compareTo(a.count));
    final filtered = genres.where((g) => g.meanScore > avg).toList();
    if (filtered.isEmpty)
      return genres.toList()..sort((a, b) => b.count.compareTo(a.count));
    filtered.sort((a, b) => b.count.compareTo(a.count));
    return filtered;
  }

  static List<TagStat> _aboveAverageTags(List<TagStat> tags, double avg) {
    if (avg <= 0) return tags.toList()..sort((a, b) => b.count.compareTo(a.count));
    final filtered = tags.where((t) => t.meanScore > avg).toList();
    if (filtered.isEmpty)
      return tags.toList()..sort((a, b) => b.count.compareTo(a.count));
    filtered.sort((a, b) => b.count.compareTo(a.count));
    return filtered;
  }

  static HeuristicScore _hs(
    String key,
    String label,
    String description,
    double score,
    double weight,
  ) {
    return HeuristicScore(
      key: key,
      label: label,
      description: description,
      score: score,
      weight: weight,
      weightedScore: score * weight,
    );
  }

  static (double, RankInfo) _weightedResult(List<_H> scores) {
    double totalWeight = 0;
    double weightedSum = 0;
    for (final s in scores) {
      weightedSum += s.score * s.weight;
      totalWeight += s.weight;
    }
    final pct = totalWeight > 0 ? (weightedSum / totalWeight) * 100 : 0.0;
    final clamped = pct.clamp(0.0, 100.0);
    return (clamped, getRankForScore(clamped));
  }

  static MangaFormatSplit? _mangaFormatSplit(MangaStats? m) {
    if (m == null || m.formats.isEmpty) return null;
    final total = m.formats.fold<int>(0, (s, f) => s + f.count);
    if (total == 0) return null;
    double manga = 0, ln = 0, novel = 0;
    for (final f in m.formats) {
      final pct = (f.count / total) * 100;
      switch (f.type.toUpperCase()) {
        case 'MANGA':
          manga += pct;
        case 'LIGHT_NOVEL':
          ln += pct;
        case 'NOVEL':
          novel += pct;
      }
    }
    return MangaFormatSplit(
      mangaPercent: manga,
      lightNovelPercent: ln,
      novelPercent: novel,
    );
  }
}

// ============================================================
// Internal types
// ============================================================

class _H {
  final double score;
  final double weight;
  const _H(this.score, this.weight);
}

/// Internal result carrying extra data that gets promoted to CompatibilityResult.
class _SectionResult {
  final double percentage;
  final String rank;
  final String rankDescription;
  final List<HeuristicScore> breakdown;
  final bool hasData;

  // Extra fields (not all used by every section)
  final List<int> _favAnimeIds;
  final List<int> _favMangaIds;
  final List<int> _favCharIds;
  final List<String> _staffIds;
  final List<String> _genreNames;
  final List<String> _tagNames;
  final List<String> _studioNames;
  final List<String> _vaNames;

  const _SectionResult({
    this.percentage = 0,
    this.rank = 'N/A',
    this.rankDescription = '',
    this.breakdown = const [],
    this.hasData = true,
    List<int> favAnimeIds = const [],
    List<int> favMangaIds = const [],
    List<int> favCharIds = const [],
    List<String> staffIds = const [],
    List<String> genreNames = const [],
    List<String> tagNames = const [],
    List<String> studioNames = const [],
    List<String> vaNames = const [],
  })  : _favAnimeIds = favAnimeIds,
        _favMangaIds = favMangaIds,
        _favCharIds = favCharIds,
        _staffIds = staffIds,
        _genreNames = genreNames,
        _tagNames = tagNames,
        _studioNames = studioNames,
        _vaNames = vaNames;

  factory _SectionResult.noData() => _SectionResult(hasData: false);

  CompatibilitySection toSection() => CompatibilitySection(
        percentage: percentage,
        rank: rank,
        rankDescription: rankDescription,
        breakdown: breakdown,
        hasData: hasData,
      );
}
