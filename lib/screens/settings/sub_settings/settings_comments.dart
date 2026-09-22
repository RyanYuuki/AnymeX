import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_moderation.dart';

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
    final success = await commentumService.updateNotificationPreferences({key: newVal});
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
              AnymeXExpansionTile(
                title: 'General',
                initialExpanded: true,
                content: Column(
                  children: [
                    CustomTile(
                      icon: Icons.info_outline,
                      title: "About Commentum v2",
                      description:
                          "Powered by Commentum v2 - Advanced comment system with moderation",
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),
                    CustomTile(
                      icon: Icons.code_outlined,
                      title: "Markdown Guide",
                      description: "Learn how to format your comments",
                      onTap: () {
                        _showMarkdownGuide();
                      },
                    ),
                    CustomTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      description: "Get help with the comment system",
                      onTap: () {
                        _showHelpDialog();
                      },
                    ),
                    CustomTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy & Safety",
                      description: "Privacy settings and safety features",
                      onTap: () {
                        _showPrivacyDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnymeXExpansionTile(
                title: 'Appearance',
                initialExpanded: true,
                content: Obx(() {
                  final commentum = Get.isRegistered<CommentumService>()
                      ? Get.find<CommentumService>()
                      : null;
                  if (commentum == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      CustomSwitchTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Avatar Decorations',
                        description:
                            'Show animated frames around user avatars',
                        switchValue: commentum.renderAvatarDecorations.value,
                        onChanged: (v) => commentum.saveRenderPref(
                            CommentKeys.renderAvatarDecorations, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.badge_outlined,
                        title: 'Nameplates',
                        description:
                            'Show nameplate backgrounds on comment cards and leaderboard',
                        switchValue: commentum.renderNameplates.value,
                        onChanged: (v) => commentum.saveRenderPref(
                            CommentKeys.renderNameplates, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.blur_on_rounded,
                        title: 'Profile Effects',
                        description:
                            'Show animated effect overlays on profile banners',
                        switchValue: commentum.renderProfileEffects.value,
                        onChanged: (v) => commentum.saveRenderPref(
                            CommentKeys.renderProfileEffects, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.image_outlined,
                        title: 'Custom Banners',
                        description:
                            'Show custom profile banners (falls back to AniList cover if off)',
                        switchValue: commentum.renderBanners.value,
                        onChanged: (v) => commentum.saveRenderPref(
                            CommentKeys.renderBanners, v),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 12),
              AnymeXExpansionTile(
                title: 'Notification Preferences',
                initialExpanded: true,
                content: Obx(() {
                  if (commentumService.currentUserId == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Log in to customize your push notification preferences.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_isLoadingPreferences.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Column(
                    children: [
                      CustomSwitchTile(
                        icon: Icons.reply_rounded,
                        title: 'Comment Replies',
                        description:
                            'Notify when someone replies to your comment',
                        switchValue: _notifyOnReply.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_reply', _notifyOnReply, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.alternate_email_rounded,
                        title: 'Mentions',
                        description:
                            'Notify when someone @mentions your username',
                        switchValue: _notifyOnMention.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_mention', _notifyOnMention, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.campaign_outlined,
                        title: 'Announcements',
                        description:
                            'Notify for official announcements and app updates',
                        switchValue: _notifyOnAnnouncement.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_announcement', _notifyOnAnnouncement, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.forum_outlined,
                        title: 'Recent Media Comments',
                        description:
                            'Notify on new comments for media you discussed',
                        switchValue: _notifyOnRecentComment.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_recent_comment',
                            _notifyOnRecentComment,
                            v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.thumb_up_alt_outlined,
                        title: 'Votes',
                        description: 'Notify on upvotes and downvotes',
                        switchValue: _notifyOnVote.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_vote', _notifyOnVote, v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Comment Deleted',
                        description:
                            'Notify if your comment is removed by a moderator',
                        switchValue: _notifyOnCommentDelete.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_comment_delete',
                            _notifyOnCommentDelete,
                            v),
                      ),
                      CustomSwitchTile(
                        icon: Icons.shield_outlined,
                        title: 'Moderation Actions',
                        description:
                            'Notify on warnings, pinned comments, or thread locks',
                        switchValue: _notifyOnModAction.value,
                        onChanged: (v) => _updatePreference(
                            'notify_on_mod_action', _notifyOnModAction, v),
                      ),
                    ],
                  );
                }),
              ),
              Obx(() {
                if (commentumService.currentUserRole.value == 'user') {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    AnymeXExpansionTile(
                      title: 'Moderation',
                      initialExpanded: true,
                      content: Column(
                        children: [
                          CustomTile(
                            icon: Icons.admin_panel_settings,
                            title: "Moderation Panel",
                            description:
                                "Access moderation tools and reports",
                            onTap: () {
                              navigate(() => const SettingsModeration());
                            },
                          ),
                        ],
                      ),
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

  void _showThemedDialog({
    required String title,
    required IconData icon,
    required Widget content,
    String buttonText = 'Close',
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: AnymeXContainer(
            padding: const EdgeInsets.all(20),
            radius: 20,
            color: colorScheme.surface,
            border:
                Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnymeXContainer(
                      padding: const EdgeInsets.all(8),
                      radius: 10,
                      color: colorScheme.primary.withOpacity(0.12),
                      child: Icon(icon, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnymeXText(
                        title,
                        variant: TextVariant.bold,
                        size: 17,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: content,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: AnymeXText(
                      buttonText,
                      variant: TextVariant.semiBold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    _showThemedDialog(
      title: 'About Commentum v2',
      icon: Icons.info_outline,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            'Commentum v2 is an advanced comment system that provides:',
            variant: TextVariant.semiBold,
            size: 14,
          ),
          SizedBox(height: 8),
          BulletPoint(text: 'Real-time commenting with nested replies'),
          BulletPoint(text: 'Advanced moderation tools'),
          BulletPoint(
              text:
                  'User role management (User, Moderator, Admin, Super Admin)'),
          BulletPoint(text: 'Content reporting and safety features'),
          BulletPoint(text: 'Voting system with upvotes/downvotes'),
          BulletPoint(
              text: 'Cross-platform support (AniList, MyAnimeList, SIMKL)'),
        ],
      ),
    );
  }

  void _showMarkdownGuide() {
    _showThemedDialog(
      title: 'Markdown Guide',
      icon: Icons.code_outlined,
      buttonText: 'Got it',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            'You can use Discord-style markdown to format your comments:',
            variant: TextVariant.regular,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const _MarkdownExample(
            syntax: '**bold text**',
            label: 'Bold',
            example: 'bold text',
          ),
          const _MarkdownExample(
            syntax: '*italic text*',
            label: 'Italic',
            example: 'italic text',
          ),
          const _MarkdownExample(
            syntax: '***bold italic***',
            label: 'Bold + Italic',
            example: 'bold italic',
          ),
          const _MarkdownExample(
            syntax: '~~strikethrough~~',
            label: 'Strikethrough',
            example: 'strikethrough',
          ),
          const _MarkdownExample(
            syntax: '`inline code`',
            label: 'Inline Code',
            example: 'inline code',
          ),
          const _MarkdownExample(
            syntax: '||spoiler text||',
            label: 'Spoiler (tap to reveal)',
            example: '|||||||||',
            isSpoiler: true,
          ),
          const _MarkdownExample(
            syntax: '> blockquote',
            label: 'Blockquote',
            example: 'blockquote',
          ),
          const _MarkdownExample(
            syntax: '@username',
            label: 'Mention',
            example: '@username',
          ),
          const _MarkdownExample(
            syntax: 'https://example.com',
            label: 'Link (auto-detected)',
            example: 'https://example.com',
          ),
          const _MarkdownExample(
            syntax: 'https://example.com/image.png',
            label: 'Image (shows thumbnail)',
            example: '🖼 image',
          ),
          const SizedBox(height: 12),
          AnymeXText(
            'Tip: You can combine these! e.g. **bold and *italic* together**',
            variant: TextVariant.regular,
            size: 12,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    _showThemedDialog(
      title: 'Help & Support',
      icon: Icons.help_outline,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            'How to use the comment system:',
            variant: TextVariant.bold,
            size: 14,
          ),
          SizedBox(height: 8),
          BulletPoint(
              text:
                  'Log in with your AniList, MyAnimeList, or SIMKL account'),
          BulletPoint(
              text: 'Comments are automatically linked to your account'),
          BulletPoint(text: 'You can edit or delete your own comments'),
          BulletPoint(text: 'Vote on comments you like or dislike'),
          BulletPoint(text: 'Report inappropriate content to moderators'),
          SizedBox(height: 16),
          AnymeXText(
            'Need help?',
            variant: TextVariant.bold,
            size: 14,
          ),
          SizedBox(height: 6),
          BulletPoint(text: 'Contact moderators for content issues'),
          BulletPoint(text: 'Report bugs through the app settings'),
          BulletPoint(text: 'Join our Discord community for support'),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    _showThemedDialog(
      title: 'Privacy & Safety',
      icon: Icons.privacy_tip_outlined,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            'Your privacy is important:',
            variant: TextVariant.bold,
            size: 14,
          ),
          SizedBox(height: 8),
          BulletPoint(
              text: 'Only your username and avatar are shown publicly'),
          BulletPoint(text: 'Your personal information is never shared'),
          BulletPoint(
              text:
                  'Comments can be deleted but may be retained for moderation'),
          BulletPoint(text: 'Reported content is reviewed by moderators'),
          SizedBox(height: 16),
          AnymeXText(
            'Safety features:',
            variant: TextVariant.bold,
            size: 14,
          ),
          SizedBox(height: 6),
          BulletPoint(text: 'Content filtering and moderation'),
          BulletPoint(text: 'User reporting system'),
          BulletPoint(text: 'Ban and warning system for violations'),
          BulletPoint(text: 'Shadow banning for repeat offenders'),
        ],
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: AnymeXText(
              text,
              variant: TextVariant.regular,
              size: 13,
              color: colorScheme.onSurface,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownExample extends StatelessWidget {
  final String syntax;
  final String label;
  final String example;
  final bool isSpoiler;

  const _MarkdownExample({
    required this.syntax,
    required this.label,
    required this.example,
    this.isSpoiler = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                color: colorScheme.primaryContainer,
                child: AnymeXText(
                  label,
                  variant: TextVariant.bold,
                  size: 11,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AnymeXContainer(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            radius: 8,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            border:
                Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
            child: SelectableText(
              syntax,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
