import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/leaderboard_entry.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaderboardSheet extends StatefulWidget {
  const LeaderboardSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LeaderboardSheet(),
    );
  }

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  final CommentumService _commentumService = Get.find<CommentumService>();
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _currentUserEntry;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final result = await _commentumService.getLeaderboard(limit: 100);
    final list = (result['entries'] as List<LeaderboardEntry>?) ?? [];

    final myId = _commentumService.currentUserId;
    LeaderboardEntry? myEntry;
    if (myId != null) {
      for (final e in list) {
        if (e.userId == myId) {
          myEntry = e;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _entries = list;
        _currentUserEntry = myEntry;
        _isLoading = false;
      });
    }
  }

  void _onUserTapped(LeaderboardEntry entry) {
    Navigator.pop(context);
    final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
    if (entry.userId == currentUserId) {
      navigate(() => const ProfilePage());
    } else {
      final parsedId = int.tryParse(entry.userId);
      if (parsedId != null && parsedId > 0) {
        navigate(() => UserProfilePage(userId: parsedId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emoji_events_rounded, color: colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            'Community Leaderboard',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          AnymeXText(
                            'Top commenters & points ranking',
                            size: 11.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _isLoading ? null : _fetchLeaderboard,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: ExpressiveLoadingIndicator(),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.leaderboard_outlined,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: 10),
                                AnymeXText(
                                  'No rankings available yet',
                                  color: colorScheme.onSurfaceVariant,
                                  size: 14,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return _buildLeaderboardTile(context, entry, index);
                            },
                          ),
              ),

              // Bottom Current User Rank Bar (if available)
              if (_currentUserEntry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Builder(
                            builder: (context) {
                              final myRank = '#${_currentUserEntry!.rank}';
                              return AnymeXText(
                                myRank,
                                variant: TextVariant.bold,
                                size: myRank.length > 5
                                    ? 9.0
                                    : myRank.length > 4
                                        ? 10.0
                                        : 12,
                                color: colorScheme.primary,
                                maxLines: 1,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnymeXDecoratedAvatar(
                          avatarUrl: _currentUserEntry!.avatarUrl,
                          decorationUrl: _currentUserEntry!.avatarDecoration,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: AnymeXText(
                                      'You (${_currentUserEntry!.username})',
                                      variant: TextVariant.bold,
                                      size: 13,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_currentUserEntry!.badges != null && _currentUserEntry!.badges!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    DiscordBadgesRow(badges: _currentUserEntry!.badges, size: 14.0),
                                  ],
                                ],
                              ),
                              AnymeXText(
                                '${_currentUserEntry!.tierEmoji} ${_currentUserEntry!.tierLabel} • ${_currentUserEntry!.displayPoints} pts',
                                size: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        if (_currentUserEntry!.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                AnymeXText(
                                  '${_currentUserEntry!.currentStreak}d',
                                  variant: TextVariant.bold,
                                  size: 11,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, LeaderboardEntry entry, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTop3 = index < 3;

    Color rankColor;
    Color? rankBgColor;
    String rankBadge;

    if (index == 0) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankBgColor = const Color(0xFFFFD700).withValues(alpha: 0.15);
      rankBadge = '🥇';
    } else if (index == 1) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankBgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.15);
      rankBadge = '🥈';
    } else if (index == 2) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankBgColor = const Color(0xFFCD7F32).withValues(alpha: 0.15);
      rankBadge = '🥉';
    } else {
      rankColor = colorScheme.onSurfaceVariant;
      rankBgColor = null;
      rankBadge = '#${entry.rank}';
    }

    final isMyEntry = entry.userId == _commentumService.currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onUserTapped(entry),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMyEntry
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMyEntry
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : isTop3
                      ? rankColor.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.12),
              width: isTop3 || isMyEntry ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              // Rank indicator
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rankBgColor ?? colorScheme.surface.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isTop3
                    ? Text(rankBadge, style: const TextStyle(fontSize: 16))
                    : AnymeXText(
                        rankBadge,
                        variant: TextVariant.bold,
                        // 4-digit ranks (#4048) overflow a 36px circle at 12
                        size: rankBadge.length > 5
                            ? 9.0
                            : rankBadge.length > 4
                                ? 10.0
                                : 12,
                        color: rankColor,
                        maxLines: 1,
                      ),
              ),
              const SizedBox(width: 12),

              // Avatar
              AnymeXDecoratedAvatar(
                avatarUrl: entry.avatarUrl,
                decorationUrl: entry.avatarDecoration,
                size: 38,
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AnymeXText(
                            entry.username,
                            variant: TextVariant.bold,
                            size: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.badges != null && entry.badges!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          DiscordBadgesRow(badges: entry.badges, size: 14.0),
                        ] else if (entry.role != null && entry.role != 'user') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AnymeXText(
                              entry.role!,
                              size: 9.5,
                              variant: TextVariant.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (entry.tierEmoji.isNotEmpty) ...[
                          Text(entry.tierEmoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                        ],
                        AnymeXText(
                          entry.tierLabel,
                          size: 11,
                          variant: TextVariant.semiBold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        if (entry.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          const Text('🔥', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          AnymeXText(
                            '${entry.currentStreak}d',
                            size: 10.5,
                            color: Colors.orange,
                            variant: TextVariant.semiBold,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Points badge & bonus tag button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isTop3
                          ? rankColor.withValues(alpha: 0.12)
                          : colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: isTop3
                          ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 0.8)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: isTop3 ? rankColor : colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        AnymeXText(
                          '${entry.realPoints}',
                          variant: TextVariant.bold,
                          size: 12.5,
                          color: isTop3 ? rankColor : colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  if (entry.bonusTag != null) ...[
                    const SizedBox(width: 5),
                    _buildBonusTagButton(context, entry),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusTagButton(BuildContext context, LeaderboardEntry entry) {
    final tag = entry.bonusTag!;
    Color tagColor = const Color(0xFF5865F2);
    try {
      final hex = tag.color.replaceAll('#', '');
      tagColor = Color(int.parse('0xFF$hex'));
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        if (entry.isInfinite) {
          snackBar('${entry.username}: ${tag.label} (∞ points). Ranking is based on real activity (${entry.realPoints} pts).');
        } else {
          snackBar('${entry.username}: ${entry.realPoints} earned pts + ${tag.text} role bonus (${tag.label}). Ranking is based on real activity.');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: tagColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tagColor.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.isInfinite) ...[
              const Icon(Icons.workspace_premium_rounded, size: 11, color: Color(0xFFFFD700)),
              const SizedBox(width: 2),
            ],
            AnymeXText(
              tag.text,
              variant: TextVariant.bold,
              size: 11,
              color: tagColor,
            ),
          ],
        ),
      ),
    );
  }
}
