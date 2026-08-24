import 'dart:math';

import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';

class Matchmaker {
  static const double _expoWeightingFactor = 1.0 / 3.0;

  static const _watchStatsWeight = 0.25;
  static const _releaseYearWeight = 0.80;
  static const _genreWeight = 1.50;
  static const _tagWeight = 1.50;
  static const _perfectAnimeWeight = 2.00;
  static const _favouriteAnimeWeight = 4.00;
  static const _favouriteCharWeight = 0.80;
  static const _voiceActorWeight = 0.50;
  static const _studioWeight = 0.90;
  static const _staffWeight = 0.50;

  static const _mangaReadStatsWeight = 0.25;
  static const _mangaReleaseYearWeight = 0.80;
  static const _mangaGenreWeight = 1.50;
  static const _mangaTagWeight = 1.50;
  static const _favouriteMangaWeight = 4.00;
  static const _perfectMangaWeight = 2.00;

  static CompatibilityResult compute(
    Profile user1,
    Profile user2, {
    List<int>? user1PerfectAnimeIds,
    List<int>? user2PerfectAnimeIds,
    List<int>? user1PerfectMangaIds,
    List<int>? user2PerfectMangaIds,
    List<FavouriteMedia>? sharedAnimeList,
    List<FavouriteMedia>? sharedMangaList,
  }) {
    final a = user1.stats?.animeStats;
    final b = user2.stats?.animeStats;
    final m1 = user1.stats?.mangaStats;
    final m2 = user2.stats?.mangaStats;
    final f1 = user1.favourites;
    final f2 = user2.favourites;

    final p1Anime = user1PerfectAnimeIds ?? user1.perfectAnimeIds;
    final p2Anime = user2PerfectAnimeIds ?? user2.perfectAnimeIds;
    final p1Manga = user1PerfectMangaIds ?? user1.perfectMangaIds;
    final p2Manga = user2PerfectMangaIds ?? user2.perfectMangaIds;

    final animeResult = _computeAnimeSection(
      a,
      b,
      f1,
      f2,
      p1Anime,
      p2Anime,
      user1.perfectAnimeList,
      user2.perfectAnimeList,
      sharedAnimeMedia: sharedAnimeList,
    );

    final mangaResult = _computeMangaSection(
      m1,
      m2,
      f1,
      f2,
      p1Manga,
      p2Manga,
      user1.perfectMangaList,
      user2.perfectMangaList,
      sharedMangaMedia: sharedMangaList,
    );

    final double overallPct;
    if (animeResult.hasData && mangaResult.hasData) {
      final aCount1 = _parseI(a?.animeCount);
      final aCount2 = _parseI(b?.animeCount);
      final mCount1 = _parseI(m1?.mangaCount);
      final mCount2 = _parseI(m2?.mangaCount);

      final totalAnime = (aCount1 + aCount2).clamp(1, 1000000);
      final totalManga = (mCount1 + mCount2).clamp(1, 1000000);
      final total = totalAnime + totalManga;

      final rawAnimeWeight = totalAnime / total;
      final animeWeight = rawAnimeWeight.clamp(0.35, 0.65);
      final mangaWeight = 1.0 - animeWeight;

      overallPct = (animeResult.percentage * animeWeight) + (mangaResult.percentage * mangaWeight);
    } else if (animeResult.hasData) {
      overallPct = animeResult.percentage;
    } else if (mangaResult.hasData) {
      overallPct = mangaResult.percentage;
    } else {
      overallPct = 0.0;
    }
    final clampedPct = overallPct.clamp(0.0, 100.0);
    final overallRank = getRankForScore(clampedPct.roundToDouble());

    final allBreakdown = <HeuristicScore>[
      ...animeResult.breakdown,
      ...mangaResult.breakdown,
    ];

    final u1Split = _mangaFormatSplit(m1);
    final u2Split = _mangaFormatSplit(m2);

    return CompatibilityResult(
      percentage: clampedPct,
      rank: overallRank.name,
      rankDescription: overallRank.getFormattedDescription(clampedPct),
      animeSection: animeResult,
      mangaSection: mangaResult,
      breakdown: allBreakdown,
      user1FormatSplit: u1Split,
      user2FormatSplit: u2Split,
    );
  }

  static CompatibilitySection _computeAnimeSection(
    AnimeStats? a,
    AnimeStats? b,
    ProfileFavourites? f1,
    ProfileFavourites? f2,
    List<int>? user1PerfectIds,
    List<int>? user2PerfectIds,
    List<FavouriteMedia>? user1PerfectList,
    List<FavouriteMedia>? user2PerfectList, {
    List<FavouriteMedia>? sharedAnimeMedia,
  }) {
    if (a == null || b == null) {
      return CompatibilitySection.noData();
    }

    final hasWatchData = (_parseI(a.animeCount) > 0 || _parseI(a.episodesWatched) > 0) &&
        (_parseI(b.animeCount) > 0 || _parseI(b.episodesWatched) > 0);
    if (!hasWatchData && (f1?.anime.isEmpty ?? true) && (f2?.anime.isEmpty ?? true)) {
      return CompatibilitySection.noData();
    }

    final watchStatsScore = _watchStats(a, b);
    final watchStatsDesc = _watchStatsDesc(a, b);
    final watchStatsCards = _buildWatchStatsCards(a, b);

    final (releaseYearScore, releaseYearCards, releaseYearActive) = _computeReleaseYearOverlap(
      a.releaseYears,
      b.releaseYears,
      _parseD(a.minutesWatched),
      _parseD(b.minutesWatched),
      _parseD(a.meanScore),
      _parseD(b.meanScore),
    );
    final releaseYearDesc = _releaseYearDesc(a.releaseYears, b.releaseYears);

    final (perfectScore, perfectCount, perfectActive, commonPerfectAnime) =
        _computePerfectMediaOverlap(user1PerfectIds, user2PerfectIds, user1PerfectList, user2PerfectList);

    final (favAnimeScore, favAnimeList, favAnimeIds, favAnimeCount, favAnimeActive) =
        _computeFavouriteMediaOverlap(f1?.anime, f2?.anime);

    final sharedAnimeList = _deduplicateMedia([sharedAnimeMedia, favAnimeList, commonPerfectAnime]);

    final (genreScore, commonGenresList, genreCards, genreActive) = _genreOverlapDetailed(
      genresA: a.genres,
      genresB: b.genres,
      meanScoreA: a.meanScore,
      meanScoreB: b.meanScore,
      mediaList: sharedAnimeList,
    );

    final (tagScore, commonTagsList, tagCards, tagActive) = _tagOverlapDetailed(
      tagsA: a.tags,
      tagsB: b.tags,
      meanScoreA: a.meanScore,
      meanScoreB: b.meanScore,
      mediaList: sharedAnimeList,
    );

    final (favCharScore, favCharList, favCharIds, favCharCount, favCharActive) =
        _favouriteCharacterOverlapDetailed(f1, f2);

    final (vaScore, vaCards, vaNames, vaActive) = _voiceActorOverlapDetailed(a, b);

    final (studioScore, studioCards, studioNames, studioActive) = _studioOverlapDetailed(a, b);

    final (staffScore, staffList, staffNames, staffActive) = _favouriteStaffOverlapDetailed(f1, f2);

    final scores = [
      _H(watchStatsScore, _watchStatsWeight, isActive: true),
      _H(releaseYearScore, _releaseYearWeight, isActive: releaseYearActive),
      _H(genreScore, _genreWeight, isActive: genreActive),
      _H(tagScore, _tagWeight, isActive: tagActive),
      _H(perfectScore, _perfectAnimeWeight, isActive: perfectActive),
      _H(favAnimeScore, _favouriteAnimeWeight, isActive: favAnimeActive),
      _H(favCharScore, _favouriteCharWeight, isActive: favCharActive),
      _H(vaScore, _voiceActorWeight, isActive: vaActive),
      _H(studioScore, _studioWeight, isActive: studioActive),
      _H(staffScore, _staffWeight, isActive: staffActive),
    ];

    final (pct, rank) = _weightedResult(scores);

    final details = <HeuristicDetail>[
      HeuristicDetail(
        key: 'watchStats',
        title: 'Watch Stats',
        description: watchStatsDesc,
        score: watchStatsScore,
        weight: _watchStatsWeight,
        cards: watchStatsCards,
      ),
      HeuristicDetail(
        key: 'releaseYear',
        title: 'Release Year Stats',
        description: releaseYearDesc,
        score: releaseYearScore,
        weight: _releaseYearWeight,
        cards: releaseYearCards,
        hasData: releaseYearActive,
      ),
      HeuristicDetail(
        key: 'genres',
        title: 'Common Genres',
        description: 'Based on your top 5 genres.',
        score: genreScore,
        weight: _genreWeight,
        cards: genreCards,
        hasData: genreActive,
      ),
      HeuristicDetail(
        key: 'tags',
        title: 'Common Tags',
        description: 'Based on your top 10 tags.',
        score: tagScore,
        weight: _tagWeight,
        cards: tagCards,
        hasData: tagActive,
      ),
      HeuristicDetail(
        key: 'perfectAnime',
        title: 'Common Perfect Anime',
        description: 'Based on anime you\'ve scored as 10/10.',
        score: perfectScore,
        weight: _perfectAnimeWeight,
        mediaItems: commonPerfectAnime,
        hasData: perfectActive,
      ),
      HeuristicDetail(
        key: 'favouriteAnime',
        title: 'Common Favourite Anime',
        description: 'Based on your favourite anime.',
        score: favAnimeScore,
        weight: _favouriteAnimeWeight,
        mediaItems: favAnimeList,
        hasData: favAnimeActive,
      ),
      HeuristicDetail(
        key: 'favouriteCharacters',
        title: 'Common Favourite Characters',
        description: 'Based on your favourite characters.',
        score: favCharScore,
        weight: _favouriteCharWeight,
        characterItems: favCharList,
        hasData: favCharActive,
      ),
      HeuristicDetail(
        key: 'voiceActors',
        title: 'Common Voice Actors',
        description: 'Based on your top 6 voice actors.',
        score: vaScore,
        weight: _voiceActorWeight,
        cards: vaCards,
        hasData: vaActive,
      ),
      HeuristicDetail(
        key: 'studios',
        title: 'Common Studios',
        description: 'Based on your top 3 studios.',
        score: studioScore,
        weight: _studioWeight,
        cards: studioCards,
        hasData: studioActive,
      ),
      HeuristicDetail(
        key: 'staff',
        title: 'Common Favourite Staff',
        description: 'Based on your favourite staff.',
        score: staffScore,
        weight: _staffWeight,
        staffItems: staffList,
        hasData: staffActive,
      ),
    ];

    final breakdown = details.where((d) => d.hasData).map((d) => d.toScore()).toList();

    return CompatibilitySection(
      percentage: pct,
      rank: rank.name,
      rankDescription: rank.getFormattedDescription(pct),
      breakdown: breakdown,
      details: details,
    );
  }

  static CompatibilitySection _computeMangaSection(
    MangaStats? m1,
    MangaStats? m2,
    ProfileFavourites? f1,
    ProfileFavourites? f2,
    List<int>? user1PerfectIds,
    List<int>? user2PerfectIds,
    List<FavouriteMedia>? user1PerfectList,
    List<FavouriteMedia>? user2PerfectList, {
    List<FavouriteMedia>? sharedMangaMedia,
  }) {
    if (m1 == null || m2 == null) {
      return CompatibilitySection.noData();
    }

    final hasReadData = (_parseI(m1.mangaCount) > 0 || _parseI(m1.chaptersRead) > 0) &&
        (_parseI(m2.mangaCount) > 0 || _parseI(m2.chaptersRead) > 0);
    if (!hasReadData && (f1?.manga.isEmpty ?? true) && (f2?.manga.isEmpty ?? true)) {
      return CompatibilitySection.noData();
    }

    final readStatsScore = _mangaReadStats(m1, m2);
    final readStatsDesc = _mangaReadStatsDesc(m1, m2);
    final readStatsCards = _buildMangaReadStatsCards(m1, m2);

    final (releaseYearScore, releaseYearCards, releaseYearActive) = _computeReleaseYearOverlap(
      m1.releaseYears,
      m2.releaseYears,
      _parseD(m1.chaptersRead),
      _parseD(m2.chaptersRead),
      _parseD(m1.meanScore),
      _parseD(m2.meanScore),
    );
    final releaseYearDesc = _releaseYearDesc(m1.releaseYears, m2.releaseYears);

    final (favMangaScore, favMangaList, favMangaIds, favMangaCount, favMangaActive) =
        _computeFavouriteMediaOverlap(f1?.manga, f2?.manga);

    final (perfectScore, perfectCount, perfectActive, commonPerfectManga) =
        _computePerfectMediaOverlap(user1PerfectIds, user2PerfectIds, user1PerfectList, user2PerfectList);

    final sharedMangaList = _deduplicateMedia([sharedMangaMedia, favMangaList, commonPerfectManga]);

    final (genreScore, commonGenresList, genreCards, genreActive) = _genreOverlapDetailed(
      genresA: m1.genres,
      genresB: m2.genres,
      meanScoreA: m1.meanScore,
      meanScoreB: m2.meanScore,
      mediaList: sharedMangaList,
    );

    final (tagScore, commonTagsList, tagCards, tagActive) = _tagOverlapDetailed(
      tagsA: m1.tags,
      tagsB: m2.tags,
      meanScoreA: m1.meanScore,
      meanScoreB: m2.meanScore,
      mediaList: sharedMangaList,
    );

    final scores = [
      _H(readStatsScore, _mangaReadStatsWeight, isActive: true),
      _H(releaseYearScore, _mangaReleaseYearWeight, isActive: releaseYearActive),
      _H(genreScore, _mangaGenreWeight, isActive: genreActive),
      _H(tagScore, _mangaTagWeight, isActive: tagActive),
      _H(favMangaScore, _favouriteMangaWeight, isActive: favMangaActive),
      _H(perfectScore, _perfectMangaWeight, isActive: perfectActive),
    ];

    final (pct, rank) = _weightedResult(scores);

    final details = <HeuristicDetail>[
      HeuristicDetail(
        key: 'mangaReadStats',
        title: 'Read Stats',
        description: readStatsDesc,
        score: readStatsScore,
        weight: _mangaReadStatsWeight,
        cards: readStatsCards,
      ),
      HeuristicDetail(
        key: 'mangaReleaseYear',
        title: 'Release Year Stats',
        description: releaseYearDesc,
        score: releaseYearScore,
        weight: _mangaReleaseYearWeight,
        cards: releaseYearCards,
        hasData: releaseYearActive,
      ),
      HeuristicDetail(
        key: 'mangaGenres',
        title: 'Common Genres',
        description: 'Based on your top 5 manga genres.',
        score: genreScore,
        weight: _mangaGenreWeight,
        cards: genreCards,
        hasData: genreActive,
      ),
      HeuristicDetail(
        key: 'mangaTags',
        title: 'Common Tags',
        description: 'Based on your top 10 manga tags.',
        score: tagScore,
        weight: _mangaTagWeight,
        cards: tagCards,
        hasData: tagActive,
      ),
      HeuristicDetail(
        key: 'favouriteManga',
        title: 'Common Favourite Manga',
        description: 'Based on your favourite manga.',
        score: favMangaScore,
        weight: _favouriteMangaWeight,
        mediaItems: favMangaList,
        hasData: favMangaActive,
      ),
      HeuristicDetail(
        key: 'perfectManga',
        title: 'Common Perfect Manga',
        description: 'Based on manga you\'ve scored as 10/10.',
        score: perfectScore,
        weight: _perfectMangaWeight,
        mediaItems: commonPerfectManga,
        hasData: perfectActive,
      ),
    ];

    final breakdown = details.where((d) => d.hasData).map((d) => d.toScore()).toList();

    return CompatibilitySection(
      percentage: pct,
      rank: rank.name,
      rankDescription: rank.getFormattedDescription(pct),
      breakdown: breakdown,
      details: details,
    );
  }

  static double _computeStatsSimilarity({
    required double completedA,
    required double completedB,
    required double volumeA,
    required double volumeB,
    required double unitsA,
    required double unitsB,
    required double scoreA,
    required double scoreB,
  }) {
    final countSim = _minMaxRatio(completedA, completedB);
    final volSim = _minMaxRatio(volumeA, volumeB);
    final unitsSim = _minMaxRatio(unitsA, unitsB);
    final scoreSim = _scoreSimilarity(scoreA, scoreB);
    return (countSim + volSim + unitsSim + scoreSim) / 4.0;
  }

  
  static double _watchStats(AnimeStats a, AnimeStats b) => _computeStatsSimilarity(
        completedA: _getCompletedCount(a.statuses, a.animeCount),
        completedB: _getCompletedCount(b.statuses, b.animeCount),
        volumeA: _parseD(a.minutesWatched) / 60.0,
        volumeB: _parseD(b.minutesWatched) / 60.0,
        unitsA: _parseD(a.episodesWatched),
        unitsB: _parseD(b.episodesWatched),
        scoreA: _parseD(a.meanScore),
        scoreB: _parseD(b.meanScore),
      );

  static String _watchStatsDesc(AnimeStats a, AnimeStats b) {
    return '${_parseI(a.animeCount)} vs ${_parseI(b.animeCount)} anime';
  }

  static String _releaseYearDesc(List<YearStat> aYears, List<YearStat> bYears) {
    final aTop = _topDecade(aYears);
    final bTop = _topDecade(bYears);
    return aTop != null && bTop != null
        ? '${_decadeLabel(aTop)} vs ${_decadeLabel(bTop)}'
        : 'Decades comparison';
  }

  static double _mangaReadStats(MangaStats a, MangaStats b) => _computeStatsSimilarity(
        completedA: _getCompletedCount(a.statuses, a.mangaCount),
        completedB: _getCompletedCount(b.statuses, b.mangaCount),
        volumeA: _parseD(a.volumesRead),
        volumeB: _parseD(b.volumesRead),
        unitsA: _parseD(a.chaptersRead),
        unitsB: _parseD(b.chaptersRead),
        scoreA: _parseD(a.meanScore),
        scoreB: _parseD(b.meanScore),
      );

  static String _mangaReadStatsDesc(MangaStats a, MangaStats b) {
    return '${_parseI(a.mangaCount)} vs ${_parseI(b.mangaCount)} entries';
  }
 

  static double _parseD(String? s) => double.tryParse(s ?? '') ?? 0.0;
  static int _parseI(String? s) => int.tryParse(s ?? '') ?? 0;

  static double _minMaxRatio(double a, double b) {
    if (a <= 0 && b <= 0) return 1.0;
    final maxVal = max(a, b);
    if (maxVal <= 0) return 1.0;
    final minVal = min(a, b);
    return (minVal / maxVal).clamp(0.0, 1.0);
  }

  static double _scoreSimilarity(double aScore, double bScore) {
    if (aScore <= 0 && bScore <= 0) return 1.0;
    if (aScore <= 0 || bScore <= 0) return 0.5;
    return (1.0 - (aScore - bScore).abs() / 100.0).clamp(0.0, 1.0);
  }

  static (double, int) _jaccardExponential(Set<int> aSet, Set<int> bSet, double maxLen) {
    if (aSet.isEmpty || bSet.isEmpty) return (0.0, 0);
    final common = aSet.intersection(bSet).length;
    if (common == 0) return (0.0, 0);
    final ratio = (common / maxLen).clamp(0.0, 1.0);
    final score = pow(ratio, _expoWeightingFactor).toDouble().clamp(0.0, 1.0);
    return (score, common);
  }

  static double _getCompletedCount(List<TypeStat> statuses, String? countFallback) {
    for (final s in statuses) {
      if (s.type.toUpperCase() == 'COMPLETED') {
        return s.count.toDouble();
      }
    }
    return _parseD(countFallback);
  }

  static List<HeuristicCardData> _buildTotalsCard(List<StatComparisonRow> rows) => [
        HeuristicCardData(title: 'Totals', rows: rows),
      ];

  static List<HeuristicCardData> _buildWatchStatsCards(AnimeStats a, AnimeStats b) => _buildTotalsCard([
        StatComparisonRow(
          user1Value: '${_getCompletedCount(a.statuses, a.animeCount).toInt()}',
          label: 'Anime Completed',
          user2Value: '${_getCompletedCount(b.statuses, b.animeCount).toInt()}',
        ),
        StatComparisonRow(
          user1Value: '${_parseI(a.episodesWatched)}',
          label: 'Episodes Watched',
          user2Value: '${_parseI(b.episodesWatched)}',
        ),
        StatComparisonRow(
          user1Value: '${(_parseD(a.minutesWatched) / 60.0).round()}',
          label: 'Hours Watched',
          user2Value: '${(_parseD(b.minutesWatched) / 60.0).round()}',
        ),
        StatComparisonRow(
          user1Value: _parseD(a.meanScore).toStringAsFixed(2),
          label: 'Mean Score',
          user2Value: _parseD(b.meanScore).toStringAsFixed(2),
        ),
      ]);

  static List<HeuristicCardData> _buildMangaReadStatsCards(MangaStats a, MangaStats b) => _buildTotalsCard([
        StatComparisonRow(
          user1Value: '${_getCompletedCount(a.statuses, a.mangaCount).toInt()}',
          label: 'Manga Completed',
          user2Value: '${_getCompletedCount(b.statuses, b.mangaCount).toInt()}',
        ),
        StatComparisonRow(
          user1Value: '${_parseI(a.chaptersRead)}',
          label: 'Chapters Read',
          user2Value: '${_parseI(b.chaptersRead)}',
        ),
        StatComparisonRow(
          user1Value: '${_parseI(a.volumesRead)}',
          label: 'Volumes Read',
          user2Value: '${_parseI(b.volumesRead)}',
        ),
        StatComparisonRow(
          user1Value: _parseD(a.meanScore).toStringAsFixed(2),
          label: 'Mean Score',
          user2Value: _parseD(b.meanScore).toStringAsFixed(2),
        ),
      ]);

  static (double, List<HeuristicCardData>, bool) _computeReleaseYearOverlap(
    List<YearStat> yearsA,
    List<YearStat> yearsB,
    double totalVolA,
    double totalVolB,
    double meanScoreA,
    double meanScoreB,
  ) {
    if (yearsA.isEmpty || yearsB.isEmpty) return (0.0, [], false);

    final aDecades = _stackYearsIntoDecades(yearsA);
    final bDecades = _stackYearsIntoDecades(yearsB);
    if (aDecades.isEmpty || bDecades.isEmpty) return (0.0, [], false);

    final allDecades = {...aDecades.keys, ...bDecades.keys}.toList()..sort();
    double totalDecadeScore = 0.0;
    double totalDecadeWeight = 0.0;
    final cards = <HeuristicCardData>[];

    for (final decade in allDecades) {
      final dataA = aDecades[decade];
      final dataB = bDecades[decade];
      final volA = dataA?.minutesWatched ?? 0.0;
      final volB = dataB?.minutesWatched ?? 0.0;

      final propA = totalVolA > 0 ? (volA / totalVolA) : 0.0;
      final propB = totalVolB > 0 ? (volB / totalVolB) : 0.0;

      final hasDataA = dataA != null && dataA.count > 0 && volA > 0;
      final hasDataB = dataB != null && dataB.count > 0 && volB > 0;
      final deltaA = hasDataA ? dataA.meanScore - meanScoreA : 0.0;
      final deltaB = hasDataB ? dataB.meanScore - meanScoreB : 0.0;

      if (propA >= 0.01 || propB >= 0.01) {
        final propStrA = '${(propA * 100).round()}%';
        final propStrB = '${(propB * 100).round()}%';
        final deltaStrA = hasDataA ? '${deltaA >= 0 ? '+' : ''}${deltaA.toStringAsFixed(2)}' : '-';
        final deltaStrB = hasDataB ? '${deltaB >= 0 ? '+' : ''}${deltaB.toStringAsFixed(2)}' : '-';

        cards.add(HeuristicCardData(
          title: '${decade}s',
          rows: [
            StatComparisonRow(user1Value: propStrA, label: 'Proportion of Total Time Watched', user2Value: propStrB),
            StatComparisonRow(user1Value: deltaStrA, label: 'Difference from own Mean Score', user2Value: deltaStrB),
          ],
        ));

        if (propA >= 0.005 && propB >= 0.005 && hasDataA && hasDataB) {
          final timeScore = _minMaxRatio(propA, propB);
          final deltaDiff = (deltaA - deltaB).abs() / 25.0;
          final scoreDeltaScore = (1.0 - deltaDiff).clamp(0.0, 1.0);
          final decadeSim = (timeScore * 0.5) + (scoreDeltaScore * 0.5);

          final decadeWeight = ((propA + propB) / 2.0).clamp(0.05, 1.0);
          totalDecadeScore += decadeSim * decadeWeight;
          totalDecadeWeight += decadeWeight;
        }
      }
    }

    if (totalDecadeWeight == 0.0) {
      final sim = _cosineSimilarity(_toDecadeDistribution(yearsA), _toDecadeDistribution(yearsB));
      return (sim, cards, cards.isNotEmpty);
    }

    final finalScore = (totalDecadeScore / totalDecadeWeight).clamp(0.0, 1.0);
    return (finalScore, cards, true);
  }

  static List<FavouriteMedia> _findMatchingCommonMedia(String term, List<FavouriteMedia> commonMediaList) {
    if (commonMediaList.isEmpty) return const [];
    final termLower = term.trim().toLowerCase();
    final matched = <FavouriteMedia>[];

    for (final m in commonMediaList) {
      final hasGenre = m.genres.any((g) => g.trim().toLowerCase() == termLower);
      final hasTag = m.tags.any((t) => t.trim().toLowerCase() == termLower);
      if (hasGenre || hasTag) {
        matched.add(m);
      }
    }
    return matched;
  }

  static (double, List<String>, List<HeuristicCardData>, bool) _computeTaxonomyOverlap<T extends Object>({
    required List<T> listA,
    required double avgA,
    required List<T> listB,
    required double avgB,
    required int maxTop,
    required double expectedMax,
    required String Function(T) getName,
    required double Function(T) getMeanScore,
    required int Function(T) getCount,
    List<FavouriteMedia> mediaList = const [],
  }) {
    final aTop = _aboveAverageEntities(listA, avgA, getMeanScore: getMeanScore, getCount: getCount);
    final bTop = _aboveAverageEntities(listB, avgB, getMeanScore: getMeanScore, getCount: getCount);
    if (aTop.isEmpty || bTop.isEmpty) return (0.0, [], [], false);

    final aMap = <String, T>{};
    for (final item in aTop.take(maxTop)) {
      final key = getName(item).trim().toLowerCase();
      if (key.isNotEmpty) aMap[key] = item;
    }
    final bMap = <String, T>{};
    for (final item in bTop.take(maxTop)) {
      final key = getName(item).trim().toLowerCase();
      if (key.isNotEmpty) bMap[key] = item;
    }

    final aSet = aMap.keys.toSet();
    final bSet = bMap.keys.toSet();
    if (aSet.isEmpty || bSet.isEmpty) return (0.0, [], [], false);

    final commonKeys = aSet.intersection(bSet).toList();
    if (commonKeys.isEmpty) return (0.0, <String>[], <HeuristicCardData>[], false);

    commonKeys.sort((k1, k2) {
      final statA1 = aMap[k1]!;
      final statB1 = bMap[k1]!;
      final statA2 = aMap[k2]!;
      final statB2 = bMap[k2]!;

      final score1 = ((getMeanScore(statA1) + getMeanScore(statB1)) / 2.0) -
          (getMeanScore(statA1) - getMeanScore(statB1)).abs() * 0.4 +
          min(10.0, min(getCount(statA1), getCount(statB1)).toDouble()) * 0.5;

      final score2 = ((getMeanScore(statA2) + getMeanScore(statB2)) / 2.0) -
          (getMeanScore(statA2) - getMeanScore(statB2)).abs() * 0.4 +
          min(10.0, min(getCount(statA2), getCount(statB2)).toDouble()) * 0.5;

      return score2.compareTo(score1);
    });

    final commonDisplay = <String>[];
    final cards = <HeuristicCardData>[];

    for (final k in commonKeys) {
      final statA = aMap[k]!;
      final statB = bMap[k]!;
      final name = _capitalizeWords(getName(statA).trim());
      final matchingMedia = _findMatchingCommonMedia(k, mediaList);
      final posters = matchingMedia
          .map((m) => m.cover?.trim() ?? '')
          .where((c) => c.isNotEmpty)
          .take(3)
          .toList();

      commonDisplay.add(name);
      cards.add(HeuristicCardData(
        title: name,
        posterUrls: posters,
        commonMediaItems: matchingMedia,
        rows: [
          StatComparisonRow(
            user1Value: getMeanScore(statA).toStringAsFixed(2),
            label: 'Mean Score',
            user2Value: getMeanScore(statB).toStringAsFixed(2),
          ),
          StatComparisonRow(
            user1Value: '${getCount(statA)}',
            label: 'Count',
            user2Value: '${getCount(statB)}',
          ),
        ],
      ));
    }

    final countScore = pow(commonKeys.length / expectedMax, _expoWeightingFactor).toDouble().clamp(0.0, 1.0);
    double scoreAgreement = 0.0;
    for (final k in commonKeys) {
      final sA = getMeanScore(aMap[k]!);
      final sB = getMeanScore(bMap[k]!);
      final diff = (sA - sB).abs();
      scoreAgreement += (1.0 - (diff / 50.0)).clamp(0.0, 1.0);
    }
    final avgAgreement = commonKeys.isNotEmpty ? scoreAgreement / commonKeys.length : 1.0;
    final score = ((countScore * 0.65) + (avgAgreement * 0.35)).clamp(0.0, 1.0);
    return (score, commonDisplay, cards, true);
  }

  static (double, List<String>, List<HeuristicCardData>, bool) _genreOverlapDetailed({
    required List<GenreStat> genresA,
    required List<GenreStat> genresB,
    required String? meanScoreA,
    required String? meanScoreB,
    List<FavouriteMedia> mediaList = const [],
  }) =>
      _computeTaxonomyOverlap<GenreStat>(
        listA: genresA,
        avgA: _parseD(meanScoreA),
        listB: genresB,
        avgB: _parseD(meanScoreB),
        maxTop: 5,
        expectedMax: 5.0,
        getName: (g) => g.genre,
        getMeanScore: (g) => g.meanScore,
        getCount: (g) => g.count,
        mediaList: mediaList,
      );

  static (double, List<String>, List<HeuristicCardData>, bool) _tagOverlapDetailed({
    required List<TagStat> tagsA,
    required List<TagStat> tagsB,
    required String? meanScoreA,
    required String? meanScoreB,
    List<FavouriteMedia> mediaList = const [],
  }) =>
      _computeTaxonomyOverlap<TagStat>(
        listA: tagsA,
        avgA: _parseD(meanScoreA),
        listB: tagsB,
        avgB: _parseD(meanScoreB),
        maxTop: 10,
        expectedMax: 10.0,
        getName: (t) => t.tag,
        getMeanScore: (t) => t.meanScore,
        getCount: (t) => t.count,
        mediaList: mediaList,
      );

  static (double, List<FavouriteMedia>, List<int>, int, bool) _computeFavouriteMediaOverlap(
    List<FavouriteMedia>? listA,
    List<FavouriteMedia>? listB,
  ) {
    final (score, list, _, active) = _computeFavouriteEntityOverlap<FavouriteMedia>(
      listA: listA,
      listB: listB,
      getId: (m) => m.id,
      getName: (m) => m.title,
      maxLen: 8.0,
    );
    final ids = list.map((m) => int.tryParse(m.id ?? '') ?? 0).where((id) => id > 0).toList();
    return (score, list, ids, ids.length, active);
  }

  static (double, int, bool, List<FavouriteMedia>) _computePerfectMediaOverlap(
    List<int>? ids1,
    List<int>? ids2,
    List<FavouriteMedia>? list1,
    List<FavouriteMedia>? list2,
  ) {
    final p1 = ids1?.where((id) => id > 0).toSet() ?? <int>{};
    final p2 = ids2?.where((id) => id > 0).toSet() ?? <int>{};
    final active = p1.isNotEmpty && p2.isNotEmpty;
    final (score, count) = active ? _jaccardExponential(p1, p2, 8.0) : (0.0, 0);
    final commonMedia = _intersectMedia(list1, list2, p1.intersection(p2));
    return (score, count, active, commonMedia);
  }

  static List<FavouriteMedia> _deduplicateMedia(List<List<FavouriteMedia>?> lists) {
    final unique = <String, FavouriteMedia>{};
    for (final list in lists) {
      if (list == null) continue;
      for (final m in list) {
        final id = m.id?.trim() ?? '';
        if (id.isNotEmpty) {
          unique[id] = m;
        }
      }
    }
    return unique.values.toList();
  }

  static (double, List<FavouriteCharacter>, List<int>, int, bool) _favouriteCharacterOverlapDetailed(
      ProfileFavourites? f1, ProfileFavourites? f2) {
    final (score, list, _, active) = _computeFavouriteEntityOverlap<FavouriteCharacter>(
      listA: f1?.characters,
      listB: f2?.characters,
      getId: (c) => c.id,
      getName: (c) => c.name,
      maxLen: 6.0,
    );
    final ids = list.map((c) => int.tryParse(c.id ?? '') ?? 0).where((id) => id > 0).toList();
    return (score, list, ids, ids.length, active);
  }

  static (double, List<FavouriteStaff>, List<String>, bool) _favouriteStaffOverlapDetailed(
      ProfileFavourites? f1, ProfileFavourites? f2) {
    return _computeFavouriteEntityOverlap<FavouriteStaff>(
      listA: f1?.staff,
      listB: f2?.staff,
      getId: (s) => s.id,
      getName: (s) => s.name,
      maxLen: 6.0,
    );
  }

  static (double, List<T>, List<String>, bool) _computeFavouriteEntityOverlap<T extends Object>({
    required List<T>? listA,
    required List<T>? listB,
    required String? Function(T) getId,
    required String? Function(T) getName,
    double maxLen = 6.0,
  }) {
    if (listA == null || listB == null || listA.isEmpty || listB.isEmpty) {
      return (0.0, <T>[], <String>[], false);
    }
    final aMap = {for (final item in listA) (getId(item)?.trim() ?? ''): item}..remove('');
    final bMap = {for (final item in listB) (getId(item)?.trim() ?? ''): item}..remove('');
    if (aMap.isEmpty || bMap.isEmpty) return (0.0, <T>[], <String>[], false);

    final commonIds = aMap.keys.toSet().intersection(bMap.keys.toSet()).toList();
    final posA = {for (var i = 0; i < listA.length; i++) (getId(listA[i])?.trim() ?? ''): i};
    final posB = {for (var i = 0; i < listB.length; i++) (getId(listB[i])?.trim() ?? ''): i};
    commonIds.sort((id1, id2) {
      final prio1 = (posA[id1] ?? 99) + (posB[id1] ?? 99);
      final prio2 = (posA[id2] ?? 99) + (posB[id2] ?? 99);
      return prio1.compareTo(prio2);
    });

    final commonList = commonIds.map((id) => aMap[id] ?? bMap[id]!).toList();
    final commonNames = commonList.map((item) => getName(item) ?? '').where((s) => s.isNotEmpty).toList();
    final score = min(pow(commonIds.length / maxLen, _expoWeightingFactor).toDouble(), 1.0);
    return (score, commonList, commonNames, true);
  }

  static (double, List<HeuristicCardData>, List<String>, bool) _voiceActorOverlapDetailed(AnimeStats a, AnimeStats b) {
    return _computeEntityStatOverlap<PersonStat>(
      listA: a.voiceActors,
      listB: b.voiceActors,
      avgScoreA: _parseD(a.meanScore),
      avgScoreB: _parseD(b.meanScore),
      maxTop: 6,
      expectedMax: 6.0,
      getId: (v) => v.id,
      getName: (v) => v.name,
      getMeanScore: (v) => v.meanScore,
      getCount: (v) => v.count,
      getImage: (v) => v.image,
    );
  }

  static (double, List<HeuristicCardData>, List<String>, bool) _studioOverlapDetailed(AnimeStats a, AnimeStats b) {
    return _computeEntityStatOverlap<StudioStat>(
      listA: a.studios,
      listB: b.studios,
      avgScoreA: _parseD(a.meanScore),
      avgScoreB: _parseD(b.meanScore),
      maxTop: 3,
      expectedMax: 3.0,
      getId: (s) => s.id,
      getName: (s) => s.name,
      getMeanScore: (s) => s.meanScore,
      getCount: (s) => s.count,
    );
  }

  static (double, List<HeuristicCardData>, List<String>, bool) _computeEntityStatOverlap<T extends Object>({
    required List<T> listA,
    required List<T> listB,
    required double avgScoreA,
    required double avgScoreB,
    required int maxTop,
    required double expectedMax,
    required String? Function(T) getId,
    required String Function(T) getName,
    required double Function(T) getMeanScore,
    required int Function(T) getCount,
    String? Function(T)? getImage,
  }) {
    final aTop = _aboveAverageEntities(listA, avgScoreA, getMeanScore: getMeanScore, getCount: getCount);
    final bTop = _aboveAverageEntities(listB, avgScoreB, getMeanScore: getMeanScore, getCount: getCount);
    if (aTop.isEmpty || bTop.isEmpty) return (0.0, [], [], false);

    final aMap = <String, T>{};
    for (final item in aTop.take(maxTop)) {
      final id = getId(item)?.trim() ?? '';
      if (id.isNotEmpty) aMap[id] = item;
    }
    final bMap = <String, T>{};
    for (final item in bTop.take(maxTop)) {
      final id = getId(item)?.trim() ?? '';
      if (id.isNotEmpty) bMap[id] = item;
    }

    final aSet = aMap.keys.toSet();
    final bSet = bMap.keys.toSet();
    if (aSet.isEmpty || bSet.isEmpty) return (0.0, <HeuristicCardData>[], <String>[], false);

    final commonIds = aSet.intersection(bSet).toList();
    if (commonIds.isEmpty) return (0.0, <HeuristicCardData>[], <String>[], false);

    commonIds.sort((id1, id2) {
      final sA1 = aMap[id1]!;
      final sB1 = bMap[id1]!;
      final sA2 = aMap[id2]!;
      final sB2 = bMap[id2]!;

      final score1 = ((getMeanScore(sA1) + getMeanScore(sB1)) / 2.0) -
          (getMeanScore(sA1) - getMeanScore(sB1)).abs() * 0.3 +
          min(10.0, min(getCount(sA1), getCount(sB1)).toDouble()) * 1.0;

      final score2 = ((getMeanScore(sA2) + getMeanScore(sB2)) / 2.0) -
          (getMeanScore(sA2) - getMeanScore(sB2)).abs() * 0.3 +
          min(10.0, min(getCount(sA2), getCount(sB2)).toDouble()) * 1.0;

      return score2.compareTo(score1);
    });

    final commonNames = <String>[];
    final cards = <HeuristicCardData>[];

    for (final id in commonIds) {
      final statA = aMap[id]!;
      final statB = bMap[id]!;
      final name = getName(statA).trim();
      commonNames.add(name);
      cards.add(HeuristicCardData(
        title: name,
        imageUrl: getImage != null ? (getImage(statA) ?? getImage(statB)) : null,
        mediaId: id,
        rows: [
          StatComparisonRow(
            user1Value: getMeanScore(statA).toStringAsFixed(2),
            label: 'Mean Score',
            user2Value: getMeanScore(statB).toStringAsFixed(2),
          ),
          StatComparisonRow(
            user1Value: '${getCount(statA)}',
            label: 'Count',
            user2Value: '${getCount(statB)}',
          ),
        ],
      ));
    }

    final countScore = pow(commonIds.length / expectedMax, _expoWeightingFactor).toDouble().clamp(0.0, 1.0);
    double scoreAgreement = 0.0;
    for (final id in commonIds) {
      final sA = getMeanScore(aMap[id]!);
      final sB = getMeanScore(bMap[id]!);
      final diff = (sA - sB).abs();
      scoreAgreement += (1.0 - (diff / 50.0)).clamp(0.0, 1.0);
    }
    final avgAgreement = commonIds.isNotEmpty ? scoreAgreement / commonIds.length : 1.0;
    final score = ((countScore * 0.70) + (avgAgreement * 0.30)).clamp(0.0, 1.0);
    return (score, cards, commonNames, true);
  }

  static List<FavouriteMedia> _intersectMedia(
    List<FavouriteMedia>? list1,
    List<FavouriteMedia>? list2,
    Set<int> commonIds,
  ) {
    if (commonIds.isEmpty) return [];
    final map = <int, FavouriteMedia>{};
    if (list1 != null) {
      for (final m in list1) {
        final id = int.tryParse(m.id ?? '') ?? 0;
        if (commonIds.contains(id)) map[id] = m;
      }
    }
    if (list2 != null) {
      for (final m in list2) {
        final id = int.tryParse(m.id ?? '') ?? 0;
        if (commonIds.contains(id) && !map.containsKey(id)) map[id] = m;
      }
    }
    return commonIds.map((id) => map[id] ?? FavouriteMedia(id: '$id', title: 'Media #$id')).toList();
  }

  static Map<int, _DecadeData> _stackYearsIntoDecades(List<YearStat> years) {
    final map = <int, _DecadeData>{};
    for (final y in years) {
      final decade = (y.year ~/ 10) * 10;
      final current = map.putIfAbsent(decade, () => _DecadeData());
      current.minutesWatched += y.amount > 0 ? y.amount.toDouble() : (y.count * 24.0);
      current.totalScore += y.meanScore * y.count;
      current.count += y.count;
    }
    return map;
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

  static List<T> _aboveAverageEntities<T extends Object>(
    List<T> list,
    double avg, {
    required double Function(T) getMeanScore,
    required int Function(T) getCount,
  }) {
    if (list.isEmpty) return [];
    if (avg <= 0) return list.toList()..sort((a, b) => getCount(b).compareTo(getCount(a)));
    final filtered = list.where((x) => getCount(x) >= 3 && getMeanScore(x) > avg).toList();
    if (filtered.isEmpty) {
      final fallback = list.where((x) => getMeanScore(x) > avg).toList();
      if (fallback.isNotEmpty) {
        fallback.sort((a, b) => getMeanScore(b).compareTo(getMeanScore(a)));
        return fallback;
      }
      return list.toList()..sort((a, b) => getCount(b).compareTo(getCount(a)));
    }
    filtered.sort((a, b) => getMeanScore(b).compareTo(getMeanScore(a)));
    return filtered;
  }

  static String _capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static (double, RankInfo) _weightedResult(List<_H> scores) {
    double totalWeight = 0;
    double weightedSum = 0;
    for (final s in scores) {
      if (s.isActive && s.weight > 0) {
        weightedSum += s.score * s.weight;
        totalWeight += s.weight;
      }
    }
    final pct = totalWeight > 0 ? (weightedSum / totalWeight) * 100.0 : 0.0;
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

class _H {
  final double score;
  final double weight;
  final bool isActive;
  const _H(this.score, this.weight, {this.isActive = true});
}

class _DecadeData {
  double minutesWatched = 0.0;
  double totalScore = 0.0;
  int count = 0;
  double get meanScore => count > 0 ? totalScore / count : 0.0;
}
