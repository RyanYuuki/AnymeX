import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/screens/settings/settings.dart';
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
              const Row(
                children: [
                  CustomBackButton(),
                  SizedBox(width: 10),
                  Text("Comment System",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
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
                    CustomTile(
                        icon: Icons.person_outline,
                        title: "User Role",
                        description: _getCurrentRoleDescription(),
                        postFix: Obx(() => Text(
                              commentumService.currentUserRole.value
                                  .toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        onTap: () {
                          _showRoleInfo();
                        }),
                    const Divider(height: 1),
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
                    CustomTile(
                        icon: Icons.settings_outlined,
                        title: "Comment Preferences",
                        description: "Customize comment display and behavior",
                        onTap: () {
                          _showCommentPreferences();
                        }),
                    CustomTile(
                        icon: Icons.notifications_outlined,
                        title: "Notification Settings",
                        description: "Configure comment notifications",
                        onTap: () {
                          _showNotificationSettings();
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

  String _getCurrentRoleDescription() {
    final role = commentumService.currentUserRole.value;
    switch (role) {
      case 'super_admin':
        return 'Full system access and control';
      case 'admin':
        return 'Can moderate and manage users';
      case 'moderator':
        return 'Can moderate content';
      default:
        return 'Basic commenting privileges';
    }
  }

  Color _getRoleColor() {
    final role = commentumService.currentUserRole.value;
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
            SizedBox(height: 8),
            Text('Base URL: https://whzwmfxngelicmjyxwmr.supabase.co'),
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

  void _showRoleInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Roles & Permissions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your current role and permissions:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            RoleDescription(
              role: 'User',
              permissions: [
                'Create comments',
                'Edit own comments',
                'Delete own comments',
                'Vote on comments',
                'Report inappropriate content',
              ],
            ),
            SizedBox(height: 8),
            RoleDescription(
              role: 'Moderator',
              permissions: [
                'All User permissions',
                'Edit/delete any comment',
                'Pin/unpin comments',
                'Lock/unlock threads',
                'Warn users',
                'Mute users temporarily',
                'Resolve reports',
              ],
            ),
            SizedBox(height: 8),
            RoleDescription(
              role: 'Admin',
              permissions: [
                'All Moderator permissions',
                'Ban/unban users permanently',
                'Shadow ban users',
                'Full user management',
              ],
            ),
            SizedBox(height: 8),
            RoleDescription(
              role: 'Super Admin',
              permissions: [
                'All Admin permissions',
                'System configuration',
                'Role management',
                'Discord bot management',
              ],
            ),
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

  void _navigateToModerationPanel() {
    // Check if user has moderation permissions
    if (commentumService.currentUserRole.value == 'user') {
      snackBar('You need moderator or admin permissions to access this panel');
      return;
    }

    // Navigate to moderation panel (to be implemented)
    snackBar('Moderation panel coming soon!');
  }

  void _navigateToReportsPanel() {
    // Check if user has moderation permissions
    if (commentumService.currentUserRole.value == 'user') {
      snackBar('You need moderator or admin permissions to access this panel');
      return;
    }

    // Navigate to reports panel (to be implemented)
    snackBar('Reports panel coming soon!');
  }

  void _showCommentPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Comment display preferences will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Default sorting order'),
            BulletPoint(text: 'Comment density settings'),
            BulletPoint(text: 'Show/hide avatars'),
            BulletPoint(text: 'Font size adjustment'),
            BulletPoint(text: 'Auto-play videos in comments'),
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

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Comment notification preferences will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Replies to your comments'),
            BulletPoint(text: 'Mentions in comments'),
            BulletPoint(text: 'Moderation notifications'),
            BulletPoint(text: 'Report resolution updates'),
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

class RoleDescription extends StatelessWidget {
  final String role;
  final List<String> permissions;

  const RoleDescription(
      {super.key, required this.role, required this.permissions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...permissions.map((permission) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                        child: Text(permission,
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
