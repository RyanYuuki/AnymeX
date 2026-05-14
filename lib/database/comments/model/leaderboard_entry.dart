class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final String tier;
  final String tierEmoji;
  final int currentStreak;
  final String? role;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.tier,
    required this.tierEmoji,
    required this.currentStreak,
    this.avatarUrl,
    this.role,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map m, {int? rank}) {
    return LeaderboardEntry(
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? 'Unknown',
      avatarUrl: m['avatar_url']?.toString(),
      totalPoints: _parseInt(m['total_points']),
      tier: m['tier']?.toString() ?? 'Newcomer',
      tierEmoji: m['tier_emoji']?.toString() ?? '🌱',
      currentStreak: _parseInt(m['current_streak']),
      role: m['role']?.toString(),
      rank: rank ?? _parseInt(m['rank']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
