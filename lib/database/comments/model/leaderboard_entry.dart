import 'package:anymex/database/comments/model/discord_badge.dart';

class LeaderboardBonusTag {
  final String text;
  final String color;
  final String label;

  LeaderboardBonusTag({
    required this.text,
    required this.color,
    required this.label,
  });

  factory LeaderboardBonusTag.fromMap(Map m) {
    return LeaderboardBonusTag(
      text: m['text']?.toString() ?? '',
      color: m['color']?.toString() ?? '#5865F2',
      label: m['label']?.toString() ?? '',
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarDecoration;
  final String? nameplateTheme;
  final int totalPoints;
  final int realPoints;
  final int roleBonus;
  final bool isInfinite;
  final LeaderboardBonusTag? bonusTag;
  final String tier;
  final String tierEmoji;
  final String tierLabel;
  final int currentStreak;
  final String? role;
  final String? clientType;
  final int rank;
  final List<DiscordBadge>? badges;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.realPoints,
    required this.roleBonus,
    required this.isInfinite,
    this.bonusTag,
    required this.tier,
    required this.tierEmoji,
    required this.tierLabel,
    required this.currentStreak,
    this.avatarUrl,
    this.avatarDecoration,
    this.nameplateTheme,
    this.role,
    this.clientType,
    required this.rank,
    this.badges,
  });

  String get displayPoints => isInfinite ? '∞' : '$realPoints';

  factory LeaderboardEntry.fromMap(Map m, {int? rank}) {
    final role = m['role']?.toString();
    final isInfinite =
        m['is_infinite'] == true || role == 'owner' || role == 'app_owner';
    final tier = isInfinite ? 'Elite' : (m['tier']?.toString() ?? 'newcomer');
    final realPoints = _parseInt(m['real_points'] ?? m['points']);
    final roleBonus = _parseInt(m['role_bonus']);

    LeaderboardBonusTag? bonusTag;
    if (m['bonus_tag'] != null && m['bonus_tag'] is Map) {
      bonusTag = LeaderboardBonusTag.fromMap(m['bonus_tag'] as Map);
    } else if (isInfinite) {
      bonusTag = LeaderboardBonusTag(
        text: '∞',
        color: '#FFD700',
        label: role == 'app_owner' ? 'App Creator' : 'Commentum Owner',
      );
    } else if (roleBonus > 0) {
      String color = '#5865F2';
      String label = 'Staff Bonus';
      if (role == 'super_admin') {
        color = '#ED4245';
        label = 'SuperAdmin';
      } else if (role == 'admin') {
        color = '#E67E22';
        label = 'Admin';
      } else if (role == 'moderator') {
        color = '#5865F2';
        label = 'Mod';
      }
      bonusTag =
          LeaderboardBonusTag(text: '+$roleBonus', color: color, label: label);
    }

    return LeaderboardEntry(
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? 'Unknown',
      avatarUrl: m['avatar_url']?.toString() ??
          m['avatar']?.toString() ??
          (m['user'] is Map ? m['user']['avatar']?.toString() : null),
      avatarDecoration: _cleanDeco(m['avatar_decoration']) ??
          _cleanDeco(m['avatarDecoration']) ??
          _cleanDeco(m['decoration']) ??
          _cleanDeco(m['avatar_frame']) ??
          (m['user'] is Map
              ? (_cleanDeco(m['user']['avatar_decoration']) ??
                  _cleanDeco(m['user']['avatarDecoration']))
              : null),
      nameplateTheme: _cleanDeco(m['nameplate_theme']) ??
          _cleanDeco(m['nameplateTheme']) ??
          (m['user'] is Map
              ? (_cleanDeco(m['user']['nameplate_theme']) ??
                  _cleanDeco(m['user']['nameplateTheme']))
              : null),
      totalPoints: _parseInt(m['total_points'] ?? m['points']),
      realPoints: realPoints,
      roleBonus: roleBonus,
      isInfinite: isInfinite,
      bonusTag: bonusTag,
      tier: tier,
      tierEmoji: m['tier_emoji']?.toString() ?? '',
      tierLabel: m['tier_label']?.toString() ??
          (tier.isNotEmpty
              ? '${tier[0].toUpperCase()}${tier.substring(1)}'
              : 'Newcomer'),
      currentStreak: _parseInt(m['current_streak'] ?? m['streak']),
      role: role,
      clientType: m['client_type']?.toString(),
      rank: rank ?? _parseInt(m['rank']),
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

  static String? _cleanDeco(dynamic value) {
    if (value == null) return null;
    final t = value.toString().trim();
    if (t.isEmpty || t == 'null') return null;
    return t;
  }
}
