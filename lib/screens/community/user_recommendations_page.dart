import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserRecommendationsPage extends StatefulWidget {
  final ReasonUserProfile user;

  const UserRecommendationsPage({
    super.key,
    required this.user,
  });

  @override
  State<UserRecommendationsPage> createState() =>
      _UserRecommendationsPageState();
}

class _UserRecommendationsPageState extends State<UserRecommendationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refreshData();
  }

  Future<void> _refreshData() async {
    final svc = Get.find<CommunityService>();
    await svc.refresh();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_UserRecItem> _getRecommendations() {
    final svc = Get.find<CommunityService>();
    final user = widget.user;
    final items = <_UserRecItem>[];

    for (final item in svc.communityAnimes) {
      final reason = item.recommendationFrom(user);
      if (reason != null) {
        items.add(_UserRecItem(
          media: item.media,
          reason: reason,
          category: 'anime',
        ));
      }
    }

    for (final item in svc.communityMangas) {
      final reason = item.recommendationFrom(user);
      if (reason != null) {
        items.add(_UserRecItem(
          media: item.media,
          reason: reason,
          category: 'manga',
        ));
      }
    }

    for (final item in svc.communityShows) {
      final reason = item.recommendationFrom(user);
      if (reason != null) {
        items.add(_UserRecItem(
          media: item.media,
          reason: reason,
          category: 'shows',
        ));
      }
    }

    for (final item in svc.communityMovies) {
      final reason = item.recommendationFrom(user);
      if (reason != null) {
        items.add(_UserRecItem(
          media: item.media,
          reason: reason,
          category: 'movies',
        ));
      }
    }

    return items;
  }

  List<_UserRecItem> _filterByCategory(String category, List<_UserRecItem> all) {
    if (category == 'all') return all;
    return all.where((i) => i.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user.displayName ?? 'Unknown User';
    final avatarUrl = widget.user.displayAvatar;
    final isAdmin = widget.user.isAdmin;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: _Avatar(
                  avatarUrl: avatarUrl,
                  fallbackLabel: username,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnymexText(
                  text: username,
                  variant: TextVariant.semiBold,
                  color: context.colors.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified_rounded,
                    size: 16, color: context.colors.primary),
              ],
              const SizedBox(width: 4),
              AnymexText(
                text: "'s Recs",
                variant: TextVariant.semiBold,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allItems = _getRecommendations();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: _Avatar(
                avatarUrl: avatarUrl,
                fallbackLabel: username,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AnymexText(
                text: username,
                variant: TextVariant.semiBold,
                color: context.colors.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified_rounded,
                  size: 16, color: context.colors.primary),
            ],
            const SizedBox(width: 4),
            AnymexText(
              text: "'s Recs",
              variant: TextVariant.semiBold,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.only(left: 12, right: 12),
          tabs: [
            Tab(text: 'All (${allItems.length})'),
            Tab(
                text:
                    'Anime (${allItems.where((i) => i.category == 'anime').length})'),
            Tab(
                text:
                    'Manga (${allItems.where((i) => i.category == 'manga').length})'),
            Tab(
                text:
                    'Shows (${allItems.where((i) => i.category == 'shows').length})'),
            Tab(
                text:
                    'Movies (${allItems.where((i) => i.category == 'movies').length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(context, _filterByCategory('all', allItems)),
          _buildGrid(context, _filterByCategory('anime', allItems)),
          _buildGrid(context, _filterByCategory('manga', allItems)),
          _buildGrid(context, _filterByCategory('shows', allItems)),
          _buildGrid(context, _filterByCategory('movies', allItems)),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_UserRecItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_remove_rounded,
                size: 48,
                color: context.colors.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            AnymexText(
              text: 'No recommendations found',
              color: context.colors.onSurfaceVariant.withOpacity(0.7),
              variant: TextVariant.semiBold,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 200,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _RecCard(item: items[index]);
      },
    );
  }
}

class _RecCard extends StatelessWidget {
  final _UserRecItem item;

  const _RecCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isManga = item.category == 'manga';

    return GestureDetector(
      onTap: () {
        final tag = 'user-rec-${item.media.id}';
        if (isManga) {
          navigate(() => MangaDetailsPage(media: item.media, tag: tag));
        } else {
          navigate(() => AnimeDetailsPage(media: item.media, tag: tag));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnymeXImage(
                    imageUrl: item.media.poster,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                      child: AnymexText(
                        text: item.media.rating.toString(),
                        size: 10,
                        color: Colors.white,
                        variant: TextVariant.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnymexText(
            text: item.media.title,
            variant: TextVariant.semiBold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            size: 11,
          ),
          const SizedBox(height: 2),
          AnymexText(
            text: item.reason.displayText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            size: 10,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double size;

  const _Avatar({
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                (fallbackLabel?.trim().isNotEmpty == true
                        ? fallbackLabel!.trim()[0]
                        : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _UserRecItem {
  final Media media;
  final ReasonEntry reason;
  final String category;

  _UserRecItem({
    required this.media,
    required this.reason,
    required this.category,
  });
}
