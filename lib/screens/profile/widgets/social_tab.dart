import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/social_user.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialTab extends StatefulWidget {
  final int userId;

  final Function(int, int)? onCountsFetched;

  const SocialTab({
    super.key,
    required this.userId,
    this.onCountsFetched,
  });

  @override
  State<SocialTab> createState() => SocialTabState();
}

class SocialTabState extends State<SocialTab> {
  List<SocialUser> _following = [];
  List<SocialUser> _followers = [];
  bool _socialLoading = false;
  bool _socialLoadingMore = false;
  bool _socialFetched = false;
  int _socialSubTab = 0;
  bool _socialListMode = false;
  int _followingPage = 1;
  int _followersPage = 1;
  bool _followingHasMore = true;
  bool _followersHasMore = true;

  bool get _activeSocialHasMore =>
      _socialSubTab == 0 ? _followingHasMore : _followersHasMore;

  bool get shouldLoadMore =>
      !_socialLoading &&
      !_socialLoadingMore &&
      _socialFetched &&
      _activeSocialHasMore;

  Future<void> _fetchSocial({bool refresh = false}) async {
    if (_socialFetched && !refresh) return;
    setState(() => _socialLoading = true);
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      final followingResult =
          await anilistAuth.fetchFollowingPage(widget.userId, page: 1);
      final followersResult =
          await anilistAuth.fetchFollowersPage(widget.userId, page: 1);
      if (mounted) {
        final (followingUsers, followingHasMore, followingTotal) =
            followingResult;
        final (followerUsers, followersHasMore, followersTotal) =
            followersResult;
        setState(() {
          _following = followingUsers;
          _followers = followerUsers;
          _followingPage = 1;
          _followersPage = 1;
          _followingHasMore = followingHasMore;
          _followersHasMore = followersHasMore;
          _socialLoading = false;
          _socialFetched = true;
        });
        widget.onCountsFetched?.call(followingTotal, followersTotal);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _socialLoading = false;
          _socialFetched = true;
        });
      }
    }
  }

  Future<void> loadMore() async {
    if (_socialLoadingMore || !_socialFetched || !_activeSocialHasMore) return;

    setState(() => _socialLoadingMore = true);
    try {
      final anilistAuth = Get.find<AnilistAuth>();

      if (_socialSubTab == 0) {
        final nextPage = _followingPage + 1;
        final (users, hasMore, totalCount) =
            await anilistAuth.fetchFollowingPage(widget.userId, page: nextPage);
        if (!mounted) return;
        setState(() {
          final merged = <int, SocialUser>{
            for (final u in _following) u.id: u,
            for (final u in users) u.id: u,
          };
          _following = merged.values.toList();
          _followingPage = nextPage;
          _followingHasMore = hasMore;
          _socialLoadingMore = false;
        });
      } else {
        final nextPage = _followersPage + 1;
        final (users, hasMore, totalCount) =
            await anilistAuth.fetchFollowersPage(widget.userId, page: nextPage);
        if (!mounted) return;
        setState(() {
          final merged = <int, SocialUser>{
            for (final u in _followers) u.id: u,
            for (final u in users) u.id: u,
          };
          _followers = merged.values.toList();
          _followersPage = nextPage;
          _followersHasMore = hasMore;
          _socialLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _socialLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_socialFetched && !_socialLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSocial());
    }

    if (_socialLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final list = _socialSubTab == 0 ? _following : _followers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Sub-tab selector + layout toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: context.theme.colorScheme.surface,
                    selectedBackgroundColor:
                        context.theme.colorScheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text(
                        'Following (${_following.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _socialSubTab == 0
                              ? context.theme.colorScheme.onPrimaryContainer
                              : context.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text(
                        'Followers (${_followers.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _socialSubTab == 1
                              ? context.theme.colorScheme.onPrimaryContainer
                              : context.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  selected: {_socialSubTab},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _socialSubTab = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    setState(() => _socialListMode = !_socialListMode),
                icon: Icon(
                  _socialListMode
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: context.theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                tooltip: _socialListMode ? 'Grid view' : 'List view',
                style: IconButton.styleFrom(
                  backgroundColor: context.theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                _socialSubTab == 0 ? 'Not following anyone' : 'No followers',
                style: TextStyle(
                  color: context.theme.colorScheme.onSurfaceVariant
                      .withOpacity(0.6),
                ),
              ),
            ),
          )
        else if (_socialListMode)
          // List view
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: list.map((user) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      final currentUserId =
                          Get.find<ServiceHandler>().profileData.value.id;
                      if (user.id.toString() == currentUserId) {
                        navigateWithSlide(() => const ProfilePage());
                      } else {
                        navigateWithSlide(
                            () => UserProfilePage(userId: user.id));
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 90,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Banner image
                            if (user.bannerImage != null)
                              CachedNetworkImage(
                                imageUrl: user.bannerImage!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: context
                                      .theme.colorScheme.surfaceContainerHigh,
                                ),
                              )
                            else if (user.avatarUrl != null)
                              CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: context
                                      .theme.colorScheme.surfaceContainerHigh,
                                ),
                              )
                            else
                              Container(
                                color: context
                                    .theme.colorScheme.surfaceContainerHigh,
                              ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    context.theme.colorScheme.surface
                                        .withOpacity(0.9),
                                    context.theme.colorScheme.surface
                                        .withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Avatar + Name
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  if (user.avatarUrl != null)
                                    ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user.avatarUrl!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.transparent,
                                          child: Icon(Icons.person, size: 24),
                                        ),
                                      ),
                                    )
                                  else
                                    const CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.transparent,
                                      child: Icon(Icons.person, size: 24),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AnymexText(
                                      text: user.name,
                                      size: 15,
                                      variant: TextVariant.bold,
                                      color:
                                          context.theme.colorScheme.onSurface,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      isMarquee: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          // Grid view
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                const spacing = 10.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                final avatarRadius = (itemWidth * 0.34).clamp(24.0, 42.0);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: itemWidth / (avatarRadius * 2 + 48),
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final user = list[index];
                    return GestureDetector(
                      onTap: () {
                        final currentUserId =
                            Get.find<ServiceHandler>().profileData.value.id;
                        if (user.id.toString() == currentUserId) {
                          navigateWithSlide(() => const ProfilePage());
                        } else {
                          navigateWithSlide(
                              () => UserProfilePage(userId: user.id));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainerHigh
                              .withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (user.avatarUrl != null)
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl!,
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: Colors.transparent,
                                    child: Icon(Icons.person,
                                        size: avatarRadius * 0.7),
                                  ),
                                ),
                              )
                            else
                              CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Colors.transparent,
                                child: Icon(Icons.person,
                                    size: avatarRadius * 0.7),
                              ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: AnymexText(
                                text: user.name,
                                size: 11.5,
                                variant: TextVariant.bold,
                                color: context.theme.colorScheme.onSurface,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                isMarquee: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        if (_socialLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (!_socialLoadingMore && !_activeSocialHasMore && list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'No more users',
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.onSurfaceVariant
                      .withOpacity(0.6),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
