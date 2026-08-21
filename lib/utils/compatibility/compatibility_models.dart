/// A single section of compatibility (e.g. Anime, Manga & Novels, Shared).
class CompatibilitySection {
  final double percentage;
  final String rank;
  final String rankDescription;
  final List<HeuristicScore> breakdown;
  final bool hasData;

  const CompatibilitySection({
    required this.percentage,
    required this.rank,
    required this.rankDescription,
    required this.breakdown,
    this.hasData = true,
  });

  factory CompatibilitySection.noData() => const CompatibilitySection(
        percentage: 0,
        rank: 'N/A',
        rankDescription: 'No data available',
        breakdown: [],
        hasData: false,
      );
}

/// Format distribution for the manga section (Manga vs LN vs Novel).
class MangaFormatSplit {
  final double mangaPercent;
  final double lightNovelPercent;
  final double novelPercent;

  const MangaFormatSplit({
    this.mangaPercent = 0,
    this.lightNovelPercent = 0,
    this.novelPercent = 0,
  });

  String get displayLabel {
    final parts = <String>[];
    if (mangaPercent > 5) parts.add('Manga ${mangaPercent.toStringAsFixed(0)}%');
    if (lightNovelPercent > 5) {
      parts.add('LN ${lightNovelPercent.toStringAsFixed(0)}%');
    }
    if (novelPercent > 5) parts.add('Novel ${novelPercent.toStringAsFixed(0)}%');
    return parts.isEmpty ? 'No data' : parts.join(' · ');
  }
}

class CompatibilityResult {
  /// Overall compatibility (weighted average of sections that have data).
  final double percentage;
   final String rank;
  final String rankDescription;

  /// Anime-specific compatibility.
  final CompatibilitySection animeSection;

  /// Manga & Novels compatibility.
  final CompatibilitySection mangaSection;

  /// Flat list of ALL heuristic scores (for backwards compat / detailed view).
  final List<HeuristicScore> breakdown;

  // ---- Shared data ----
  final List<int> commonFavouriteAnimeIds;
  final List<int> commonFavouriteMangaIds;
  final List<int> commonFavouriteCharacterIds;
  final List<String> commonStaffIds;
  final List<String> commonGenres;
  final List<String> commonTags;
  final List<String> commonStudios;
  final List<String> commonVoiceActors;
  final List<String> commonMangaGenres;
  final List<String> commonMangaTags;

  /// Format split (Manga vs LN vs Novel) for each user.
  final MangaFormatSplit? user1FormatSplit;
  final MangaFormatSplit? user2FormatSplit;

  const CompatibilityResult({
    required this.percentage,
    required this.rank,
    required this.rankDescription,
    required this.animeSection,
    required this.mangaSection,
    required this.breakdown,
    this.commonFavouriteAnimeIds = const [],
    this.commonFavouriteMangaIds = const [],
    this.commonFavouriteCharacterIds = const [],
    this.commonStaffIds = const [],
    this.commonGenres = const [],
    this.commonTags = const [],
    this.commonStudios = const [],
    this.commonVoiceActors = const [],
    this.commonMangaGenres = const [],
    this.commonMangaTags = const [],
    this.user1FormatSplit,
    this.user2FormatSplit,
  });
}

class HeuristicScore {
  final String key;
  final String label;
  final String description;
  final double score; // 0.0–1.0
  final double weight;
  final double weightedScore;

  const HeuristicScore({
    required this.key,
    required this.label,
    required this.description,
    required this.score,
    required this.weight,
    required this.weightedScore,
  });

  double get percentageDisplay => (score * 100);
}

class RankInfo {
  final String name;
  final double min;
  final double max;
  final String description;
  final String colorHex; // For UI theming

  const RankInfo({
    required this.name,
    required this.min,
    required this.max,
    required this.description,
    required this.colorHex,
  });

  bool contains(double value) => value >= min && value < max;
}

const kRanks = <RankInfo>[
  RankInfo(
    name: 'SSS',
    min: 85,
    max: 100.01,
    description: 'You are basically the same person.',
    colorHex: '#FFD700',
  ),
  RankInfo(
    name: 'SS',
    min: 75,
    max: 85,
    description: 'Practically made for each other.',
    colorHex: '#FF6B6B',
  ),
  RankInfo(
    name: 'S',
    min: 65,
    max: 75,
    description: 'Very similar taste.',
    colorHex: '#A855F7',
  ),
  RankInfo(
    name: 'A',
    min: 55,
    max: 65,
    description: 'Good chemistry and shared taste.',
    colorHex: '#3B82F6',
  ),
  RankInfo(
    name: 'B',
    min: 40,
    max: 55,
    description: 'Above-average similarity.',
    colorHex: '#22C55E',
  ),
  RankInfo(
    name: 'C',
    min: 20,
    max: 40,
    description: 'Average overlap.',
    colorHex: '#EAB308',
  ),
  RankInfo(
    name: 'D',
    min: 10,
    max: 20,
    description: 'Small spark of agreement.',
    colorHex: '#F97316',
  ),
  RankInfo(
    name: 'F',
    min: 0,
    max: 10,
    description: 'Not very compatible at all.',
    colorHex: '#6B7280',
  ),
];

RankInfo getRankForScore(double percentage) {
  for (final rank in kRanks) {
    if (rank.contains(percentage)) return rank;
  }
  return kRanks.last;
}
