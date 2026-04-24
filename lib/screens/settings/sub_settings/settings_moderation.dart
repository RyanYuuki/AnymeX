import 'dart:async';
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
                CustomTile(
                  icon: Icons.people_outlined,
                  title: "User List",
                  description: "View and filter all users",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListPage())),
                ),
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
      case 'owner':
        return Colors.purple;
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
        return _UserSearchSheet(
          searchController: searchController,
          commentumService: commentumService,
        );
      },
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  final TextEditingController searchController;
  final CommentumService commentumService;

  const _UserSearchSheet({
    required this.searchController,
    required this.commentumService,
  });

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  int _searchMode = 0; // 0 = by ID, 1 = by username
  String _selectedClientType = 'anilist';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  final _clientTypes = [
    ('anilist', 'AniList'),
    ('mal', 'MAL'),
    ('simkl', 'Simkl'),
  ];

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchMode != 1) return;
    final query = widget.searchController.text.trim();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
      }
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.searchController.removeListener(_onSearchChanged);
    widget.searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = widget.searchController.text.trim();
    if (query.isEmpty) {
      snackBar('Please enter a search term');
      return;
    }

    if (_searchMode == 0) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserManagementPage(
            targetUserId: query,
            targetClientType: _selectedClientType,
          ),
        ),
      );
    } else {
      if (query.length < 2) {
        snackBar('Enter at least 2 characters');
        return;
      }

      setState(() => _isSearching = true);
      try {
        final result = await widget.commentumService.searchUsers(
          username: query,
          targetClientType: _selectedClientType,
        );

        if (result != null) {
          final users = List<Map<String, dynamic>>.from(result['users'] ?? []);
          setState(() {
            _searchResults = users;
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } catch (e) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Search mode toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('By ID'),
                  selected: _searchMode == 0,
                  onSelected: (_) {
                    widget.searchController.clear();
                    setState(() { _searchMode = 0; _searchResults = []; });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('By Username'),
                  selected: _searchMode == 1,
                  onSelected: (_) {
                    widget.searchController.clear();
                    setState(() { _searchMode = 1; _searchResults = []; });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client type selector
          Row(
            children: [
              Text(
                'Platform:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              ..._clientTypes.map((ct) {
                final isSelected = _selectedClientType == ct.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(ct.$2),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedClientType = ct.$1),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Search field
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              labelText: _searchMode == 0 ? 'Enter User ID' : 'Enter Username',
              hintText: _searchMode == 0
                  ? 'Enter the user ID'
                  : 'Type a username to search',
              prefixIcon: _isSearching && _searchMode == 1
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_searchMode == 0
                      ? Icons.badge_outlined
                      : Icons.person_search_rounded),
              suffixIcon: _searchMode == 1 && widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        widget.searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
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
            onSubmitted: (_) => _performSearch(),
          ),

          // For ID search mode, show the View User button
          if (_searchMode == 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSearching ? null : _performSearch,
                child: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('View User'),
              ),
            ),
          ],

          // For username search, show hint text
          if (_searchMode == 1 && _searchResults.isEmpty && !_isSearching && widget.searchController.text.trim().length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Type at least 2 characters to search',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // No results found
          if (_searchMode == 1 && _searchResults.isEmpty && !_isSearching && widget.searchController.text.trim().length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'No users found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Username search results
          if (_searchMode == 1 && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              '${_searchResults.length} result(s)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final userId = user['id']?.toString() ?? '';
                  final username = user['username']?.toString() ?? 'Unknown';
                  final avatar = user['avatar']?.toString();
                  final role = user['role']?.toString() ?? 'user';
                  final isBanned = user['banned'] == true;
                  final clientType = user['client_type']?.toString() ?? '';

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainer,
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? Icon(Icons.person_rounded,
                              size: 18, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role != 'user') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(role),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isBanned) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.block_rounded,
                              size: 14, color: colorScheme.error),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'ID: $userId${clientType.isNotEmpty ? ' · $clientType' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserManagementPage(
                            targetUserId: userId,
                            targetClientType: clientType,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
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
              final reporterUsername = r['reporter_username']?.toString() ?? '';
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (reporterUsername.isNotEmpty || reporterId.isNotEmpty)
                            Text(
                              'by ${reporterUsername.isNotEmpty ? reporterUsername : reporterId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                        ],
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

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final commentumService = Get.find<CommentumService>();
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt totalPages = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalUsers = 0.obs;

  // Filters
  final RxInt selectedStatusFilter = 0.obs; // 0=All, 1=Banned, 2=Muted, 3=Shadow Banned, 4=Warned
  final RxString selectedRoleFilter = ''.obs; // ''=All
  final RxString selectedClientTypeFilter = ''.obs; // ''=All

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        currentPage.value < totalPages.value) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers() async {
    isLoading.value = true;
    currentPage.value = 1;
    users.clear();
    try {
      final result = await commentumService.listUsers(
        targetClientType: selectedClientTypeFilter.value.isEmpty ? null : selectedClientTypeFilter.value,
        role: selectedRoleFilter.value.isEmpty ? null : selectedRoleFilter.value,
        banned: selectedStatusFilter.value == 1 ? true : null,
        muted: selectedStatusFilter.value == 2 ? true : null,
        shadowBanned: selectedStatusFilter.value == 3 ? true : null,
        page: 1,
        limit: 50,
      );
      if (result != null) {
        final usersList = result['users'] as List<dynamic>? ?? [];
        users.assignAll(usersList.cast<Map<String, dynamic>>());
        totalUsers.value = result['total'] as int? ?? 0;
        currentPage.value = result['page'] as int? ?? 1;
        final limit = result['limit'] as int? ?? 50;
        totalPages.value = (totalUsers.value / limit).ceil();

        if (selectedStatusFilter.value == 4) {
          users.assignAll(users.where((u) =>
              (u['warnings'] is int && u['warnings'] > 0) ||
              (u['warnings'] is String && int.tryParse(u['warnings'].toString()) != null && int.parse(u['warnings'].toString()) > 0)
          ).toList());
        }
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMoreUsers() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;
    try {
      final result = await commentumService.listUsers(
        targetClientType: selectedClientTypeFilter.value.isEmpty ? null : selectedClientTypeFilter.value,
        role: selectedRoleFilter.value.isEmpty ? null : selectedRoleFilter.value,
        banned: selectedStatusFilter.value == 1 ? true : null,
        muted: selectedStatusFilter.value == 2 ? true : null,
        shadowBanned: selectedStatusFilter.value == 3 ? true : null,
        page: nextPage,
        limit: 50,
      );
      if (result != null) {
        final usersList = result['users'] as List<dynamic>? ?? [];
        final newUsers = usersList.cast<Map<String, dynamic>>();

        if (selectedStatusFilter.value == 4) {
          newUsers.removeWhere((u) =>
              !((u['warnings'] is int && u['warnings'] > 0) ||
                  (u['warnings'] is String && int.tryParse(u['warnings'].toString()) != null && int.parse(u['warnings'].toString()) > 0))
          );
        }

        users.addAll(newUsers);
        totalUsers.value = result['total'] as int? ?? 0;
        currentPage.value = result['page'] as int? ?? nextPage;
        final limit = result['limit'] as int? ?? 50;
        totalPages.value = (totalUsers.value / limit).ceil();
      }
    } catch (e) {
      print('Error loading more users: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _onFilterChanged() {
    _loadUsers();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          _buildStatusFilters(colorScheme, theme),
          // Role & Client type dropdowns
          _buildDropdownFilters(colorScheme, theme),
          // User count
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${users.length} of $totalUsers users',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )),
          // User list
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: ExpressiveLoadingIndicator());
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: users.length + (isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == users.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return _buildUserCard(context, users[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(ColorScheme colorScheme, ThemeData theme) {
    final statusFilters = ['All', 'Banned', 'Muted', 'Shadow Banned', 'Warned'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Obx(() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(statusFilters.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(statusFilters[index]),
                selected: selectedStatusFilter.value == index,
                onSelected: (selected) {
                  if (selected) {
                    selectedStatusFilter.value = index;
                    _onFilterChanged();
                  }
                },
              ),
            );
          }),
        ),
      )),
    );
  }

  Widget _buildDropdownFilters(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildFilterDropdown(
              value: selectedRoleFilter.value.isEmpty ? null : selectedRoleFilter.value,
              hint: 'Role: All',
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                const DropdownMenuItem(value: 'user', child: Text('User')),
                const DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
                const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                const DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
              ],
              onChanged: (value) {
                selectedRoleFilter.value = value ?? '';
                _onFilterChanged();
              },
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => _buildFilterDropdown(
              value: selectedClientTypeFilter.value.isEmpty ? null : selectedClientTypeFilter.value,
              hint: 'Client: All',
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                const DropdownMenuItem(value: 'anilist', child: Text('AniList')),
                const DropdownMenuItem(value: 'mal', child: Text('MAL')),
                const DropdownMenuItem(value: 'simkl', child: Text('Simkl')),
              ],
              onChanged: (value) {
                selectedClientTypeFilter.value = value ?? '';
                _onFilterChanged();
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = user['username']?.toString() ?? 'Unknown';
    final avatar = user['avatar']?.toString();
    final role = user['role']?.toString() ?? 'user';
    final isBanned = user['banned'] == true;
    final isMuted = user['muted'] == true;
    final isShadowBanned = user['shadow_banned'] == true;
    final warnings = user['warnings'];
    final warningCount = warnings is int ? warnings : (int.tryParse(warnings?.toString() ?? '0') ?? 0);
    final clientType = user['client_type']?.toString() ?? '';
    final userId = user['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserManagementPage(targetUserId: userId, targetClientType: clientType.isNotEmpty ? clientType : null),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.surfaceContainer,
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Icon(Icons.person_rounded, size: 22, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRoleColor(role).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status indicators
                        if (isBanned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.block_rounded,
                                size: 16, color: colorScheme.error),
                          ),
                        if (isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.volume_off_rounded,
                                size: 16, color: Colors.amber),
                          ),
                        if (isShadowBanned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.visibility_off_rounded,
                                size: 16, color: Colors.purple),
                          ),
                        if (warningCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.warning_rounded,
                                size: 16, color: Colors.orange),
                          ),
                        if (clientType.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              clientType.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  final String targetUserId;
  final String? targetClientType;

  const UserManagementPage({super.key, required this.targetUserId, this.targetClientType});

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
          targetUserId: widget.targetUserId,
          targetClientType: widget.targetClientType);
      if (data != null) {
        final users = data['users'] as List<dynamic>? ?? [];
        if (users.isNotEmpty) {
          final user = users.first as Map<String, dynamic>;
          final username = user['username']?.toString() ??
              user['commentum_username']?.toString() ?? 'Unknown';
          final avatar = user['avatar']?.toString() ??
              user['commentum_user_avatar']?.toString();
          final role = user['role']?.toString() ??
              user['commentum_user_role']?.toString() ?? 'user';
          final banned = user['banned']?.toString() ??
              user['commentum_user_banned']?.toString() ?? 'false';
          final muted = user['muted']?.toString() ??
              user['commentum_user_muted']?.toString() ?? 'false';
          final shadowBanned = user['shadow_banned']?.toString() ??
              user['commentum_user_shadow_banned']?.toString() ?? 'false';
          final warnings = user['warnings']?.toString() ??
              user['commentum_user_warnings']?.toString() ?? '0';
          final mutedUntil = user['muted_until']?.toString() ??
              user['commentum_user_muted_until']?.toString();
          final notes = user['notes']?.toString() ??
              user['commentum_user_notes']?.toString();
          final clientType = user['client_type']?.toString() ??
              user['commentum_client_type']?.toString() ?? '';
          final createdAt = user['created_at']?.toString() ?? '';
          setState(() {
            userInfo = {
              ...user,
              'username': username,
              'avatar': avatar,
              'role': role,
              'banned': banned,
              'muted': muted,
              'shadow_banned': shadowBanned,
              'warnings': warnings,
              'muted_until': mutedUntil,
              'notes': notes,
              'client_type': clientType,
              'created_at': createdAt,
            };
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: colorScheme.surfaceContainer,
                              backgroundImage: userInfo?['avatar'] != null &&
                                      userInfo!['avatar'].toString().isNotEmpty
                                  ? NetworkImage(userInfo!['avatar'].toString())
                                  : null,
                              child: userInfo?['avatar'] == null ||
                                      userInfo!['avatar'].toString().isEmpty
                                  ? Icon(Icons.person_rounded,
                                      size: 32,
                                      color: colorScheme.onSurfaceVariant)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userInfo?['username']?.toString() ?? 'Unknown',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                    userInfo?['role']?.toString() ?? 'user')
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRoleColor(
                                      userInfo?['role']?.toString() ?? 'user')
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                (userInfo?['role']?.toString() ?? 'user')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _getRoleColor(
                                      userInfo?['role']?.toString() ?? 'user'),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(context, 'User ID',
                                      widget.targetUserId),
                                  if (userInfo?['client_type'] != null &&
                                      userInfo!['client_type'].toString().isNotEmpty)
                                    _buildInfoRow(context, 'Client',
                                        userInfo!['client_type'].toString().toUpperCase()),
                                  _buildInfoRow(context, 'Banned',
                                      userInfo?['banned']?.toString() == 'true'
                                          ? 'Yes' : 'No'),
                                  _buildInfoRow(context, 'Shadow Banned',
                                      userInfo?['shadow_banned']?.toString() == 'true'
                                          ? 'Yes' : 'No'),
                                  _buildInfoRow(context, 'Muted',
                                      userInfo?['muted']?.toString() == 'true'
                                          ? 'Yes' : 'No'),
                                  _buildInfoRow(context, 'Warnings',
                                      userInfo?['warnings']?.toString() ?? '0'),
                                  if (userInfo?['muted_until'] != null &&
                                      userInfo!['muted_until'].toString().isNotEmpty &&
                                      userInfo!['muted_until'].toString() != 'null')
                                    _buildInfoRow(context, 'Muted Until',
                                        userInfo?['muted_until'].toString() ?? 'N/A'),
                                  if (userInfo?['created_at'] != null &&
                                      userInfo!['created_at'].toString().isNotEmpty &&
                                      userInfo!['created_at'].toString() != 'null')
                                    _buildInfoRow(context, 'Joined',
                                        userInfo?['created_at'].toString() ?? 'N/A'),
                                  if (userInfo?['notes'] != null &&
                                      userInfo!['notes'].toString().isNotEmpty &&
                                      userInfo!['notes'].toString() != 'null')
                                    _buildInfoRow(
                                      context,
                                      'Notes',
                                      userInfo?['notes']?.toString() ?? '',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
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
      targetClientType: widget.targetClientType,
    );

    if (success) {
      snackBar('User ${label.toLowerCase()}d successfully');
      _loadUserInfo();
    } else {
      snackBar('Failed to $label user');
    }
  }
}
