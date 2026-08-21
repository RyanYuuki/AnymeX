class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final String tier;
  final String tierEmoji;
  final String tierLabel;
  final int currentStreak;
  final String? role;
  final String? clientType;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.tier,
    required this.tierEmoji,
    required this.tierLabel,
    required this.currentStreak,
    this.avatarUrl,
    this.role,
    this.clientType,
    required this.rank,
  });

  static String _getTierEmoji(String tier) {
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

  static String _getTierLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return 'Elite';
      case 'veteran':
        return 'Veteran';
      case 'active':
        return 'Active';
      case 'regular':
        return 'Regular';
      default:
        return 'Newcomer';
    }
  }

  factory LeaderboardEntry.fromMap(Map m, {int? rank}) {
    final tier = m['tier']?.toString() ?? 'newcomer';
    return LeaderboardEntry(
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? 'Unknown',
      avatarUrl: m['avatar_url']?.toString() ?? m['avatar']?.toString(),
      totalPoints: _parseInt(m['total_points'] ?? m['points']),
      tier: tier,
      tierEmoji: m['tier_emoji']?.toString() ?? _getTierEmoji(tier),
      tierLabel: _getTierLabel(tier),
      currentStreak: _parseInt(m['current_streak'] ?? m['streak']),
      role: m['role']?.toString(),
      clientType: m['client_type']?.toString(),
      rank: rank ?? _parseInt(m['rank']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
