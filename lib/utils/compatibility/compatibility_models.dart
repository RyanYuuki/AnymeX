class CompatibilityResult {
  final double percentage;
  final String rank;
  final String rankDescription;
  final List<HeuristicScore> breakdown;
  final List<int> commonFavouriteAnimeIds;
  final List<int> commonFavouriteCharacterIds;
  final List<String> commonGenres;
  final List<String> commonTags;
  final List<String> commonStudios;
  final List<String> commonVoiceActors;

  const CompatibilityResult({
    required this.percentage,
    required this.rank,
    required this.rankDescription,
    required this.breakdown,
    this.commonFavouriteAnimeIds = const [],
    this.commonFavouriteCharacterIds = const [],
    this.commonGenres = const [],
    this.commonTags = const [],
    this.commonStudios = const [],
    this.commonVoiceActors = const [],
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
