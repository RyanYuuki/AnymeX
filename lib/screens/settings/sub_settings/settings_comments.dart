import 'package:anymex/database/data_keys/keys.dart';
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
      snackBar('Failed to update preference');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Comment System',
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
                title: 'General',
                children: [
                  AnymeXTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Commentum v2',
                    subtitle:
                        'Powered by Commentum v2 - Advanced comment system with moderation',
                    onTap: _showAboutDialog,
                  ),
                  AnymeXTile(
                    icon: Icons.code_rounded,
                    title: 'Markdown Guide',
                    subtitle: 'Learn how to format your comments',
                    onTap: _showMarkdownGuide,
                  ),
                  AnymeXTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Get help with the comment system',
                    onTap: _showHelpDialog,
                  ),
                  AnymeXTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy & Safety',
                    subtitle: 'Privacy settings and safety features',
                    onTap: _showPrivacyDialog,
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
                  title: 'Appearance',
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Avatar Decorations',
                      subtitle: 'Show animated frames around user avatars',
                      value: commentum.renderAvatarDecorations.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderAvatarDecorations, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.badge_outlined,
                      title: 'Nameplates',
                      subtitle:
                          'Show nameplate backgrounds on comment cards and leaderboard',
                      value: commentum.renderNameplates.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderNameplates, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.blur_on_rounded,
                      title: 'Profile Effects',
                      subtitle:
                          'Show animated effect overlays on profile banners',
                      value: commentum.renderProfileEffects.value,
                      onChanged: (v) => commentum.saveRenderPref(
                          CommentKeys.renderProfileEffects, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.image_outlined,
                      title: 'Custom Banners',
                      subtitle:
                          'Show custom profile banners (falls back to AniList cover if off)',
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
                  return const AnymeXSectionBuilder(
                    title: 'Notification Preferences',
                    children: [
                      AnymeXTile(
                        icon: Icons.notifications_off_outlined,
                        title: 'Log In Required',
                        subtitle:
                            'Log in to customize your push notification preferences.',
                        showChevron: false,
                      ),
                    ],
                  );
                }

                if (_isLoadingPreferences.value) {
                  return AnymeXSectionBuilder(
                    title: 'Notification Preferences',
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
                  title: 'Notification Preferences',
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.reply_rounded,
                      title: 'Comment Replies',
                      subtitle: 'Notify when someone replies to your comment',
                      value: _notifyOnReply.value,
                      onChanged: (v) =>
                          _updatePreference('notify_on_reply', _notifyOnReply, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.alternate_email_rounded,
                      title: 'Mentions',
                      subtitle: 'Notify when someone @mentions your username',
                      value: _notifyOnMention.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_mention', _notifyOnMention, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.campaign_outlined,
                      title: 'Announcements',
                      subtitle:
                          'Notify for official announcements and app updates',
                      value: _notifyOnAnnouncement.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_announcement', _notifyOnAnnouncement, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.forum_outlined,
                      title: 'Recent Media Comments',
                      subtitle:
                          'Notify on new comments for media you discussed',
                      value: _notifyOnRecentComment.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_recent_comment',
                          _notifyOnRecentComment,
                          v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.thumb_up_alt_outlined,
                      title: 'Votes',
                      subtitle: 'Notify on upvotes and downvotes',
                      value: _notifyOnVote.value,
                      onChanged: (v) =>
                          _updatePreference('notify_on_vote', _notifyOnVote, v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.delete_outline_rounded,
                      title: 'Comment Deleted',
                      subtitle:
                          'Notify if your comment is removed by a moderator',
                      value: _notifyOnCommentDelete.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_comment_delete',
                          _notifyOnCommentDelete,
                          v),
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.shield_outlined,
                      title: 'Moderation Actions',
                      subtitle:
                          'Notify on warnings, pinned comments, or thread locks',
                      value: _notifyOnModAction.value,
                      onChanged: (v) => _updatePreference(
                          'notify_on_mod_action', _notifyOnModAction, v),
                    ),
                  ],
                );
              }),
              Obx(() {
                if (commentumService.currentUserRole.value == 'user') {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    AnymeXSectionBuilder(
                      title: 'Moderation',
                      children: [
                        AnymeXTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Moderation Panel',
                          subtitle: 'Access moderation tools and reports',
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
      title: 'About Commentum v2',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnymeXText(
            'Commentum v2 is an advanced comment system that provides:',
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
      confirmText: 'Close',
      onConfirm: () {},
    ).show(context);
  }

  void _showMarkdownGuide() {
    AnymeXDialog(
      title: 'Markdown Guide',
      contentWidget: _buildMarkdownGuideContent(context),
      showCancelButton: false,
      confirmText: 'Got it',
      onConfirm: () {},
    ).show(context);
  }

  void _showHelpDialog() {
    AnymeXDialog(
      title: 'Help & Support',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnymeXText(
            'How to use the comment system:',
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
          const AnymeXText(
            'Need help?',
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
      confirmText: 'Close',
      onConfirm: () {},
    ).show(context);
  }

  void _showPrivacyDialog() {
    AnymeXDialog(
      title: 'Privacy & Safety',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnymeXText(
            'Your privacy is important:',
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
          const AnymeXText(
            'Safety features:',
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
      confirmText: 'Close',
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
          'You can use Discord-style markdown to format your comments:',
          variant: TextVariant.regular,
          size: 13,
          color: theme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        _buildMarkdownExample(context, syntax: '**bold text**', label: 'Bold'),
        _buildMarkdownExample(context, syntax: '*italic text*', label: 'Italic'),
        _buildMarkdownExample(
            context, syntax: '***bold italic***', label: 'Bold + Italic'),
        _buildMarkdownExample(
            context, syntax: '~~strikethrough~~', label: 'Strikethrough'),
        _buildMarkdownExample(
            context, syntax: '`inline code`', label: 'Inline Code'),
        _buildMarkdownExample(
            context, syntax: '||spoiler text||', label: 'Spoiler (tap to reveal)'),
        _buildMarkdownExample(context, syntax: '> blockquote', label: 'Blockquote'),
        _buildMarkdownExample(context, syntax: '@username', label: 'Mention'),
        _buildMarkdownExample(
            context, syntax: 'https://example.com', label: 'Link (auto-detected)'),
        _buildMarkdownExample(context,
            syntax: 'https://example.com/image.png',
            label: 'Image (shows thumbnail)'),
        const SizedBox(height: 8),
        AnymeXText(
          'Tip: You can combine these! e.g. **bold and *italic* together**',
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
