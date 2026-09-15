class UserPoints {
  final String userId;
  final int totalPoints;
  final String tier;
  final String tierEmoji;
  final int currentStreak;
  final int longestStreak;
  final String? role;
  final PointsBreakdown breakdown;
  final PointsStats stats;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.tier,
    required this.tierEmoji,
    required this.currentStreak,
    required this.longestStreak,
    this.role,
    required this.breakdown,
    required this.stats,
  });

  factory UserPoints.fromMap(Map m) {
    final breakdownData = m['breakdown'] as Map? ?? {};
    final statsData = m['stats'] as Map? ?? {};
    final tier = m['tier']?.toString() ?? 'Newcomer';

    return UserPoints(
      userId: m['user_id']?.toString() ?? '',
      totalPoints: _parseInt(m['total_points'] ?? m['points']),
      tier: tier,
      tierEmoji: m['tier_emoji']?.toString() ?? getTierEmoji(tier),
      currentStreak: _parseInt(m['current_streak'] ?? m['streak']),
      longestStreak: _parseInt(m['longest_streak']),
      role: m['role']?.toString(),
      breakdown: PointsBreakdown.fromMap(breakdownData),
      stats: PointsStats.fromMap(statsData),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String getTierForPoints(int points) {
    if (points >= 5000) return 'Elite';
    if (points >= 1500) return 'Veteran';
    if (points >= 500) return 'Active';
    if (points >= 100) return 'Regular';
    return 'Newcomer';
  }

  static String getTierEmojiForPoints(int points) {
    if (points >= 5000) return '💎';
    if (points >= 1500) return '⭐';
    if (points >= 500) return '🌸';
    if (points >= 100) return '🍃';
    return '🌱';
  }

  static String getTierEmoji(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return '💎';
      case 'veteran':
        return '⭐';
      case 'active':
        return '🌸';
      case 'regular':
        return '🍃';
      default:
        return '🌱';
    }
  }
}

class PointsBreakdown {
  final int commentsPoints;
  final int repliesPoints;
  final int upvotesReceivedPoints;
  final int votesCastPoints;
  final int pinnedPoints;
  final int downvotesReceivedPoints;
  final int warningsPoints;
  final int deletedPoints;
  final int bannedPoints;
  final int streakBonus;
  final int roleBonus;

  PointsBreakdown({
    required this.commentsPoints,
    required this.repliesPoints,
    required this.upvotesReceivedPoints,
    required this.votesCastPoints,
    required this.pinnedPoints,
    required this.downvotesReceivedPoints,
    required this.warningsPoints,
    required this.deletedPoints,
    required this.bannedPoints,
    required this.streakBonus,
    required this.roleBonus,
  });

  factory PointsBreakdown.fromMap(Map m) {
    return PointsBreakdown(
      commentsPoints: UserPoints._parseInt(m['comments'] ?? m['from_comments']),
      repliesPoints: UserPoints._parseInt(m['replies'] ?? m['from_replies']),
      upvotesReceivedPoints: UserPoints._parseInt(m['upvotes_from_others'] ?? m['from_upvotes_received']),
      votesCastPoints: UserPoints._parseInt(m['votes_cast'] ?? m['from_votes_cast']),
      pinnedPoints: UserPoints._parseInt(m['pinned'] ?? m['from_pinned']),
      downvotesReceivedPoints: UserPoints._parseInt(m['downvotes_from_others'] ?? m['from_downvotes_received']),
      warningsPoints: UserPoints._parseInt(m['warnings'] ?? m['penalty_warnings']),
      deletedPoints: UserPoints._parseInt(m['mod_deletions'] ?? m['penalty_mod_deletes']),
      bannedPoints: UserPoints._parseInt(m['banned'] ?? m['penalty_ban']),
      streakBonus: UserPoints._parseInt(m['streak_bonus'] ?? m['from_streak_bonus']),
      roleBonus: UserPoints._parseInt(m['role_bonus'] ?? m['from_role_bonus']),
    );
  }

  int get totalPositive =>
      commentsPoints +
      repliesPoints +
      upvotesReceivedPoints +
      votesCastPoints +
      pinnedPoints +
      streakBonus +
      roleBonus;

  int get totalNegative =>
      downvotesReceivedPoints.abs() +
      warningsPoints.abs() +
      deletedPoints.abs() +
      bannedPoints.abs();
}

class PointsStats {
  final int totalComments;
  final int totalReplies;
  final int totalUpvotesReceived;
  final int totalDownvotesReceived;
  final int totalVotesCast;

  PointsStats({
    required this.totalComments,
    required this.totalReplies,
    required this.totalUpvotesReceived,
    required this.totalDownvotesReceived,
    required this.totalVotesCast,
  });

  factory PointsStats.fromMap(Map m) {
    return PointsStats(
      totalComments: UserPoints._parseInt(m['total_comments'] ?? m['comment_count']),
      totalReplies: UserPoints._parseInt(m['total_replies'] ?? m['replies']),
      totalUpvotesReceived: UserPoints._parseInt(m['total_upvotes_received'] ?? m['upvotes_from_others']),
      totalDownvotesReceived:
          UserPoints._parseInt(m['total_downvotes_received'] ?? m['downvotes_from_others']),
      totalVotesCast: UserPoints._parseInt(m['total_votes_cast'] ?? m['vote_count']),
    );
  }
}
