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

class SettingsModeration extends StatefulWidget {
  const SettingsModeration({super.key});

  @override
  State<SettingsModeration> createState() => _SettingsModerationState();
}

class _SettingsModerationState extends State<SettingsModeration> {
  final commentumService = Get.find<CommentumService>();
  final RxList<Map<String, dynamic>> moderationQueue = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingQueue = false.obs;

  @override
  void initState() {
    super.initState();
    _loadModerationQueue();
  }

  Future<void> _loadModerationQueue() async {
    if (!await commentumService.isModerator()) {
      return;
    }

    isLoadingQueue.value = true;
    try {
      final queue = await commentumService.getModerationQueue();
      moderationQueue.assignAll(queue);
    } catch (e) {
      print('Error loading moderation queue: $e');
    } finally {
      isLoadingQueue.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SuperListView(
        padding: getResponsiveValue(context,
            mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
            desktopValue: const EdgeInsets.fromLTRB(20.0, 50.0, 25.0, 20.0)),
        children: [
          const Row(
            children: [
              CustomBackButton(),
              SizedBox(width: 10),
              Text("Moderation Panel",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 30),
          
          // User Role Display
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .opaque(0.3)),
            child: Column(
              children: [
                Obx(() => CustomTile(
                  icon: Icons.admin_panel_settings,
                  title: "Your Role",
                  description: commentumService.currentUserRole.value.toUpperCase(),
                  postFix: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRoleColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      commentumService.currentUserRole.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Moderation Actions
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
                    icon: Icons.report_outlined,
                    title: "Moderation Queue",
                    description: "${moderationQueue.length} pending reports",
                    postFix: isLoadingQueue.value 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: () {
                      _navigateToModerationQueue();
                    }),
                CustomTile(
                    icon: Icons.people_outline,
                    title: "User Management",
                    description: "Manage user roles and permissions",
                    onTap: () {
                      _navigateToUserManagement();
                    }),
                CustomTile(
                    icon: Icons.history_outlined,
                    title: "Moderation History",
                    description: "View past moderation actions",
                    onTap: () {
                      _showModerationHistory();
                    }),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick Actions
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
                    icon: Icons.search_outlined,
                    title: "Search User",
                    description: "Find and manage specific users",
                    onTap: () {
                      _showUserSearch();
                    }),
                CustomTile(
                    icon: Icons.content_paste_search_outlined,
                    title: "Search Comments",
                    description: "Search through comment content",
                    onTap: () {
                      _showCommentSearch();
                    }),
                CustomTile(
                    icon: Icons.analytics_outlined,
                    title: "Statistics",
                    description: "View moderation statistics",
                    onTap: () {
                      _showStatistics();
                    }),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Settings
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
                    icon: Icons.notifications_outlined,
                    title: "Notification Settings",
                    description: "Configure moderation notifications",
                    onTap: () {
                      _showNotificationSettings();
                    }),
                CustomTile(
                    icon: Icons.rule_outlined,
                    title: "Moderation Rules",
                    description: "View and configure moderation rules",
                    onTap: () {
                      _showModerationRules();
                    }),
              ],
            ),
          ),
          
          30.height(),
        ],
      ),
    );
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

  Future<void> _navigateToModerationQueue() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    // Navigate to moderation queue (to be implemented)
    snackBar('Moderation queue interface coming soon!');
  }

  Future<void> _navigateToUserManagement() async {
    if (!await commentumService.isAdmin()) {
      snackBar('You need admin permissions to access this panel');
      return;
    }
    
    // Navigate to user management (to be implemented)
    snackBar('User management interface coming soon!');
  }

  Future<void> _showModerationHistory() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Moderation history will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Filter by action type'),
            BulletPoint(text: 'Filter by date range'),
            BulletPoint(text: 'Filter by moderator'),
            BulletPoint(text: 'Export moderation logs'),
            BulletPoint(text: 'Appeal system'),
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

  Future<void> _showUserSearch() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User search functionality will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Search by username'),
            BulletPoint(text: 'Search by user ID'),
            BulletPoint(text: 'Search by comment history'),
            BulletPoint(text: 'Advanced filtering options'),
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

  Future<void> _showCommentSearch() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Comments'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comment search functionality will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Search by content'),
            BulletPoint(text: 'Search by username'),
            BulletPoint(text: 'Search by date range'),
            BulletPoint(text: 'Search by report status'),
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

  Future<void> _showStatistics() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Statistics'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Moderation statistics will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Reports resolved'),
            BulletPoint(text: 'Users warned/banned'),
            BulletPoint(text: 'Comments moderated'),
            BulletPoint(text: 'Response times'),
            BulletPoint(text: 'Trends and analytics'),
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

  Future<void> _showNotificationSettings() async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notification settings will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned notifications:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'New reports'),
            BulletPoint(text: 'Report resolutions'),
            BulletPoint(text: 'User appeals'),
            BulletPoint(text: 'System alerts'),
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

  Future<void> _showModerationRules() async {
    if (!await commentumService.isAdmin()) {
      snackBar('You need admin permissions to access this panel');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Rules'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Moderation rules configuration will be available in future updates.'),
            SizedBox(height: 8),
            Text('Planned features:', style: TextStyle(fontWeight: FontWeight.bold)),
            BulletPoint(text: 'Custom banned keywords'),
            BulletPoint(text: 'Auto-moderation thresholds'),
            BulletPoint(text: 'Role-specific permissions'),
            BulletPoint(text: 'Content filtering rules'),
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