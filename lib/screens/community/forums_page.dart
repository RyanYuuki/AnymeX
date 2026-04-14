import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_thread.dart';
import 'package:anymex/screens/community/thread_detail_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/thread_composer_sheet.dart';

enum ThreadSortOption {
  latestUpdated('Latest Updated', 'UPDATED_AT_DESC'),
  newest('Newest', 'CREATED_AT_DESC'),
  mostCommented('Most Commented', 'REPLY_COUNT_DESC'),
  mostViewed('Most Viewed', 'VIEW_COUNT_DESC');

  final String label;
  final String value;
  const ThreadSortOption(this.label, this.value);
}

class ForumsPage extends StatefulWidget {
  const ForumsPage({super.key});

  @override
  State<ForumsPage> createState() => _ForumsPageState();
}

class _ForumsPageState extends State<ForumsPage> {
  final List<AnilistThread> _threads = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String? _searchQuery;
  ThreadSortOption _sortOption = ThreadSortOption.latestUpdated;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _fetchThreads();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasNextPage &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _fetchThreads({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _threads.clear();
        _hasNextPage = true;
      });
    }

    final anilistAuth = Get.find<AnilistAuth>();
    final results = await anilistAuth.fetchThreads(
      page: _currentPage,
      perPage: 25,
      search: _searchQuery,
      sort: _sortOption.value,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (reset) {
          _threads.clear();
        }
        _threads.addAll(results);
        _hasNextPage = results.length >= 25;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchThreads(reset: false);
  }

  Future<void> _onRefresh() async {
    await _fetchThreads(reset: true);
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = null;
        _searchController.clear();
        _fetchThreads();
      }
    });
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;
    _searchQuery = trimmed.isEmpty ? null : trimmed;
    _fetchThreads();
  }

  void _onSortChanged(ThreadSortOption option) {
    if (option == _sortOption) return;
    setState(() {
      _sortOption = option;
    });
    _fetchThreads();
  }

  void _openNewThreadSheet() {
    ThreadComposerSheet.show(
      context,
      onSubmit: (title, body) async {
        final anilistAuth = Get.find<AnilistAuth>();
        final result = await anilistAuth.saveThread(title: title, body: body);
        if (result != null) {
          _fetchThreads();
          return true;
        }
        return false;
      },
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: 'Forums',
              action: Row(
                children: [
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(
                      _showSearchBar ? Icons.close : Icons.search,
                    ),
                  ),
                ],
              ),
            ),

            if (_showSearchBar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search threads...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.theme.colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ThreadSortOption.values.map((option) {
                    final isSelected = option == _sortOption;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: AnymexText(
                          text: option.label,
                          size: 12,
                          variant: TextVariant.semiBold,
                          color: isSelected
                              ? context.theme.colorScheme.onPrimaryContainer
                              : context.theme.colorScheme.onSurfaceVariant,
                        ),
                        selected: isSelected,
                        onSelected: (_) => _onSortChanged(option),
                        backgroundColor: context.theme.colorScheme.surfaceContainer,
                        selectedColor: context.theme.colorScheme.primaryContainer,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _threads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined,
                                  size: 48,
                                  color: context.theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5)),
                              const SizedBox(height: 12),
                              AnymexText(
                                text: 'No threads found',
                                color: context.theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                                variant: TextVariant.semiBold,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount:
                                _threads.length + (_hasNextPage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _threads.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            context.theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _ThreadCard(
                                thread: _threads[index],
                                bodyPreview: _stripHtml(_threads[index].body),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openNewThreadSheet,
          backgroundColor: context.theme.colorScheme.primary,
          child: Icon(Icons.add, color: context.theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final AnilistThread thread;
  final String bodyPreview;

  const _ThreadCard({
    required this.thread,
    required this.bodyPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colorScheme;

    return InkWell(
      onTap: () {
        navigate(() => ThreadDetailPage(threadId: thread.id));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thread.isSticky || thread.isLocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (thread.isSticky)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin,
                                  size: 12, color: colors.onTertiaryContainer),
                              const SizedBox(width: 4),
                              AnymexText(
                                text: 'Sticky',
                                size: 11,
                                variant: TextVariant.semiBold,
                                color: colors.onTertiaryContainer,
                              ),
                            ],
                          ),
                        ),
                      if (thread.isSticky && thread.isLocked)
                        const SizedBox(width: 6),
                      if (thread.isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 12, color: colors.onErrorContainer),
                              const SizedBox(width: 4),
                              AnymexText(
                                text: 'Locked',
                                size: 11,
                                variant: TextVariant.semiBold,
                                color: colors.onErrorContainer,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              AnymexText(
                text: thread.title,
                variant: TextVariant.bold,
                size: 15,
                maxLines: 2,
              ),

              if (bodyPreview.isNotEmpty) ...[
                const SizedBox(height: 6),
                AnymexText(
                  text: bodyPreview.length > 120
                      ? '${bodyPreview.substring(0, 120)}...'
                      : bodyPreview,
                  size: 13,
                  color: colors.onSurfaceVariant,
                  maxLines: 2,
                ),
              ],

              if (thread.categories.isNotEmpty ||
                  thread.mediaCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...thread.categories.map((cat) => Chip(
                          label: AnymexText(
                            text: cat.name,
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: colors.onSecondaryContainer,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: colors.secondaryContainer,
                          side: BorderSide.none,
                        )),
                    ...thread.mediaCategories.map((mc) => Chip(
                          label: AnymexText(
                            text: mc.title ?? 'Media',
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: colors.onPrimaryContainer,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: colors.primaryContainer,
                          side: BorderSide.none,
                        )),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              Row(
                children: [
                  if (thread.user?.avatarUrl != null)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: thread.user!.avatarUrl!,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => CircleAvatar(
                          radius: 11,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.person,
                              size: 12, color: colors.onPrimaryContainer),
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(Icons.person,
                          size: 12, color: colors.onPrimaryContainer),
                    ),
                  const SizedBox(width: 8),
                  AnymexText(
                    text: thread.user?.name ?? 'User',
                    variant: TextVariant.semiBold,
                    size: 12,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  AnymexText(
                    text: thread.timeAgo,
                    size: 11,
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.chat_bubble_outline,
                    count: thread.replyCount,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.visibility_outlined,
                    count: thread.viewCount,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: thread.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    count: thread.likeCount,
                    color: thread.isLiked ? Colors.redAccent : colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        AnymexText(
          text: _formatCount(count),
          size: 12,
          color: color,
          variant: TextVariant.semiBold,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}
