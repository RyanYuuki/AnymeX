import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Anilist/social_user.dart';

class MutualSocialData {
  final bool user1FollowsUser2;
  final bool user2FollowsUser1;
  final List<SocialUser> mutualFollowing;
  final List<SocialUser> mutualFollowers;

  const MutualSocialData({
    this.user1FollowsUser2 = false,
    this.user2FollowsUser1 = false,
    this.mutualFollowing = const [],
    this.mutualFollowers = const [],
  });

  bool get isMutualFriends => user1FollowsUser2 && user2FollowsUser1;
  bool get hasAnySocialData =>
      user1FollowsUser2 ||
      user2FollowsUser1 ||
      mutualFollowing.isNotEmpty ||
      mutualFollowers.isNotEmpty;
}

class StatComparisonRow {
  final String user1Value;
  final String label;
  final String user2Value;

  const StatComparisonRow({
    required this.user1Value,
    required this.label,
    required this.user2Value,
  });
}

class HeuristicCardData {
  final String title;
  final List<StatComparisonRow> rows;
  final String? imageUrl;
  final String? mediaId;
  final List<String> posterUrls;
  final List<FavouriteMedia> commonMediaItems;

  const HeuristicCardData({
    required this.title,
    this.rows = const [],
    this.imageUrl,
    this.mediaId,
    this.posterUrls = const [],
    this.commonMediaItems = const [],
  });
}

class HeuristicDetail {
  final String key;
  final String title;
  final String description;
  final double score; // 0.0–1.0
  final double weight;
  final List<HeuristicCardData> cards;
  final List<FavouriteMedia> mediaItems;
  final List<FavouriteCharacter> characterItems;
  final List<FavouriteStaff> staffItems;
  final bool hasData;

  const HeuristicDetail({
    required this.key,
    required this.title,
    required this.description,
    required this.score,
    required this.weight,
    this.cards = const [],
    this.mediaItems = const [],
    this.characterItems = const [],
    this.staffItems = const [],
    this.hasData = true,
  });

  double get percentage => (score * 100.0).clamp(0.0, 100.0);

  HeuristicScore toScore() => HeuristicScore(
        key: key,
        label: title,
        description: description,
        score: score,
        weight: weight,
        weightedScore: score * weight,
      );
}

class CompatibilitySection {
  final double percentage;
  final String rank;
  final String rankDescription;
  final List<HeuristicScore> breakdown;
  final List<HeuristicDetail> details;
  final bool hasData;

  const CompatibilitySection({
    required this.percentage,
    required this.rank,
    required this.rankDescription,
    required this.breakdown,
    this.details = const [],
    this.hasData = true,
  });

  factory CompatibilitySection.noData() => const CompatibilitySection(
        percentage: 0,
        rank: 'N/A',
        rankDescription: 'No data available',
        breakdown: [],
        details: [],
        hasData: false,
      );
}

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
  final double percentage;
  final String rank;
  final String rankDescription;
  final CompatibilitySection animeSection;
  final CompatibilitySection mangaSection;
  final List<HeuristicScore> breakdown;
  final MangaFormatSplit? user1FormatSplit;
  final MangaFormatSplit? user2FormatSplit;
  MutualSocialData? socialData;

  CompatibilityResult({
    required this.percentage,
    required this.rank,
    required this.rankDescription,
    required this.animeSection,
    required this.mangaSection,
    required this.breakdown,
    this.user1FormatSplit,
    this.user2FormatSplit,
    this.socialData,
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
  final String colorHex;
  final String? template;

  const RankInfo({
    required this.name,
    required this.min,
    required this.max,
    required this.description,
    required this.colorHex,
    this.template,
  });

  bool contains(double value) => value >= min && value < max;

  String getFormattedDescription(double percentage) {
    final t = template ?? description;
    return t.replaceAll('{{RANGE}}', '${percentage.toStringAsFixed(0)}%');
  }
}

const kRanks = <RankInfo>[
  RankInfo(
    name: 'SSS',
    min: 85,
    max: 100.01,
    description: 'You are basically the same person.',
    colorHex: '#FBBF24',
    template: 'Absolute soulmates in taste with {{RANGE}} overlap.',
  ),
  RankInfo(
    name: 'SS',
    min: 75,
    max: 85,
    description: 'Practically made for each other.',
    colorHex: '#F59E0B',
    template: 'Practically made for each other with {{RANGE}} overlap.',
  ),
  RankInfo(
    name: 'S',
    min: 65,
    max: 75,
    description: 'You both have very similar taste.',
    colorHex: '#EAB308',
    template: 'You both have very similar taste—about {{RANGE}} agreement.',
  ),
  RankInfo(
    name: 'A',
    min: 55,
    max: 65,
    description: 'Good chemistry and shared taste.',
    colorHex: '#8B5CF6',
    template: 'Good chemistry and shared taste with around {{RANGE}} overlap.',
  ),
  RankInfo(
    name: 'B',
    min: 40,
    max: 55,
    description: 'Above-average similarity.',
    colorHex: '#10B981',
    template: 'Above-average similarity at roughly {{RANGE}} overlap.',
  ),
  RankInfo(
    name: 'C',
    min: 20,
    max: 40,
    description: 'Average overlap.',
    colorHex: '#22C55E',
    template: 'Average overlap with around {{RANGE}} shared taste.',
  ),
  RankInfo(
    name: 'D',
    min: 10,
    max: 20,
    description: 'There’s a small spark of agreement.',
    colorHex: '#F97316',
    template: 'There’s a small spark of agreement: about {{RANGE}} overlap.',
  ),
  RankInfo(
    name: 'F',
    min: 0,
    max: 10,
    description: 'Not very compatible at all.',
    colorHex: '#EF4444',
    template: 'Not very compatible at all. Only {{RANGE}} of your taste overlaps.',
  ),
];

RankInfo getRankForScore(double percentage) {
  for (final rank in kRanks) {
    if (rank.contains(percentage)) return rank;
  }
  return kRanks.last;
}
