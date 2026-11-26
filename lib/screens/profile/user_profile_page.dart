import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';
import 'dart:ui';
import 'package:anymex/widgets/anymex_widgets/anymex_titlebar.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';

import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/screens/profile/activity_details_page.dart';
import 'package:anymex/widgets/non_widgets/activity_card.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:anymex/screens/profile/widgets/widgets.dart';
import 'dart:developer';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/database/comments/model/user_points.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/utils/theme_extensions.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  static final Map<String, Color> _paletteCache = {};
  late final AnimationController _bannerController;
  late final Animation<Alignment> _bannerAnim;
  int _selectedTab = 0;
  Profile? _userProfile;
  bool _profileLoading = true;
  List<AnilistActivity> _activities = [];
  bool _activitiesLoading = true;
  bool _loadingMoreActivities = false;
  bool _hasMoreActivities = true;
  int _activitiesPage = 1;
  final List<String> _activityFilters = [
    'ANIME_LIST',
    'MANGA_LIST',
    'TEXT',
    'MESSAGE'
  ];

  final GlobalKey<SocialTabState> _socialTabKey = GlobalKey<SocialTabState>();

  bool? _isFollowingUser;
  bool? _isFollowerOfUser;
  bool _followToggling = false;
  bool _isAboutExpanded = true;

  Color? _avatarDominantColor;
  String? _customBanner;
  String? _customDecoration;
  String? _customEffect;
  UserPoints? _userPoints;
  Map<String, dynamic>? _linkedAccounts;

  Future<void> _extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    final cached = _paletteCache[imageUrl];
    if (cached != null) {
      if (mounted && _avatarDominantColor != cached) {
        setState(() => _avatarDominantColor = cached);
      }
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(NetworkImage(imageUrl), width: 32, height: 32),
        size: const Size(32, 32),
        maximumColorCount: 4,
      );
      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;
      if (color != null) {
        _paletteCache[imageUrl] = color;
      }
      if (mounted) {
        setState(() {
          _avatarDominantColor = color;
        });
      }
    } catch (e) {
      log("Error extracting palette: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _bannerAnim = Tween<Alignment>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeInOut,
    ));
    _fetchProfile();
    _fetchActivities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isWindows && mounted) {
        AnymeXTitleBar.isTransparent.value = true;
      }
    });
  }

  List<TypeStat> _animeStatuses = [];
  List<TypeStat> _mangaStatuses = [];

  Future<void> _fetchProfile() async {
    final anilistAuth = Get.find<AnilistAuth>();
    final profile = await anilistAuth.fetchUserDetails(widget.userId);

    if (Get.isRegistered<CommentumService>()) {
      try {
        final commentum = Get.find<CommentumService>();
        final profileData =
            await commentum.fetchUserProfile(widget.userId.toString());
        if (profileData != null && mounted) {
          setState(() {
            _customBanner = profileData['banner_url'] as String?;
            _customDecoration = profileData['avatar_decoration'] as String?;
            _customEffect = profileData['profile_effect_url'] as String?;
            if (profileData['linked_accounts'] is Map) {
              _linkedAccounts =
                  Map<String, dynamic>.from(profileData['linked_accounts']);
            }
          });
        }
        final points =
            await commentum.getUserPoints(targetUserId: widget.userId.toString());
        if (points != null && mounted) {
          setState(() {
            _userPoints = points;
          });
        }
      } catch (e) {
        log("Error fetching user Commentum profile: $e");
      }
    }

    if (profile != null) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
          final handler = Get.find<ServiceHandler>();
          final currentUserId = handler.profileData.value.id;
          final isOwner = currentUserId != null &&
              widget.userId == int.tryParse(currentUserId);

          if (!isOwner) {
            _isFollowingUser = profile.isFollowing;
            _isFollowerOfUser = profile.isFollower;
          } else {
            _isFollowingUser = null;
            _isFollowerOfUser = null;
          }

          _animeStatuses = profile.stats?.animeStats?.statuses ?? [];
          _mangaStatuses = profile.stats?.mangaStats?.statuses ?? [];
          _profileLoading = false;
        });

        if (profile.avatar != null) {
          Future.microtask(() => _extractDominantColor(profile.avatar!));
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followToggling) return;

    final previousState = _isFollowingUser;

    setState(() {
      _followToggling = true;
      _isFollowingUser = !(_isFollowingUser ?? false);
    });

    final anilistAuth = Get.find<AnilistAuth>();
    final result = await anilistAuth.toggleFollow(widget.userId);

    if (mounted) {
      setState(() {
        _followToggling = false;
        if (result != null) {
          _isFollowingUser = result;
        } else {
          _isFollowingUser = previousState; // fallback
        }
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnymeXTitleBar.isTransparent.value = false;
      });
    }
    _bannerController.dispose();

    super.dispose();
  }

  Future<void> _fetchActivities({bool reset = true}) async {
    if (reset) {
      setState(() {
        if (_activities.isEmpty) _activitiesLoading = true;
        _activitiesPage = 1;
        _hasMoreActivities = true;
      });
    }
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      final (activities, hasMore) = await anilistAuth.fetchUserActivities(
        widget.userId,
        page: _activitiesPage,
        typeIn: _activityFilters,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _activities = activities.toList();
          } else {
            _activities.addAll(activities);
          }
          _hasMoreActivities = hasMore;
          _activitiesLoading = false;
          _loadingMoreActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activitiesLoading = false;
          _loadingMoreActivities = false;
        });
      }
    }
  }

  Future<void> _refreshActivityTab({bool showMessage = true}) async {
    if (mounted) {
      setState(() {
        _activitiesLoading = true;
        _activities = [];
        _activitiesPage = 1;
        _hasMoreActivities = true;
      });
    }
    await _fetchActivities(reset: true);
    if (!mounted || !showMessage) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AnymeXText(context.l10n.activityRefreshed),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _loadMoreActivities() {
    if (_loadingMoreActivities || !_hasMoreActivities) return;
    setState(() {
      _loadingMoreActivities = true;
      _activitiesPage++;
    });
    _fetchActivities(reset: false);
  }

  List<NavItem> get _profileNavItems => [
        NavItem(
          selectedIcon: IconlyBold.home,
          unselectedIcon: IconlyLight.home,
          label: context.l10n.overview,
          onTap: (i) => setState(() => _selectedTab = 0),
        ),
        NavItem(
          selectedIcon: Icons.forum_rounded,
          unselectedIcon: Icons.forum_outlined,
          label: context.l10n.activity,
          onTap: (i) => setState(() => _selectedTab = 1),
        ),
        NavItem(
          selectedIcon: IconlyBold.chart,
          unselectedIcon: IconlyLight.chart,
          label: context.l10n.stats,
          onTap: (i) => setState(() => _selectedTab = 2),
        ),
        NavItem(
          selectedIcon: IconlyBold.user3,
          unselectedIcon: IconlyLight.user2,
          label: context.l10n.social,
          onTap: (i) => setState(() => _selectedTab = 3),
        ),
      ];

  Widget _buildBody(BuildContext context, bool isDesktop) {
    if (_profileLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnymeXText(
            context.l10n.failedToLoadProfileAccountMay,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final user = _userProfile!;
    final bannerUrl = user.avatar ?? '';

    final tabScrollView = CustomScrollView(
      physics: isDesktop
          ? const AlwaysScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      slivers: [
        if (isDesktop)
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDesktopHeader(context, user, _bannerAnim),
                const SizedBox(height: 40),
                DesktopStatsGrid(user: user),
                const SizedBox(height: 20),
                _buildDesktopTabs(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        if (!isDesktop)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: HighlightCard(
                              label: context.l10n.anime,
                              value: user.stats?.animeStats?.animeCount
                                      ?.toString() ??
                                  '0',
                              icon: IconlyBold.video,
                              color: context.theme.colorScheme.primary,
                              onTap: () =>
                                  _openUserList('ANIME', user.name ?? 'User'),
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: HighlightCard(
                              label: context.l10n.manga,
                              value: user.stats?.mangaStats?.mangaCount
                                      ?.toString() ??
                                  '0',
                              icon: IconlyBold.document,
                              color: context.theme.colorScheme.secondary,
                              onTap: () =>
                                  _openUserList('MANGA', user.name ?? 'User'),
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ..._buildTabSlivers(context, user),
      ],
    );

    final content = NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification &&
            _selectedTab == 1 &&
            !_loadingMoreActivities &&
            _hasMoreActivities &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreActivities();
        } else if (scrollInfo is ScrollUpdateNotification &&
            _selectedTab == 3 &&
            (_socialTabKey.currentState?.shouldLoadMore ?? false) &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _socialTabKey.currentState?.loadMore();
        }
        return false;
      },
      child: isDesktop
          ? tabScrollView
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  if (!isDesktop)
                    _buildSliverAppBar(
                        context, bannerUrl, user.cover, user, _bannerAnim),
                ];
              },
              body: _selectedTab == 1
                  ? RefreshIndicator(
                      onRefresh: () => _refreshActivityTab(showMessage: false),
                      child: tabScrollView,
                    )
                  : tabScrollView,
            ),
    );

    final blurScope = settingsController.detailsBlurScope;
    final isMesh = settingsController.detailsBlurStyle == 1;
    final isBaked = isMesh || settingsController.useComputedBlur;
    final blurAmount =
        UISettingsKeys.detailsBlurAmount.get<double>(20.0);
    final brightness =
        UISettingsKeys.detailsBackdropBrightness.get<double>(1.0);
    final hasCustomBanner =
        _customBanner != null && _customBanner!.trim().isNotEmpty;
    final hasCover = user.cover != null && user.cover!.trim().isNotEmpty;
    final effectiveBanner =
        hasCustomBanner ? _customBanner! : (hasCover ? user.cover! : '');
    final hasBanner = effectiveBanner.isNotEmpty;
    final blurSourceUrl =
        hasBanner ? effectiveBanner : (user.avatar ?? '');
    final blurFallbackUrl =
        (user.avatar != null && user.avatar!.isNotEmpty)
            ? user.avatar!
            : (hasBanner ? effectiveBanner : '');
    final tintBlur = settingsController.tintBlur;
    final colors = context.colors;
    final blurColor = tintBlur ? colors.primary.opaque(0.4) : null;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final baseArtworkColor = tintBlur
        ? colors.primary
        : (_avatarDominantColor ?? colors.primary);
    final gradientBgColor = Color.alphaBlend(
      baseArtworkColor.withValues(alpha: isDark ? 0.20 : 0.12),
      colors.surface,
    );

    Widget buildBlurredImage({double? height}) {
      if (blurSourceUrl.isEmpty) {
        return Container(
          height: height ?? double.infinity,
          width: double.infinity,
          color: gradientBgColor,
        );
      }
      return isBaked
          ? BakedBlurImage(
              url: blurSourceUrl,
              fallback: blurFallbackUrl,
              saturation: 1.0,
              blurAmount: blurAmount,
              brightness: brightness,
              color: blurColor,
              fit: BoxFit.cover,
              height: height,
              width: double.infinity,
              fadeBottom: true,
              isMesh: isMesh,
            )
          : ColorFiltered(
              colorFilter: ColorFilter.matrix([
                brightness, 0, 0, 0, 0,
                0, brightness, 0, 0, 0,
                0, 0, brightness, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: blurAmount, sigmaY: blurAmount),
                child: AnymeXImage(
                  imageUrl: blurSourceUrl,
                  errorImage: blurFallbackUrl,
                  radius: 0,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height ?? double.infinity,
                  color: blurColor,
                ),
              ),
            );
    }

    if (blurScope == 2) {
      final washHeight = (MediaQuery.sizeOf(context).height * 0.48)
          .clamp(320.0, 520.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              color: gradientBgColor,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: washHeight,
            child: RepaintBoundary(
              child: buildBlurredImage(height: washHeight),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: washHeight + 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
                  colors: [
                    gradientBgColor.withValues(
                        alpha: isDark ? 0.30 : 0.10),
                    gradientBgColor.withValues(
                        alpha: isDark ? 0.55 : 0.25),
                    gradientBgColor.withValues(
                        alpha: isDark ? 0.85 : 0.65),
                    gradientBgColor,
                    gradientBgColor,
                  ],
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: buildBlurredImage(),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surface.withValues(alpha: 0.40),
                  colors.surface.withValues(alpha: 0.65),
                  colors.surface.withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);

    return AnymeXScaffold(
      backgroundColor: Colors.transparent,
      extendBehindTitleBar: Platform.isWindows,
      extendBody: true,
      bottomNavigationBar: isDesktop
          ? null
          : ResponsiveNavBar(
              isDesktop: false,
              currentIndex: _selectedTab,
              items: _profileNavItems,
            ),
      body: _buildBody(context, isDesktop),
    );
  }

  List<Widget> _buildTabSlivers(BuildContext context, Profile user) {
    Widget content;
    switch (_selectedTab) {
      case 0:
        content = _buildOverviewTab(context, user);
        break;
      case 2:
        content = ProfileStatsTab(user: user);
        break;
      case 3:
        content = SocialTab(
          key: _socialTabKey,
          userId: widget.userId,
          onCountsFetched: (followingCount, followersCount) {
            if (_userProfile != null) {
              _userProfile!.following = followingCount;
              _userProfile!.followers = followersCount;
            }
          },
        );
        break;
      case 1:
        return _buildActivitySlivers(context);
      default:
        content = _buildOverviewTab(context, user);
    }
    final isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);
    final maxW = (isDesktop && _selectedTab == 0) ? 1400.0 : 900.0;
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: content,
          ),
        ),
      )
    ];
  }

  List<Widget> _buildActivitySlivers(BuildContext context) {
    if (_activitiesLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      ];
    }

    final String? currentUserId =
        Get.find<ServiceHandler>().profileData.value.id;
    final bool isOwner =
        currentUserId != null && widget.userId == int.tryParse(currentUserId);

    // Header + filter buttonn
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionHeader(
              title: context.l10n.recentActivity, icon: Icons.forum_outlined),
          Row(
            children: [
              if (!isOwner)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (!Get.find<AnilistAuth>().isLoggedIn.value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: AnymeXText(context.l10n.pleaseLoginFirst),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                      return;
                    }
                    _showCreateMessageSheet(context);
                  },
                  tooltip: context.l10n.messageFriend,
                  style: IconButton.styleFrom(
                    backgroundColor: context.theme.colorScheme.primaryContainer,
                    foregroundColor: context.theme.colorScheme.primary,
                  ),
                ),
              if (!isOwner) const SizedBox(width: 8),
              IconButton(
                icon: const Icon(IconlyLight.filter),
                onPressed: () => _showFilterSheet(context),
                tooltip: context.l10n.filterActivities,
              ),
            ],
          ),
        ],
      ),
    );

    if (_activities.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  header,
                  PlaceholderTab(
                      title: context.l10n.activity,
                      subtitle: context.l10n.noRecentActivityFoundForSelected,
                      icon: IconlyLight.activity),
                ],
              ),
            ),
          ),
        )
      ];
    }

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                header,
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final activity = _activities[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: ActivityCard(
                    isOwnProfile: isOwner,
                    activity: activity,
                    onDeleted: () => _handleActivityDeleted(activity),
                    onTap: () {
                      if (activity.type == 'ANIME_LIST') {
                        final media = Media(
                          id: activity.mediaId!.toString(),
                          title: activity.mediaTitle ?? '',
                          poster: activity.mediaCoverUrl ?? '',
                          serviceType: ServicesType.anilist,
                          mediaType: ItemType.anime,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnimeDetailsPage(
                              media: media,
                              tag: 'activity-${activity.id}',
                            ),
                          ),
                        );
                      } else if (activity.type == 'MANGA_LIST') {
                        final media = Media(
                          id: activity.mediaId!.toString(),
                          title: activity.mediaTitle ?? '',
                          poster: activity.mediaCoverUrl ?? '',
                          serviceType: ServicesType.anilist,
                          mediaType: ItemType.manga,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MangaDetailsPage(
                              media: media,
                              tag: 'activity-${activity.id}',
                            ),
                          ),
                        );
                      } else {
                        showActivityDetailsSheet(context, activity);
                      }
                    },
                    onReplyTap: () {
                      showActivityDetailsSheet(context, activity);
                    },
                  ),
                ),
              ),
            );
          },
          childCount: _activities.length,
        ),
      ),
    ];

    if (_loadingMoreActivities ||
        (!_hasMoreActivities && _activities.isNotEmpty)) {
      slivers.add(
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  if (_loadingMoreActivities)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (!_hasMoreActivities && _activities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: AnymeXText(
                          context.l10n.noMoreActivities,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 40)));
    }

    return slivers;
  }

  void _showFilterSheet(BuildContext context) {
    showActivityFilterSheet(
      context,
      activityFilters: _activityFilters,
      onApply: () => _fetchActivities(),
    );
  }

  void _handleActivityDeleted(AnilistActivity activity) {
    if (!mounted) return;
    setState(() {
      _activities.removeWhere((a) => a.id == activity.id);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AnymeXText(context.l10n.activityDeleted),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Profile user) {
    final isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);

    final hasAbout = (user.about != null && user.about!.trim().isNotEmpty) ||
        (user.aboutMarkdown != null && user.aboutMarkdown!.trim().isNotEmpty);

    Widget buildAboutSection({bool needsPadding = true}) {
      if (!hasAbout) return const SizedBox.shrink();
      final aboutText = (user.about?.trim().isNotEmpty ?? false)
          ? user.about!
          : (user.aboutMarkdown ?? '');
      return AboutSection(
        aboutText: aboutText,
        needsPadding: needsPadding,
        isDesktop: isDesktop,
        isExpanded: _isAboutExpanded,
        onToggle: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
      );
    }

    final hasActivity =
        user.activityHistory != null && user.activityHistory!.isNotEmpty;

    Widget buildListStatusCard(
      BuildContext context, {
      required String title,
      required List<TypeStat> statuses,
      required int userId,
      required String userName,
      required bool isAnime,
    }) {
      return ListStatusCard(
        title: title,
        statuses: statuses,
        userId: userId,
        userName: userName,
        isAnime: isAnime,
      );
    }

    Widget buildActivitySection({bool needsPadding = true}) {
      if (!hasActivity) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: SectionHeader(
                title: context.l10n.activity, icon: IconlyLight.activity),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: ActivityHeatmap(history: user.activityHistory!),
          ),
          if (_animeStatuses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: needsPadding
                  ? EdgeInsets.symmetric(horizontal: isDesktop ? 20.0 : 26.0)
                  : EdgeInsets.zero,
              child: buildListStatusCard(context,
                  title: context.l10n.animeList,
                  statuses: _animeStatuses,
                  userId: int.tryParse(user.id?.toString() ?? '0') ?? 0,
                  userName: user.name ?? "User",
                  isAnime: true),
            ),
          ],
          if (_mangaStatuses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: needsPadding
                  ? EdgeInsets.symmetric(horizontal: isDesktop ? 20.0 : 26.0)
                  : EdgeInsets.zero,
              child: buildListStatusCard(context,
                  title: context.l10n.mangaList,
                  statuses: _mangaStatuses,
                  userId: int.tryParse(user.id?.toString() ?? '0') ?? 0,
                  userName: user.name ?? "User",
                  isAnime: false),
            ),
          ],
        ],
      );
    }

    Widget buildFavouritesSection({bool needsPadding = true}) {
      return FavoritesSection(user: user, needsPadding: needsPadding);
    }

    if (isDesktop) {
      final hasFavourites = (user.favourites?.anime.isNotEmpty ?? false) ||
          (user.favourites?.manga.isNotEmpty ?? false) ||
          (user.favourites?.characters.isNotEmpty ?? false) ||
          (user.favourites?.staff.isNotEmpty ?? false) ||
          (user.favourites?.studios.isNotEmpty ?? false);
      final hasRightColumn = hasActivity || hasFavourites;

      if (hasAbout && hasRightColumn) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: buildAboutSection(needsPadding: false),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildActivitySection(needsPadding: false),
                    buildFavouritesSection(needsPadding: false),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        );
      } else if (hasAbout) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: buildAboutSection(needsPadding: false),
        );
      } else if (hasRightColumn) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildActivitySection(needsPadding: false),
              buildFavouritesSection(needsPadding: false),
              const SizedBox(height: 50),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mobile stats ui
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SectionHeader(title: context.l10n.stats, icon: IconlyLight.chart),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerLow.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    context.theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                StatRow(
                    label: context.l10n.episodesWatched,
                    value:
                        user.stats?.animeStats?.episodesWatched?.toString() ??
                            '0',
                    icon: IconlyLight.play,
                    compact: true),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                    label: context.l10n.minutesWatched,
                    value: user.stats?.animeStats?.minutesWatched?.toString() ??
                        '0',
                    icon: IconlyLight.timeCircle,
                    compact: true),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                    label: context.l10n.chaptersRead,
                    value:
                        user.stats?.mangaStats?.chaptersRead?.toString() ?? '0',
                    icon: IconlyLight.paper,
                    compact: true),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                    label: context.l10n.volumesRead,
                    value:
                        user.stats?.mangaStats?.volumesRead?.toString() ?? '0',
                    icon: IconlyLight.bookmark,
                    compact: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                  child: ScoreCard(
                      label: context.l10n.animeScore,
                      value:
                          user.stats?.animeStats?.meanScore?.toString() ?? '0',
                      compact: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: ScoreCard(
                      label: context.l10n.mangaScore,
                      value:
                          user.stats?.mangaStats?.meanScore?.toString() ?? '0',
                      compact: true)),
            ],
          ),
        ),
        buildActivitySection(),
        buildAboutSection(),
        buildFavouritesSection(),
        SizedBox(height: isDesktop ? 50 : 120),
      ],
    );
  }

  Widget _buildDesktopHeader(
      BuildContext context, Profile user, Animation<Alignment> bannerAnim) {
    return UserProfileHeader(
      user: user,
      bannerController: _bannerController,
      bannerAnim: bannerAnim,
      avatarDominantColor: _avatarDominantColor,
      avatarDecoration: _customDecoration,
      customBanner: _customBanner,
      profileEffect: _customEffect,
      userPoints: _userPoints,
      linkedAccounts: _linkedAccounts,
      isFollowingUser: _isFollowingUser,
      isFollowerOfUser: _isFollowerOfUser,
      followToggling: _followToggling,
      onToggleFollow: _toggleFollow,
    );
  }

  Widget _buildDesktopTabs(BuildContext context) {
    return ProfileDesktopTabs(
      labels: _profileNavItems.map((e) => e.label).toList(),
      selectedIndex: _selectedTab,
      onTabSelected: (i) => setState(() => _selectedTab = i),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String avatarUrl,
      String? bannerUrl, Profile user, Animation<Alignment> bannerAnim) {
    final effectiveBanner = (_customBanner != null && _customBanner!.trim().isNotEmpty)
        ? _customBanner
        : bannerUrl;
    return UserProfileAppBar(
      user: user,
      avatarUrl: avatarUrl,
      bannerUrl: effectiveBanner,
      avatarDecoration: _customDecoration,
      profileEffect: _customEffect,
      userPoints: _userPoints,
      linkedAccounts: _linkedAccounts,
      bannerController: _bannerController,
      bannerAnim: bannerAnim,
      isFollowingUser: _isFollowingUser,
      isFollowerOfUser: _isFollowerOfUser,
      followToggling: _followToggling,
      onToggleFollow: _toggleFollow,
    );
  }

  void _openUserList(String type, String userName) {
    final favs = type == 'ANIME'
        ? _userProfile?.favourites?.anime
        : _userProfile?.favourites?.manga;
    final sectionOrder = type == 'ANIME'
        ? (_userProfile?.animeSectionOrder ?? const [])
        : (_userProfile?.mangaSectionOrder ?? const []);
    navigate(() => UserMediaListPage(
          userId: widget.userId,
          type: type,
          userName: userName,
          favourites: favs,
          sectionOrder: sectionOrder,
        ));
  }

  void _showCreateMessageSheet(BuildContext context) {
    final composerKey = GlobalKey<ActivityComposerSheetState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return WillPopScope(
          onWillPop: () => confirmDiscardComposer(
            context,
            composerKey: composerKey,
            discardTitle: context.l10n.discardMessage,
            discardMessage:
                context.l10n.youHaveUnsentTextClosingNow,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnymeXText(
                      "Message ${_userProfile?.name ?? 'User'}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        final discard = await confirmDiscardComposer(
                          context,
                          composerKey: composerKey,
                          discardTitle: context.l10n.discardMessage,
                          discardMessage:
                              context.l10n.youHaveUnsentTextClosingNow,
                        );
                        if (discard && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ActivityComposerSheet(
                    key: composerKey,
                    isModal: true,
                    hintText: context.l10n.writeAMessage,
                    showPrivateToggle: true,
                    onSubmit: (text, {isPrivate = false}) async {
                      final anilistAuth = Get.find<AnilistAuth>();
                      try {
                        await anilistAuth.createMessageActivity(
                            widget.userId, text, isPrivate);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AnymeXText(isPrivate
                                  ? 'Private message sent successfully!'
                                  : 'Message posted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _refreshActivityTab(showMessage: false);
                        return true;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AnymeXText(context.l10n.failedToPostMessage(e.toString())),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return false;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
