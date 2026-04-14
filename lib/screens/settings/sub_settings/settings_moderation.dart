import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:timeago/timeago.dart' as timeago;

class SettingsModeration extends StatefulWidget {
  const SettingsModeration({super.key});

  @override
  State<SettingsModeration> createState() => _SettingsModerationState();
}

class _SettingsModerationState extends State<SettingsModeration> {
  final commentumService = Get.find<CommentumService>();
  final RxList<Map<String, dynamic>> reportsQueue =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingQueue = false.obs;

  @override
  void initState() {
    super.initState();
    _loadReportsQueue();
  }

  Future<void> _loadReportsQueue() async {
    if (!await commentumService.isModerator()) {
      return;
    }

    isLoadingQueue.value = true;
    try {
      final queue = await commentumService.getReportsQueue();
      reportsQueue.assignAll(queue);
    } catch (e) {
      print('Error loading reports queue: $e');
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
                color:
                    Theme.of(context).colorScheme.surfaceContainer.opaque(0.3)),
            child: Column(
              children: [
                Obx(() => CustomTile(
                      icon: Icons.admin_panel_settings,
                      title: "Your Role",
                      description:
                          commentumService.currentUserRole.value.toUpperCase(),
                      postFix: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                color:
                    Theme.of(context).colorScheme.surfaceContainer.opaque(0.3)),
            child: Column(
              children: [
                Obx(() => CustomTile(
                      icon: Icons.report_outlined,
                      title: "Reports Queue",
                      description:
                          "${reportsQueue.length} pending reports",
                      postFix: isLoadingQueue.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: () => _navigateToReportsQueue(context),
                    )),
                CustomTile(
                    icon: Icons.search_outlined,
                    title: "Search User",
                    description: "Find and manage specific users",
                    onTap: () => _showUserSearch(context)),
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
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _navigateToReportsQueue(BuildContext context) async {
    if (!await commentumService.isModerator()) {
      snackBar('You need moderator permissions to access this panel');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsQueuePage(),
      ),
    );
  }

  void _showUserSearch(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Search User',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Enter User ID',
                  hintText: 'Enter the AniList user ID',
                  prefixIcon: const Icon(Icons.person_search_rounded),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final userId = searchController.text.trim();
                    if (userId.isEmpty) {
                      snackBar('Please enter a user ID');
                      return;
                    }
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserManagementPage(
                            targetUserId: userId),
                      ),
                    );
                  },
                  child: const Text('View User'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportsQueuePage extends StatefulWidget {
  const ReportsQueuePage({super.key});

  @override
  State<ReportsQueuePage> createState() => _ReportsQueuePageState();
}

class _ReportsQueuePageState extends State<ReportsQueuePage> {
  final commentumService = Get.find<CommentumService>();
  final RxList<Map<String, dynamic>> reports = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> resolvingReports = <int>{}.obs;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    isLoading.value = true;
    try {
      final queue = await commentumService.getReportsQueue();
      reports.assignAll(queue);
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Queue'),
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: ExpressiveLoadingIndicator());
        }

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'No pending reports',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All clear! No reports to review.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(context, report);
          },
        );
      }),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commentId = report['commentId'] as int? ?? 0;
    final content = report['content']?.toString() ?? '';
    final author = report['author'] as Map<String, dynamic>? ?? {};
    final authorName = author['username']?.toString() ?? 'Unknown';
    final authorAvatar = author['avatar']?.toString();
    final mediaInfo = report['media'] as Map<String, dynamic>? ?? {};
    final mediaTitle = mediaInfo['title']?.toString() ?? 'Unknown';
    final mediaType = mediaInfo['type']?.toString() ?? '';
    final totalReports = report['totalReports'] as int? ?? 0;
    final pendingReports =
        report['reports'] as List<dynamic>? ?? [];
    final createdAt = report['createdAt']?.toString() ?? '';
    final isResolving = resolvingReports.contains(commentId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainer,
                child: authorAvatar != null && authorAvatar.isNotEmpty
                    ? ClipOval(
                        child: Image.network(authorAvatar,
                            width: 36, height: 36, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 18)),
                      )
                    : const Icon(Icons.person_rounded, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (mediaTitle.isNotEmpty)
                      Text(
                        '$mediaTitle ${mediaType.isNotEmpty ? "($mediaType)" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 14, color: colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      '$totalReports',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pendingReports.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pendingReports.map((r) {
              final reason = r['reason']?.toString() ?? '';
              final notes = r['notes']?.toString() ?? '';
              final reporterId = r['reporter_id']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.report_rounded,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (notes.isNotEmpty)
                      Text(
                        '($notes)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            }),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              timeago.format(DateTime.parse(createdAt)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isResolving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                OutlinedButton(
                  onPressed: () => _resolveReport(
                    commentId: commentId,
                    reporterId: pendingReports.isNotEmpty
                        ? (pendingReports.first['reporter_id']?.toString() ??
                            '')
                        : '',
                    resolution: 'dismissed',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _resolveReport(
                    commentId: commentId,
                    reporterId: pendingReports.isNotEmpty
                        ? (pendingReports.first['reporter_id']?.toString() ??
                            '')
                        : '',
                    resolution: 'resolved',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Resolve'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveReport({
    required int commentId,
    required String reporterId,
    required String resolution,
  }) async {
    if (reporterId.isEmpty) {
      snackBar('No reporter ID found for this report');
      return;
    }

    resolvingReports.add(commentId);
    try {
      final success = await commentumService.resolveReport(
        commentId: commentId,
        reporterId: reporterId,
        resolution: resolution,
      );

      if (success) {
        snackBar('Report $resolution successfully');
        await _loadReports();
      } else {
        snackBar('Failed to resolve report');
      }
    } finally {
      resolvingReports.remove(commentId);
    }
  }
}

class UserManagementPage extends StatefulWidget {
  final String targetUserId;

  const UserManagementPage({super.key, required this.targetUserId});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final commentumService = Get.find<CommentumService>();
  Map<String, dynamic>? userInfo;
  bool isLoading = true;
  final TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final data = await commentumService.getUserInfo(
          targetUserId: widget.targetUserId);
      if (data != null) {
        final users = data['users'] as List<dynamic>? ?? [];
        if (users.isNotEmpty) {
          setState(() {
            userInfo = users.first;
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: isLoading
          ? const Center(child: ExpressiveLoadingIndicator())
          : userInfo == null
              ? Center(
                  child: Text(
                    'User not found (ID: ${widget.targetUserId})',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User: ${widget.targetUserId}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(context, 'Role',
                                userInfo?['commentum_user_role']?.toString() ??
                                    'user'),
                            _buildInfoRow(context, 'Banned',
                                userInfo?['commentum_user_banned']?.toString() ??
                                    'false'),
                            _buildInfoRow(context, 'Shadow Banned',
                                userInfo?['commentum_user_shadow_banned']
                                        ?.toString() ??
                                    'false'),
                            _buildInfoRow(context, 'Muted',
                                userInfo?['commentum_user_muted']?.toString() ??
                                    'false'),
                            _buildInfoRow(context, 'Warnings',
                                userInfo?['commentum_user_warnings']
                                        ?.toString() ??
                                    '0'),
                            if (userInfo?['commentum_user_muted_until'] !=
                                null)
                              _buildInfoRow(
                                  context,
                                  'Muted Until',
                                  userInfo?['commentum_user_muted_until']
                                      ?.toString() ?? 'N/A',
                                ),
                            if (userInfo?['commentum_user_notes'] != null &&
                                userInfo!['commentum_user_notes']
                                    .toString()
                                    .isNotEmpty)
                              _buildInfoRow(
                                context,
                                'Notes',
                                userInfo?['commentum_user_notes']?.toString() ?? '',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reason Input
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          hintText: 'Provide reason for action...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Text(
                        'Actions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context: context,
                        icon: Icons.warning_rounded,
                        label: 'Warn User',
                        color: Colors.orange,
                        onTap: () => _performAction(
                          action: 'warn_user',
                          label: 'Warn',
                        ),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.volume_off_rounded,
                        label: 'Mute User (24h)',
                        color: Colors.amber,
                        onTap: () => _performAction(
                          action: 'mute_user',
                          label: 'Mute',
                          duration: 24,
                        ),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.block_rounded,
                        label: 'Ban User',
                        color: colorScheme.error,
                        onTap: () => _performAction(
                          action: 'ban_user',
                          label: 'Ban',
                        ),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.visibility_off_rounded,
                        label: 'Shadow Ban User',
                        color: Colors.purple,
                        onTap: () => _performAction(
                          action: 'ban_user',
                          label: 'Shadow Ban',
                          shadowBan: true,
                        ),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.check_circle_rounded,
                        label: 'Unban User',
                        color: Colors.green,
                        onTap: () => _performAction(
                          action: 'unban_user',
                          label: 'Unban',
                        ),
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.volume_up_rounded,
                        label: 'Unmute User',
                        color: Colors.teal,
                        onTap: () => _performAction(
                          action: 'unmute_user',
                          label: 'Unmute',
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction({
    required String action,
    required String label,
    int? duration,
    bool shadowBan = false,
  }) async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      snackBar('Please provide a reason');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm $label'),
        content: Text(
            'Are you sure you want to $label user ${widget.targetUserId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: label.contains('Ban')
                  ? context.colors.error
                  : null,
            ),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await commentumService.manageUser(
      action: action,
      targetUserId: widget.targetUserId,
      reason: reason,
      duration: duration,
      shadowBan: shadowBan,
    );

    if (success) {
      snackBar('User ${label.toLowerCase()}d successfully');
      _loadUserInfo();
    } else {
      snackBar('Failed to $label user');
    }
  }
}
