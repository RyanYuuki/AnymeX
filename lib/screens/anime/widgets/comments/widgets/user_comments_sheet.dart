import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/comments/model/user_points.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Server-data profile card shown when tapping a username/avatar in comments.
///
/// Layout: big centered avatar w/ decoration → name → badges → tier/points
/// chips → public stats grid → role-gated private section (self + mods
/// only, never zeros for outsiders) → profile button. No comment list.
class UserCommentsSheet {
  static void show(
    BuildContext context, {
    required Comment comment,
    required CommentSectionController controller,
  }) {
    AnymeXSheet.custom(
      Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final currentUserId =
              Get.find<ServiceHandler>().profileData.value.id?.toString();
          final isSelf = comment.userId == currentUserId;
          final canViewPrivate = isSelf || controller.canModerate();

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  controller.fetchUserPoints(comment.userId),
                  Get.isRegistered<CommentumService>()
                      ? Get.find<CommentumService>()
                          .fetchUserProfile(comment.userId)
                      : Future.value(null),
                ]),
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final points = (!isLoading && snapshot.hasData)
                      ? snapshot.data![0] as UserPoints?
                      : null;
                  final profile = (!isLoading && snapshot.hasData)
                      ? snapshot.data![1] as Map<String, dynamic>?
                      : null;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 1. Banner + centered avatar with decoration + effect overlay
                      if (!isLoading && _bannerUrl(profile) != null)
                        SizedBox(
                          height: 148,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _bannerUrl(profile)!,
                                      height: 108,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                    if ((Get.isRegistered<CommentumService>() &&
                                            Get.find<CommentumService>()
                                                .renderProfileEffects
                                                .value) &&
                                        _effectUrl(profile) != null)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Opacity(
                                            opacity: 0.6,
                                            child: CachedNetworkImage(
                                              imageUrl: _effectUrl(profile)!,
                                              height: 108,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: AnymeXDecoratedAvatar(
                                    avatarUrl: comment.avatarUrl,
                                    decorationUrl: comment.avatarDecoration,
                                    size: 76,
                                    decorationScale: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: AnymeXDecoratedAvatar(
                            avatarUrl: comment.avatarUrl,
                            decorationUrl: comment.avatarDecoration,
                            size: 76,
                            decorationScale: 1.25,
                          ),
                        ),
                      const SizedBox(height: 12),

                      // 2. Name + badges (centered, with optional nameplate)
                      Builder(builder: (context) {
                        final rawNameplate = comment.nameplateTheme ??
                            _nameplateUrl(profile);
                        final commentum = Get.isRegistered<CommentumService>()
                            ? Get.find<CommentumService>()
                            : null;
                        final hasNameplate = (commentum
                                    ?.renderNameplates.value ??
                                true) &&
                            rawNameplate != null &&
                            rawNameplate.trim().isNotEmpty;

                        final nameRow = Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: AnymeXText(
                                comment.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: hasNameplate
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (comment.badges != null &&
                                comment.badges!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              DiscordBadgesRow(
                                  badges: comment.badges, size: 16.0),
                            ],
                            if (comment.linkedAccounts?.isNotEmpty == true) ...[
                              const SizedBox(width: 6),
                              LinkedAccountsBadges(
                                linkedAccounts: comment.linkedAccounts,
                                fontSize: 8.5,
                              ),
                            ],
                          ],
                        );

                        if (hasNameplate) {
                          final resolvedUrl =
                              _resolveNameplateUrl(rawNameplate!.trim());
                          return Center(
                            child: AnymeXContainer(
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(resolvedUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                color: Colors.black.withOpacity(0.38),
                                child: nameRow,
                              ),
                            ),
                          );
                        }

                        return Center(child: nameRow);
                      }),
                      const SizedBox(height: 10),

                      // 3. Tier / points / streak chips
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: ExpressiveLoadingIndicator(),
                          ),
                        )
                      else if (points != null)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(
                              context,
                              '${points.displayPoints} pts',
                              colorScheme.primary,
                            ),
                            if (points.rank != null && points.rank! > 0)
                              _chip(
                                context,
                                '#${points.rank}',
                                colorScheme.tertiary,
                                icon: Icons.leaderboard_outlined,
                              ),
                            if (points.role != null && points.role != 'user')
                              _chip(
                                context,
                                points.role!.replaceAll('_', ' ').toUpperCase(),
                                _roleColor(points.role!),
                              ),
                            if (points.currentStreak > 0)
                              _chip(
                                context,
                                '${points.currentStreak}d streak',
                                Colors.orange,
                                icon: Icons.local_fire_department_outlined,
                              ),
                          ],
                        )
                      else
                        Center(
                          child: AnymeXText(
                            'Stats unavailable',
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 4. Public stats grid (stats-tab highlight-card style)
                      if (!isLoading && points != null) ...[
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.94,
                          children: [
                            _statTile(
                              context,
                              Icons.chat_bubble_outline_rounded,
                              '${points.stats.totalComments}',
                              'Comments',
                              colorScheme.primary,
                            ),
                            _statTile(
                              context,
                              Icons.reply_rounded,
                              '${points.stats.totalReplies}',
                              'Replies',
                              colorScheme.primary,
                            ),
                            _statTile(
                              context,
                              Icons.thumb_up_outlined,
                              '${points.stats.totalUpvotesReceived}',
                              'Upvotes',
                              Colors.green,
                            ),
                            _statTile(
                              context,
                              Icons.how_to_vote_outlined,
                              '${points.stats.totalVotesCast}',
                              'Votes cast',
                              Colors.amber.shade700,
                            ),
                            _statTile(
                              context,
                              Icons.local_fire_department_outlined,
                              '${points.longestStreak}d',
                              'Best streak',
                              Colors.orange,
                            ),
                            _memberSinceTile(context, profile),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 4b. Points breakdown — every positive source (server)
                      if (!isLoading &&
                          points != null &&
                          _breakdownChips(context, points).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            AnymeXText(
                              'Points breakdown',
                              size: 12,
                              variant: TextVariant.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _breakdownChips(context, points),
                        ),
                      ],

                      // 5. Private section — self + mods only, never zeros
                      if (!isLoading &&
                          canViewPrivate &&
                          _hasPrivateInfo(points, profile)) ...[
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            AnymeXText(
                              isSelf
                                  ? 'Your moderation record'
                                  : 'Moderation record',
                              size: 12,
                              variant: TextVariant.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._privateRows(context, points, profile),
                      ],

                      const SizedBox(height: 18),

                      // 6. Profile button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final parsedId = int.tryParse(comment.userId);
                            if (isSelf) {
                              navigate(() => const ProfilePage());
                            } else if (parsedId != null && parsedId > 0) {
                              navigate(() => UserProfilePage(userId: parsedId));
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: AnymeXText(
                            'View Full Profile',
                            variant: TextVariant.bold,
                            size: 13,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
      context,
    );
  }

  static bool _hasPrivateInfo(
      UserPoints? points, Map<String, dynamic>? profile) {
    if (points == null) return false;
    if ((points.breakdown.warningsPoints.abs()) > 0) return true;
    if ((points.breakdown.deletedPoints.abs()) > 0) return true;
    if ((points.breakdown.bannedPoints.abs()) > 0) return true;
    if (points.stats.totalDownvotesReceived > 0) return true;
    if (profile == null) return false;
    if (profile['banned'] == true ||
        profile['muted'] == true ||
        profile['shadow_banned'] == true) {
      return true;
    }
    final notes = profile['notes']?.toString() ?? '';
    if (notes.isNotEmpty && notes != 'null') return true;
    return false;
  }

  static List<Widget> _privateRows(
      BuildContext context, UserPoints? points, Map<String, dynamic>? profile) {
    final rows = <Widget>[];
    if (points != null) {
      if (points.stats.totalDownvotesReceived > 0) {
        rows.add(_infoRow(
          context,
          Icons.thumb_down_outlined,
          'Downvotes received',
          '${points.stats.totalDownvotesReceived}',
          Colors.grey,
        ));
      }
      if (points.breakdown.warningsPoints.abs() > 0) {
        rows.add(_infoRow(
          context,
          Icons.warning_amber_rounded,
          'Warnings',
          '${points.breakdown.warningsPoints.abs()}',
          Colors.orange,
        ));
      }
      if (points.breakdown.deletedPoints.abs() > 0) {
        rows.add(_infoRow(
          context,
          Icons.delete_outline_rounded,
          'Comments removed by mods',
          '${points.breakdown.deletedPoints.abs()}',
          Colors.red,
        ));
      }
      if (points.breakdown.bannedPoints.abs() > 0) {
        rows.add(_infoRow(
          context,
          Icons.block_rounded,
          'Ban penalties',
          '${points.breakdown.bannedPoints.abs()}',
          Colors.red,
        ));
      }
    }
    if (profile != null) {
      if (profile['banned'] == true) {
        rows.add(_infoRow(
          context,
          Icons.gavel_rounded,
          'Banned',
          _until(profile['banned_until']),
          Colors.red,
        ));
      }
      if (profile['muted'] == true) {
        rows.add(_infoRow(
          context,
          Icons.volume_off_rounded,
          'Muted',
          _until(profile['muted_until']),
          Colors.orange,
        ));
      }
      if (profile['shadow_banned'] == true) {
        rows.add(_infoRow(
          context,
          Icons.visibility_off_rounded,
          'Shadow banned',
          '',
          Colors.purple,
        ));
      }
      final notes = profile['notes']?.toString() ?? '';
      if (notes.isNotEmpty && notes != 'null') {
        rows.add(_infoRow(
          context,
          Icons.sticky_note_2_outlined,
          'Mod notes',
          notes,
          Colors.teal,
        ));
      }
    }
    return rows;
  }

  static String? _bannerUrl(Map<String, dynamic>? profile) {
    final raw = profile?['banner_url']?.toString() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    return raw;
  }

  static String? _effectUrl(Map<String, dynamic>? profile) {
    final raw = profile?['profile_effect_url']?.toString() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    return raw;
  }

  static String? _nameplateUrl(Map<String, dynamic>? profile) {
    final raw = profile?['nameplate_theme']?.toString() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    return raw;
  }

  static String _resolveNameplateUrl(String url) {
    if (url.endsWith('.webm')) {
      return url
          .replaceAll('asset.webm', 'static.png')
          .replaceAll('.webm', '.png');
    }
    return url;
  }

  static Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'app_owner':
      case 'appowner':
        return Colors.amber.shade800;
      case 'super_admin':
      case 'superadmin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static List<Widget> _breakdownChips(BuildContext context, UserPoints points) {
    final colorScheme = Theme.of(context).colorScheme;
    final b = points.breakdown;
    final parts = <MapEntry<String, int>>[
      MapEntry('Comments', b.commentsPoints),
      MapEntry('Replies', b.repliesPoints),
      MapEntry('Upvotes', b.upvotesReceivedPoints),
      MapEntry('Votes cast', b.votesCastPoints),
      MapEntry('Pinned', b.pinnedPoints),
      MapEntry('Streak bonus', b.streakBonus),
      MapEntry('Role bonus', b.roleBonus),
    ];
    return [
      for (final p in parts)
        if (p.value > 0)
          _chip(
            context,
            '${p.key} +${p.value}',
            colorScheme.onSurfaceVariant,
          ),
    ];
  }

  static String _until(dynamic raw) {
    if (raw == null) return 'active';
    final s = raw.toString();
    if (s.isEmpty || s == 'null') return 'active';
    try {
      return 'until ${DateFormat('MMM d, y').format(DateTime.parse(s).toLocal())}';
    } catch (_) {
      return 'active';
    }
  }

  static Widget _chip(BuildContext context, String label, Color color,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          AnymeXText(
            label,
            size: 11,
            variant: TextVariant.bold,
            color: color,
          ),
        ],
      ),
    );
  }

  static Widget _statTile(BuildContext context, IconData icon, String value,
      String label, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          AnymeXText(
            value,
            size: 17,
            variant: TextVariant.bold,
            color: colorScheme.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          AnymeXText(
            label,
            size: 11,
            color: colorScheme.onSurfaceVariant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _memberSinceTile(
      BuildContext context, Map<String, dynamic>? profile) {
    final raw = profile?['created_at']?.toString();
    String value = '—';
    if (raw != null && raw.isNotEmpty && raw != 'null') {
      try {
        value = DateFormat('MMM y').format(DateTime.parse(raw).toLocal());
      } catch (_) {}
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake_outlined, size: 24, color: colorScheme.tertiary),
          const SizedBox(height: 8),
          AnymeXText(
            value,
            size: 17,
            variant: TextVariant.bold,
            color: colorScheme.onSurface,
            maxLines: 1,
          ),
          AnymeXText(
            'Member since',
            size: 11,
            color: colorScheme.onSurfaceVariant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: AnymeXText(
              label,
              size: 13,
              color: colorScheme.onSurface,
            ),
          ),
          if (value.isNotEmpty)
            AnymeXText(
              value,
              size: 12,
              variant: TextVariant.bold,
              color: color,
            ),
        ],
      ),
    );
  }
}
