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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(context).colorScheme;
        final currentUserId =
            Get.find<ServiceHandler>().profileData.value.id?.toString();
        final isSelf = comment.userId == currentUserId;
        final canViewPrivate = isSelf || controller.canModerate();

        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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

                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
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

                      // 1. Center avatar with decoration
                      Center(
                        child: AnymeXDecoratedAvatar(
                          avatarUrl: comment.avatarUrl,
                          decorationUrl: comment.avatarDecoration,
                          size: 76,
                          decorationScale: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Name + badges (centered)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AnymeXText(
                              comment.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: colorScheme.onSurface,
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
                      ),
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
                              '${points.tierEmoji} ${points.tier.toUpperCase()}'
                                  .trim(),
                              colorScheme.primary,
                            ),
                            _chip(
                              context,
                              '${points.displayPoints} pts',
                              colorScheme.primary,
                            ),
                            if (points.currentStreak > 0)
                              _chip(
                                context,
                                '🔥 ${points.currentStreak}d streak',
                                Colors.orange,
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

                      // 4. Public stats grid (server data, never placeholders)
                      if (!isLoading && points != null) ...[
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.6,
                          children: [
                            _statTile(
                              context,
                              Icons.chat_bubble_outline_rounded,
                              '${points.stats.totalComments}',
                              'Comments posted',
                            ),
                            _statTile(
                              context,
                              Icons.reply_rounded,
                              '${points.stats.totalReplies}',
                              'Replies',
                            ),
                            _statTile(
                              context,
                              Icons.thumb_up_outlined,
                              '${points.stats.totalUpvotesReceived}',
                              'Upvotes received',
                            ),
                            _statTile(
                              context,
                              Icons.how_to_vote_outlined,
                              '${points.stats.totalVotesCast}',
                              'Votes cast',
                            ),
                            _statTile(
                              context,
                              Icons.local_fire_department_outlined,
                              '${points.longestStreak}d',
                              'Longest streak',
                            ),
                            _memberSinceTile(context, profile),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                            Navigator.pop(sheetContext);
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
                          label: const AnymeXText(
                            'View Full Profile',
                            variant: TextVariant.bold,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  static bool _hasPrivateInfo(
      UserPoints? points, Map<String, dynamic>? profile) {
    if (points == null) return false;
    if ((points.breakdown.warningsPoints.abs()) > 0) return true;
    if ((points.breakdown.deletedPoints.abs()) > 0) return true;
    if ((points.breakdown.bannedPoints.abs()) > 0) return true;
    if (profile == null) return false;
    if (profile['banned'] == true ||
        profile['muted'] == true ||
        profile['shadow_banned'] == true) {
      return true;
    }
    return false;
  }

  static List<Widget> _privateRows(
      BuildContext context, UserPoints? points, Map<String, dynamic>? profile) {
    final rows = <Widget>[];
    if (points != null) {
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
    }
    return rows;
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

  static Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: AnymeXText(
        label,
        size: 11,
        variant: TextVariant.bold,
        color: color,
      ),
    );
  }

  static Widget _statTile(
      BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  value,
                  size: 15,
                  variant: TextVariant.bold,
                  color: colorScheme.onSurface,
                  maxLines: 1,
                ),
                AnymeXText(
                  label,
                  size: 10.5,
                  color: colorScheme.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  value,
                  size: 15,
                  variant: TextVariant.bold,
                  color: colorScheme.onSurface,
                  maxLines: 1,
                ),
                AnymeXText(
                  'Member since',
                  size: 10.5,
                  color: colorScheme.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
