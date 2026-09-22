import 'package:anymex/database/comments/model/discord_badge.dart';

class UserPoints {
  final String userId;
  final int totalPoints;
  final int realPoints;
  final int roleBonus;
  final bool isInfinite;
  final String tier;
  final String tierEmoji;
  final int currentStreak;
  final int longestStreak;
  final String? role;
  final int? rank;
  final PointsBreakdown breakdown;
  final PointsStats stats;
  final List<DiscordBadge>? badges;

  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.realPoints,
    required this.roleBonus,
    required this.isInfinite,
    required this.tier,
    required this.tierEmoji,
    required this.currentStreak,
    required this.longestStreak,
    this.role,
    this.rank,
    required this.breakdown,
    required this.stats,
    this.badges,
  });

  String get displayPoints => isInfinite ? '∞' : '$totalPoints';

  factory UserPoints.fromMap(Map m) {
    final breakdownData = m['breakdown'] as Map? ?? {};
    final statsData = m['stats'] as Map? ?? {};
    final role = m['role']?.toString();
    final isInfinite =
        m['is_infinite'] == true || role == 'owner' || role == 'app_owner';
    final tier = isInfinite ? 'Elite' : (m['tier']?.toString() ?? 'Newcomer');

    return UserPoints(
      userId: m['user_id']?.toString() ?? '',
      totalPoints: _parseInt(m['total_points'] ?? m['points']),
      realPoints: _parseInt(m['real_points'] ?? m['points']),
      roleBonus: _parseInt(m['role_bonus']),
      isInfinite: isInfinite,
      tier: tier,
      tierEmoji: m['tier_emoji']?.toString() ?? '',
      currentStreak: _parseInt(m['current_streak'] ?? m['streak']),
      longestStreak: _parseInt(m['longest_streak']),
      role: role,
      rank: m['rank'] == null ? null : _parseInt(m['rank']),
      breakdown: PointsBreakdown.fromMap(breakdownData),
      stats: PointsStats.fromMap(statsData),
      badges: m['badges'] != null
          ? (m['badges'] as List)
              .map((b) => DiscordBadge.fromMap(b as Map))
              .toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
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
      upvotesReceivedPoints: UserPoints._parseInt(
          m['upvotes_from_others'] ?? m['from_upvotes_received']),
      votesCastPoints:
          UserPoints._parseInt(m['votes_cast'] ?? m['from_votes_cast']),
      pinnedPoints: UserPoints._parseInt(m['pinned'] ?? m['from_pinned']),
      downvotesReceivedPoints: UserPoints._parseInt(
          m['downvotes_from_others'] ?? m['from_downvotes_received']),
      warningsPoints:
          UserPoints._parseInt(m['warnings'] ?? m['penalty_warnings']),
      deletedPoints:
          UserPoints._parseInt(m['mod_deletions'] ?? m['penalty_mod_deletes']),
      bannedPoints: UserPoints._parseInt(m['banned'] ?? m['penalty_ban']),
      streakBonus:
          UserPoints._parseInt(m['streak_bonus'] ?? m['from_streak_bonus']),
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
      totalComments:
          UserPoints._parseInt(m['total_comments'] ?? m['comment_count']),
      totalReplies: UserPoints._parseInt(m['total_replies'] ?? m['replies']),
      totalUpvotesReceived: UserPoints._parseInt(
          m['total_upvotes_received'] ?? m['upvotes_from_others']),
      totalDownvotesReceived: UserPoints._parseInt(
          m['total_downvotes_received'] ?? m['downvotes_from_others']),
      totalVotesCast:
          UserPoints._parseInt(m['total_votes_cast'] ?? m['vote_count']),
    );
  }
}
