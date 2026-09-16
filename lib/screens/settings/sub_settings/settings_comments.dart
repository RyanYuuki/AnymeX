import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Commentum v2'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commentum v2 is an advanced comment system that provides:'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMarkdownGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Markdown Guide'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'You can use Discord-style markdown to format your comments:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 12),
              _MarkdownExample(
                syntax: '**bold text**',
                label: 'Bold',
                example: 'bold text',
              ),
              _MarkdownExample(
                syntax: '*italic text*',
                label: 'Italic',
                example: 'italic text',
              ),
              _MarkdownExample(
                syntax: '***bold italic***',
                label: 'Bold + Italic',
                example: 'bold italic',
              ),
              _MarkdownExample(
                syntax: '~~strikethrough~~',
                label: 'Strikethrough',
                example: 'strikethrough',
              ),
              _MarkdownExample(
                syntax: '`inline code`',
                label: 'Inline Code',
                example: 'inline code',
              ),
              _MarkdownExample(
                syntax: '||spoiler text||',
                label: 'Spoiler (tap to reveal)',
                example: '|||||||||',
                isSpoiler: true,
              ),
              _MarkdownExample(
                syntax: '> blockquote',
                label: 'Blockquote',
                example: 'blockquote',
              ),
              _MarkdownExample(
                syntax: '@username',
                label: 'Mention',
                example: '@username',
              ),
              _MarkdownExample(
                syntax: 'https://example.com',
                label: 'Link (auto-detected)',
                example: 'https://example.com',
              ),
              _MarkdownExample(
                syntax: 'https://example.com/image.png',
                label: 'Image (shows thumbnail)',
                example: '🖼 image',
              ),
              SizedBox(height: 12),
              Text(
                  'Tip: You can combine these! e.g. **bold and *italic* together**',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use the comment system:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            BulletPoint(
                text:
                    'Log in with your AniList, MyAnimeList, or SIMKL account'),
            BulletPoint(
                text: 'Comments are automatically linked to your account'),
            BulletPoint(text: 'You can edit or delete your own comments'),
            BulletPoint(text: 'Vote on comments you like or dislike'),
            BulletPoint(text: 'Report inappropriate content to moderators'),
            SizedBox(height: 12),
            Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
                '• Contact moderators for content issues\n• Report bugs through the app settings\n• Join our Discord community for support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Safety'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your privacy is important:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            BulletPoint(
                text: 'Only your username and avatar are shown publicly'),
            BulletPoint(text: 'Your personal information is never shared'),
            BulletPoint(
                text:
                    'Comments can be deleted but may be retained for moderation'),
            BulletPoint(text: 'Reported content is reviewed by moderators'),
            SizedBox(height: 12),
            Text('Safety features:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Content filtering and moderation'),
            BulletPoint(text: 'User reporting system'),
            BulletPoint(text: 'Ban and warning system for violations'),
            BulletPoint(text: 'Shadow banning for repeat offenders'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
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
