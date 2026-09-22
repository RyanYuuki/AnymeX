import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/comments/model/user_points.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Modern, premium server-data profile card shown when tapping a username/avatar in comments.
///
/// Features:
/// - Full-width hero banner header with gradient fade and smooth profile effects
/// - Depth-elevated avatar overlapping the banner
/// - Nameplate pill or bold typography with Discord & linked accounts badges
/// - Glassmorphic pills for points, rank, role, and active streak
/// - Theme-reactive activity stats grid with crisp tinted icons
/// - Private moderation records (visible only to user & moderators)
/// - Themed primary action button linking to full profile
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
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final currentUserId =
            Get.find<ServiceHandler>().profileData.value.id?.toString();
        final isSelf = comment.userId == currentUserId;
        final canViewPrivate = isSelf || controller.canModerate();

        return AnymeXContainer(
          height: MediaQuery.of(context).size.height * 0.82,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
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
                children: [
                  // 1. Hero Banner + Avatar Header
                  _buildHeroHeader(
                    context,
                    colorScheme: colorScheme,
                    comment: comment,
                    profile: profile,
                  ),

                  // 2. Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          // Username, Badges & Nameplate
                          _buildNameSection(
                            context,
                            colorScheme: colorScheme,
                            comment: comment,
                            profile: profile,
                          ),
                          const SizedBox(height: 12),

                          // Points, Rank, Role & Streak Pills
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: ExpressiveLoadingIndicator(),
                              ),
                            )
                          else if (points != null)
                            _buildPillsWrap(
                              context,
                              colorScheme: colorScheme,
                              points: points,
                            )
                          else
                            Center(
                              child: AnymeXText(
                                'Stats unavailable',
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 18),

                          // Activity & Public Stats Grid
                          if (!isLoading && points != null) ...[
                            _buildSectionHeader(
                              icon: Icons.bar_chart_rounded,
                              title: 'Activity & Stats',
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 10),
                            _buildStatsGrid(
                              context,
                              colorScheme: colorScheme,
                              points: points,
                              profile: profile,
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Points Breakdown
                          if (!isLoading &&
                              points != null &&
                              _breakdownChips(context, points).isNotEmpty) ...[
                            _buildSectionHeader(
                              icon: Icons.pie_chart_outline_rounded,
                              title: 'Points Breakdown',
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _breakdownChips(context, points),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Moderation Record (Self + Mods Only)
                          if (!isLoading &&
                              canViewPrivate &&
                              _hasPrivateInfo(points, profile)) ...[
                            _buildSectionHeader(
                              icon: Icons.shield_outlined,
                              title: isSelf
                                  ? 'Your Moderation Record'
                                  : 'Moderation Record',
                              colorScheme: colorScheme,
                              iconColor: colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            AnymeXContainer(
                              radius: 16,
                              color: colorScheme.errorContainer
                                  .withOpacity(0.08),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Column(
                                children: _privateRows(context, points, profile),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 8),

                          // Full Profile Button
                          AnymeXButton(
                            width: double.infinity,
                            height: 48,
                            borderRadius: BorderRadius.circular(14),
                            backgroundColor: colorScheme.primary,
                            onTap: () {
                              Navigator.pop(context);
                              final parsedId = int.tryParse(comment.userId);
                              if (isSelf) {
                                navigate(() => const ProfilePage());
                              } else if (parsedId != null && parsedId > 0) {
                                navigate(
                                    () => UserProfilePage(userId: parsedId));
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 18, color: colorScheme.onPrimary),
                                const SizedBox(width: 8),
                                AnymeXText(
                                  'View Full Profile',
                                  variant: TextVariant.bold,
                                  size: 14,
                                  color: colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Header with Banner, Scrim, Handle, and Depth-Elevated Avatar
  // ---------------------------------------------------------------------------
  static Widget _buildHeroHeader(
    BuildContext context, {
    required ColorScheme colorScheme,
    required Comment comment,
    required Map<String, dynamic>? profile,
  }) {
    final banner = _bannerUrl(profile);
    final effect = _effectUrl(profile);
    final renderEffects = Get.isRegistered<CommentumService>() &&
        Get.find<CommentumService>().renderProfileEffects.value;

    return SizedBox(
      height: 155,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner Image or Themed Gradient Scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 115,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (banner != null)
                    CachedNetworkImage(
                      imageUrl: banner,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildDefaultBanner(colorScheme),
                    )
                  else
                    _buildDefaultBanner(colorScheme),

                  // Smooth dark gradient overlay for text and depth contrast
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            colorScheme.surface.withOpacity(0.7),
                            colorScheme.surface,
                          ],
                          stops: const [0.0, 0.3, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Profile Effect Overlay
                  if (renderEffects && effect != null && effect.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.65,
                          child: CachedNetworkImage(
                            imageUrl: effect,
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
          ),

          // Floating Drag Handle
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: AnymeXContainer(
                width: 38,
                height: 4.5,
                radius: 3,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ),

          // Depth-Elevated Avatar Overlapping the Banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: AnymeXDecoratedAvatar(
                  avatarUrl: comment.avatarUrl,
                  decorationUrl: comment.avatarDecoration,
                  size: 78,
                  decorationScale: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDefaultBanner(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.3),
            colorScheme.secondary.withOpacity(0.2),
            colorScheme.surfaceContainerHigh,
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Name, Badges & Nameplate Section
  // ---------------------------------------------------------------------------
  static Widget _buildNameSection(
    BuildContext context, {
    required ColorScheme colorScheme,
    required Comment comment,
    required Map<String, dynamic>? profile,
  }) {
    final rawNameplate = comment.nameplateTheme ?? _nameplateUrl(profile);
    final commentum = Get.isRegistered<CommentumService>()
        ? Get.find<CommentumService>()
        : null;
    final hasNameplate = (commentum?.renderNameplates.value ?? true) &&
        rawNameplate != null &&
        rawNameplate.trim().isNotEmpty;

    final nameRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: AnymeXText(
            comment.username,
            variant: TextVariant.bold,
            size: hasNameplate ? 16 : 19,
            color: hasNameplate ? Colors.white : colorScheme.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (comment.badges != null && comment.badges!.isNotEmpty) ...[
          const SizedBox(width: 8),
          DiscordBadgesRow(badges: comment.badges, size: 17.0),
        ],
        if (comment.linkedAccounts?.isNotEmpty == true) ...[
          const SizedBox(width: 8),
          LinkedAccountsBadges(
            linkedAccounts: comment.linkedAccounts,
            fontSize: 9.0,
          ),
        ],
      ],
    );

    if (hasNameplate) {
      final resolvedUrl = _resolveNameplateUrl(rawNameplate!.trim());
      return Center(
        child: AnymeXContainer(
          radius: 12,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
            image: DecorationImage(
              image: CachedNetworkImageProvider(resolvedUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: Colors.black.withOpacity(0.38),
            child: nameRow,
          ),
        ),
      );
    }

    return Center(child: nameRow);
  }

  // ---------------------------------------------------------------------------
  // Points, Rank, Role & Streak Pills Wrap
  // ---------------------------------------------------------------------------
  static Widget _buildPillsWrap(
    BuildContext context, {
    required ColorScheme colorScheme,
    required UserPoints points,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          context,
          '${points.displayPoints} pts',
          colorScheme.primary,
          icon: Icons.stars_rounded,
        ),
        if (points.rank != null && points.rank! > 0)
          _chip(
            context,
            '#${points.rank}',
            const Color(0xFFFFD700),
            icon: Icons.leaderboard_rounded,
          ),
        if (points.role != null && points.role != 'user')
          _chip(
            context,
            points.role!.replaceAll('_', ' ').toUpperCase(),
            _roleColor(points.role!),
            icon: Icons.verified_user_rounded,
          ),
        if (points.currentStreak > 0)
          _chip(
            context,
            '${points.currentStreak}d streak',
            Colors.orange,
            icon: Icons.local_fire_department_rounded,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Public Activity Stats Grid
  // ---------------------------------------------------------------------------
  static Widget _buildStatsGrid(
    BuildContext context, {
    required ColorScheme colorScheme,
    required UserPoints points,
    required Map<String, dynamic>? profile,
  }) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.98,
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
          colorScheme.secondary,
        ),
        _statTile(
          context,
          Icons.thumb_up_alt_outlined,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Section Header Helper
  // ---------------------------------------------------------------------------
  static Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? colorScheme.primary),
        const SizedBox(width: 8),
        AnymeXText(
          title,
          size: 13,
          variant: TextVariant.bold,
          color: colorScheme.onSurface,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Modern Themed Pill Chip
  // ---------------------------------------------------------------------------
  static Widget _chip(
    BuildContext context,
    String label,
    Color color, {
    IconData? icon,
  }) {
    return AnymeXContainer(
      radius: 20,
      color: color.withOpacity(0.12),
      border: Border.all(color: color.withOpacity(0.35)),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          AnymeXText(
            label,
            size: 11.5,
            variant: TextVariant.bold,
            color: color,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Themed Stat Tile
  // ---------------------------------------------------------------------------
  static Widget _statTile(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnymeXContainer(
      radius: 16,
      color: colorScheme.surfaceContainerLow,
      border: Border.all(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnymeXContainer(
            width: 32,
            height: 32,
            radius: 16,
            color: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          AnymeXText(
            value,
            size: 16,
            variant: TextVariant.bold,
            color: colorScheme.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
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

  // ---------------------------------------------------------------------------
  // Member Since Stat Tile
  // ---------------------------------------------------------------------------
  static Widget _memberSinceTile(
    BuildContext context,
    Map<String, dynamic>? profile,
  ) {
    final raw = profile?['created_at']?.toString();
    String value = '—';
    if (raw != null && raw.isNotEmpty && raw != 'null') {
      try {
        value = DateFormat('MMM y').format(DateTime.parse(raw).toLocal());
      } catch (_) {}
    }
    final colorScheme = Theme.of(context).colorScheme;

    return AnymeXContainer(
      radius: 16,
      color: colorScheme.surfaceContainerLow,
      border: Border.all(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnymeXContainer(
            width: 32,
            height: 32,
            radius: 16,
            color: colorScheme.tertiary.withOpacity(0.12),
            child: Icon(Icons.cake_outlined,
                size: 18, color: colorScheme.tertiary),
          ),
          const SizedBox(height: 6),
          AnymeXText(
            value,
            size: 16,
            variant: TextVariant.bold,
            color: colorScheme.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
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

  // ---------------------------------------------------------------------------
  // Points Breakdown Chips
  // ---------------------------------------------------------------------------
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
          AnymeXContainer(
            radius: 10,
            color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: AnymeXText(
              '${p.key} +${p.value}',
              size: 11.5,
              variant: TextVariant.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Moderation / Private Section Helpers
  // ---------------------------------------------------------------------------
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

  static Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  // ---------------------------------------------------------------------------
  // URL & Style Utilities
  // ---------------------------------------------------------------------------
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
}
