import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/leaderboard_sheet.dart';
import 'package:anymex/screens/profile/widgets/decoration_closet_sheet.dart';
import 'package:anymex/screens/settings/sub_settings/settings_moderation.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsComments extends StatefulWidget {
  const SettingsComments({super.key});

  @override
  State<SettingsComments> createState() => _SettingsCommentsState();
}

class _SettingsCommentsState extends State<SettingsComments> {
  final commentumService = Get.find<CommentumService>();

  final RxBool _isLoadingPreferences = true.obs;
  final RxBool _notifyOnReply = true.obs;
  final RxBool _notifyOnMention = true.obs;
  final RxBool _notifyOnAnnouncement = true.obs;
  final RxBool _notifyOnRecentComment = true.obs;
  final RxBool _notifyOnVote = true.obs;
  final RxBool _notifyOnCommentDelete = false.obs;
  final RxBool _notifyOnModAction = true.obs;

  @override
  void initState() {
    super.initState();
    commentumService.getUserRole();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (commentumService.currentUserId == null) {
      _isLoadingPreferences.value = false;
      return;
    }
    _isLoadingPreferences.value = true;
    final prefs = await commentumService.getNotificationPreferences();
    if (prefs.isNotEmpty) {
      _notifyOnReply.value = prefs['notify_on_reply'] ?? true;
      _notifyOnMention.value = prefs['notify_on_mention'] ?? true;
      _notifyOnAnnouncement.value = prefs['notify_on_announcement'] ?? true;
      _notifyOnRecentComment.value = prefs['notify_on_recent_comment'] ?? true;
      _notifyOnVote.value = prefs['notify_on_vote'] ?? true;
      _notifyOnCommentDelete.value = prefs['notify_on_comment_delete'] ?? false;
      _notifyOnModAction.value = prefs['notify_on_mod_action'] ?? true;
    }
    _isLoadingPreferences.value = false;
  }

  Future<void> _updatePreference(String key, RxBool rxVal, bool newVal) async {
    final oldVal = rxVal.value;
    rxVal.value = newVal;
    final success =
        await commentumService.updateNotificationPreferences({key: newVal});
    if (!success) {
      rxVal.value = oldVal;
      snackBar(Get.context!.l10n.failedToUpdatePreference);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.communityComments,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymeXSectionBuilder(
                title: context.l10n.closetCommunity,
                children: [
                  AnymeXTile(
                    icon: Icons.checkroom_rounded,
                    title: context.l10n.openCloset,
                    subtitle:
                        context.l10n.avatarDecorationsNameplatesBannersProfileEffects,
                    onTap: () => DecorationClosetSheet.show(context),
                  ),
                  AnymeXTile(
                    icon: Icons.emoji_events_rounded,
                    title: context.l10n.leaderboard,
                    subtitle:
                        context.l10n.viewUserRankingsTopContributorsReputation,
                    onTap: () => LeaderboardSheet.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final commentum = Get.isRegistered<CommentumService>()
                    ? Get.find<CommentumService>()
                    : null;
                if (commentum == null) return const SizedBox.shrink();
                return AnymeXSectionBuilder(
                  title: context.l10n.appearance,
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.auto_awesome_rounded,
                      title: context.l10n.avatarDecorations,
                      subtitle: context.l10n.showAnimatedFramesAroundUserAvatars,
                      value: commentum.renderAvatarDecorations.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderAvatarDecorations, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.badge_outlined,
                      title: context.l10n.nameplates,
                      subtitle:
                          context.l10n.showNameplateBackgroundsOnCommentCards,
                      value: commentum.renderNameplates.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderNameplates, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.blur_on_rounded,
                      title: context.l10n.profileEffects,
                      subtitle:
                          context.l10n.showAnimatedEffectOverlaysOnProfile,
                      value: commentum.renderProfileEffects.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderProfileEffects, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.image_outlined,
                      title: context.l10n.customBanners,
                      subtitle:
                          context.l10n.showCustomProfileBannersFallsBack,
                      value: commentum.renderBanners.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderBanners, v),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                if (commentumService.currentUserId == null) {
                  return AnymeXSectionBuilder(
                    title: context.l10n.notificationPreferences,
                    children: [
                      AnymeXTile(
                        icon: Icons.notifications_off_outlined,
                        title: context.l10n.logInRequired,
                        subtitle:
                            context.l10n.logInToCustomizeYourPush,
                        showChevron: false,
                      ),
                    ],
                  );
                }

                if (_isLoadingPreferences.value) {
                  return AnymeXSectionBuilder(
                    title: context.l10n.notificationPreferences,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                    ],
                  );
                }

                return AnymeXSectionBuilder(
                  title: context.l10n.notificationPreferences,
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.reply_rounded,
                      title: context.l10n.commentReplies,
                      subtitle: context.l10n.notifyWhenSomeoneRepliesToYour,
                      value: _notifyOnReply.value,
                      onChanged: (v) =>
                          _updatePreference('notify_on_reply', _notifyOnReply, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.alternate_email_rounded,
                      title: context.l10n.mentions,
                      subtitle: context.l10n.notifyWhenSomeoneMentionsYourUsername,
                      value: _notifyOnMention.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_mention', _notifyOnMention, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.campaign_outlined,
                      title: context.l10n.announcements,
                      subtitle:
                          context.l10n.notifyForOfficialAnnouncementsAndApp,
                      value: _notifyOnAnnouncement.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_announcement', _notifyOnAnnouncement, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.forum_outlined,
                      title: context.l10n.recentMediaComments,
                      subtitle:
                          context.l10n.notifyOnNewCommentsForMedia,
                      value: _notifyOnRecentComment.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_recent_comment',
                          _notifyOnRecentComment,
                          v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.thumb_up_alt_outlined,
                      title: context.l10n.votes,
                      subtitle: context.l10n.notifyOnUpvotesAndDownvotes,
                      value: _notifyOnVote.value,
                      onChanged: (v) =>
                          _updatePreference('notify_on_vote', _notifyOnVote, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.delete_outline_rounded,
                      title: context.l10n.commentDeleted,
                      subtitle:
                          context.l10n.notifyIfYourCommentIsRemoved,
                      value: _notifyOnCommentDelete.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_comment_delete',
                          _notifyOnCommentDelete,
                          v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.shield_outlined,
                      title: context.l10n.moderationActions,
                      subtitle:
                          context.l10n.notifyOnWarningsPinnedCommentsOr,
                      value: _notifyOnModAction.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_mod_action', _notifyOnModAction, v),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: context.l10n.helpInformation,
                children: [
                  AnymeXTile(
                    icon: Icons.info_outline_rounded,
                    title: context.l10n.aboutCommentumV2,
                    subtitle:
                        context.l10n.poweredByCommentumV2AdvancedComment,
                    onTap: _showAboutDialog,
                  ),
                  AnymeXTile(
                    icon: Icons.code_rounded,
                    title: context.l10n.markdownGuide,
                    subtitle: context.l10n.learnHowToFormatYourComments,
                    onTap: _showMarkdownGuide,
                  ),
                  AnymeXTile(
                    icon: Icons.help_outline_rounded,
                    title: context.l10n.helpSupport,
                    subtitle: context.l10n.getHelpWithTheCommentSystem,
                    onTap: _showHelpDialog,
                  ),
                  AnymeXTile(
                    icon: Icons.privacy_tip_outlined,
                    title: context.l10n.privacySafety,
                    subtitle: context.l10n.privacySettingsAndSafetyFeatures,
                    onTap: _showPrivacyDialog,
                  ),
                ],
              ),
              Obx(() {
                if (commentumService.currentUserRole.value == 'user') {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    AnymeXSectionBuilder(
                      title: context.l10n.moderation,
                      children: [
                        AnymeXTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: context.l10n.moderationPanel,
                          subtitle: context.l10n.accessModerationToolsAndReports,
                          onTap: () {
                            navigate(() => const SettingsModeration());
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    AnymeXDialog(
      title: context.l10n.aboutCommentumV2,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            context.l10n.commentumV2IsAnAdvancedComment,
            variant: TextVariant.semiBold,
            size: 14,
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
              context, 'Real-time commenting with nested replies'),
          _buildBulletPoint(context, 'Advanced moderation tools'),
          _buildBulletPoint(context,
              'User role management (User, Moderator, Admin, Super Admin)'),
          _buildBulletPoint(context, 'Content reporting and safety features'),
          _buildBulletPoint(context, 'Voting system with upvotes/downvotes'),
          _buildBulletPoint(
              context, 'Cross-platform support (AniList, MyAnimeList, SIMKL)'),
        ],
      ),
      showCancelButton: false,
      confirmText: context.l10n.close,
      onConfirm: () {},
    ).show(context);
  }

  void _showMarkdownGuide() {
    AnymeXDialog(
      title: context.l10n.markdownGuide,
      contentWidget: _buildMarkdownGuideContent(context),
      showCancelButton: false,
      confirmText: context.l10n.gotIt,
      onConfirm: () {},
    ).show(context);
  }

  void _showHelpDialog() {
    AnymeXDialog(
      title: context.l10n.helpSupport,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            context.l10n.howToUseTheCommentSystem,
            variant: TextVariant.bold,
            size: 14,
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
              context, 'Log in with your AniList, MyAnimeList, or SIMKL account'),
          _buildBulletPoint(
              context, 'Comments are automatically linked to your account'),
          _buildBulletPoint(context, 'You can edit or delete your own comments'),
          _buildBulletPoint(context, 'Vote on comments you like or dislike'),
          _buildBulletPoint(
              context, 'Report inappropriate content to moderators'),
          const SizedBox(height: 16),
          AnymeXText(
            context.l10n.needHelp,
            variant: TextVariant.bold,
            size: 14,
          ),
          const SizedBox(height: 6),
          _buildBulletPoint(context, 'Contact moderators for content issues'),
          _buildBulletPoint(context, 'Report bugs through the app settings'),
          _buildBulletPoint(context, 'Join our Discord community for support'),
        ],
      ),
      showCancelButton: false,
      confirmText: context.l10n.close,
      onConfirm: () {},
    ).show(context);
  }

  void _showPrivacyDialog() {
    AnymeXDialog(
      title: context.l10n.privacySafety,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            context.l10n.yourPrivacyIsImportant,
            variant: TextVariant.bold,
            size: 14,
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
              context, 'Only your username and avatar are shown publicly'),
          _buildBulletPoint(
              context, 'Your personal information is never shared'),
          _buildBulletPoint(context,
              'Comments can be deleted but may be retained for moderation'),
          _buildBulletPoint(
              context, 'Reported content is reviewed by moderators'),
          const SizedBox(height: 16),
          AnymeXText(
            context.l10n.safetyFeatures,
            variant: TextVariant.bold,
            size: 14,
          ),
          const SizedBox(height: 6),
          _buildBulletPoint(context, 'Content filtering and moderation'),
          _buildBulletPoint(context, 'User reporting system'),
          _buildBulletPoint(context, 'Ban and warning system for violations'),
          _buildBulletPoint(context, 'Shadow banning for repeat offenders'),
        ],
      ),
      showCancelButton: false,
      confirmText: context.l10n.close,
      onConfirm: () {},
    ).show(context);
  }

  Widget _buildMarkdownGuideContent(BuildContext context) {
    final theme = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXText(
          context.l10n.youCanUseDiscordStyleMarkdown,
          variant: TextVariant.regular,
          size: 13,
          color: theme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        _buildMarkdownExample(context, syntax: '**bold text**', label: context.l10n.bold),
        _buildMarkdownExample(context, syntax: '*italic text*', label: context.l10n.italic),
        _buildMarkdownExample(
            context, syntax: '***bold italic***', label: context.l10n.boldItalic),
        _buildMarkdownExample(
            context, syntax: '~~strikethrough~~', label: context.l10n.strikethrough),
        _buildMarkdownExample(
            context, syntax: '`inline code`', label: context.l10n.inlineCode),
        _buildMarkdownExample(
            context, syntax: '||spoiler text||', label: context.l10n.spoilerTapToReveal),
        _buildMarkdownExample(context, syntax: '> blockquote', label: context.l10n.blockquote),
        _buildMarkdownExample(context, syntax: '@username', label: context.l10n.mention),
        _buildMarkdownExample(
            context, syntax: 'https://example.com', label: context.l10n.linkAutoDetected),
        _buildMarkdownExample(context,
            syntax: 'https://example.com/image.png',
            label: context.l10n.imageShowsThumbnail),
        const SizedBox(height: 8),
        AnymeXText(
          context.l10n.tipYouCanCombineTheseE,
          variant: TextVariant.regular,
          size: 12,
          fontStyle: FontStyle.italic,
          color: theme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildMarkdownExample(
    BuildContext context, {
    required String syntax,
    required String label,
  }) {
    final theme = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnymeXContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                radius: 6,
                color: theme.primaryContainer,
                child: AnymeXText(
                  label,
                  variant: TextVariant.bold,
                  size: 11,
                  color: theme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AnymeXContainer(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            radius: 8,
            color: theme.surfaceContainerHighest.opaque(0.4),
            border: Border.all(color: theme.outlineVariant.opaque(0.3)),
            child: SelectableText(
              syntax,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: theme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: AnymeXText(
              text,
              variant: TextVariant.regular,
              size: 13,
              color: theme.onSurface,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}
