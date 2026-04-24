import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:anymex/screens/other_features.dart';

import 'settings_moderation.dart';

class SettingsComments extends StatefulWidget {
  const SettingsComments({super.key});

  @override
  State<SettingsComments> createState() => _SettingsCommentsState();
}

class _SettingsCommentsState extends State<SettingsComments> {
  final commentumService = Get.find<CommentumService>();

  @override
  void initState() {
    super.initState();
    commentumService.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        const NestedHeader(title: 'Comment System'),
        Expanded(
          child: SuperListView(
            padding: getResponsiveValue(context,
                mobileValue: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                desktopValue:
                    const EdgeInsets.fromLTRB(20.0, 20.0, 25.0, 20.0)),
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .opaque(0.3)),
                child: Column(
                  children: [
                    CustomTile(
                        icon: Icons.info_outline,
                        title: "About Commentum v2",
                        description:
                            "Powered by Commentum v2 - Advanced comment system with moderation",
                        onTap: () {
                          _showAboutDialog();
                        }),
                    const Divider(height: 1),
                    Obx(() => commentumService.currentUserRole.value != 'user'
                        ? Column(
                            children: [
                              CustomTile(
                                  icon: Icons.admin_panel_settings,
                                  title: "Moderation Panel",
                                  description: "Access moderation tools and reports",
                                  onTap: () {
                                    navigate(() => const SettingsModeration());
                                  }),
                              CustomTile(
                                  icon: Icons.report_outlined,
                                  title: "Reported Comments",
                                  description: "View and manage reported content",
                                  onTap: () {
                                    _navigateToReportsPanel();
                                  }),
                              const Divider(height: 1),
                            ],
                          )
                        : const SizedBox.shrink()),
                    CustomTile(
                        icon: Icons.code_outlined,
                        title: "Markdown Guide",
                        description: "Learn how to format your comments",
                        onTap: () {
                          _showMarkdownGuide();
                        }),
                    const Divider(height: 1),
                    CustomTile(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        description: "Get help with the comment system",
                        onTap: () {
                          _showHelpDialog();
                        }),
                    CustomTile(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy & Safety",
                        description: "Privacy settings and safety features",
                        onTap: () {
                          _showPrivacyDialog();
                        }),
                  ],
                ),
              ),
              30.height(),
            ],
          ),
        )
      ],
    ));
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

  void _navigateToReportsPanel() {
    if (commentumService.currentUserRole.value == 'user') {
      snackBar('You need moderator or admin permissions to access this panel');
      return;
    }

    navigate(() => const ReportsQueuePage());
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
              Text('You can use Discord-style markdown to format your comments:',
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
              Text('Tip: You can combine these! e.g. **bold and *italic* together**',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
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
