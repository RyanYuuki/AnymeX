import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/screens/profile/activity_details_page.dart';
import 'package:anymex/widgets/non_widgets/activity_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:anymex/screens/profile/widgets/widgets.dart';
import 'dart:developer';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bannerController;
  late final Animation<Alignment> _bannerAnim;
  bool _ready = false;
  int _selectedTab = 0;
  List<AnilistActivity> _activities = [];
  bool _activitiesLoading = true;
  bool _loadingMoreActivities = false;
  bool _hasMoreActivities = true;
  int _activitiesPage = 1;
  final List<String> _activityFilters = [
    'ANIME_LIST',
    'MANGA_LIST',
    'TEXT',
    'MESSAGE',
  ];

  // Social tab
  final GlobalKey<SocialTabState> _socialTabKey = GlobalKey<SocialTabState>();
  bool _isAboutExpanded = true;

  Color? _avatarDominantColor;

  Future<void> _extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 5,
      );
      if (mounted) {
        setState(() {
          _avatarDominantColor = palette.dominantColor?.color ??
              palette.vibrantColor?.color ??
              palette.mutedColor?.color;
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
    )..repeat(reverse: true);
    _bannerAnim = Tween<Alignment>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeInOut),
    );
    _fetchActivities();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
      final handler = Get.find<ServiceHandler>();
      if (handler.profileData.value.avatar != null) {
        _extractDominantColor(handler.profileData.value.avatar!);
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();

    super.dispose();
  }

  Future<void> _fetchActivities({bool reset = true}) async {
    final handler = Get.find<ServiceHandler>();
    final userId = handler.profileData.value.id;
    if (userId == null) {
      setState(() => _activitiesLoading = false);
      return;
    }
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
        int.parse(userId),
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
    Get.find<ServiceHandler>().refresh();
    if (!mounted || !showMessage) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity refreshed'),
        duration: Duration(milliseconds: 1200),
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
          label: 'Overview',
          onTap: (i) => setState(() => _selectedTab = 0),
        ),
        NavItem(
          selectedIcon: Icons.forum_rounded,
          unselectedIcon: Icons.forum_outlined,
          label: 'Activity',
          onTap: (i) => setState(() => _selectedTab = 1),
        ),
        NavItem(
          selectedIcon: IconlyBold.chart,
          unselectedIcon: IconlyLight.chart,
          label: 'Stats',
          onTap: (i) => setState(() => _selectedTab = 2),
        ),
        NavItem(
          selectedIcon: IconlyBold.user_3,
          unselectedIcon: IconlyLight.user_1,
          label: 'Social',
          onTap: (i) => setState(() => _selectedTab = 3),
        ),
      ];

  Widget _buildBody(BuildContext context, bool isDesktop) {
    final handler = Get.find<ServiceHandler>();
    final profileData = handler.profileData;

    return Obx(() {
      final user = profileData.value;

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
                  DesktopProfileHeader(
                    user: user,
                    bannerAnim: _bannerAnim,
                    bannerController: _bannerController,
                    avatarDominantColor: _avatarDominantColor,
                  ),
                  const SizedBox(height: 40),
                  DesktopStatsGrid(user: user),
                  const SizedBox(height: 34),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: HighlightCard(
                                label: 'Anime',
                                value: user.stats?.animeStats?.animeCount
                                        ?.toString() ??
                                    '0',
                                icon: IconlyBold.video,
                                color: context.theme.colorScheme.primary,
                                onTap: () {
                                  final userId =
                                      int.tryParse(user.id ?? '') ?? 0;
                                  navigate(
                                    () => UserMediaListPage(
                                      userId: userId,
                                      type: 'ANIME',
                                      userName: user.name ?? 'User',
                                      favourites: user.favourites?.anime,
                                      sectionOrder: user.animeSectionOrder,
                                    ),
                                  );
                                },
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HighlightCard(
                                label: 'Manga',
                                value: user.stats?.mangaStats?.mangaCount
                                        ?.toString() ??
                                    '0',
                                icon: IconlyBold.document,
                                color: context.theme.colorScheme.secondary,
                                onTap: () {
                                  final userId =
                                      int.tryParse(user.id ?? '') ?? 0;
                                  navigate(
                                    () => UserMediaListPage(
                                      userId: userId,
                                      type: 'MANGA',
                                      userName: user.name ?? 'User',
                                      favourites: user.favourites?.manga,
                                      sectionOrder: user.mangaSectionOrder,
                                    ),
                                  );
                                },
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

      return NotificationListener<ScrollNotification>(
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              if (!isDesktop)
                MobileProfileHeaderSliver(
                  avatarUrl: user.avatar ?? '',
                  bannerUrl: user.cover,
                  user: user,
                  bannerAnim: _bannerAnim,
                  bannerController: _bannerController,
                ),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = getResponsiveValue(
      context,
      mobileValue: false,
      desktopValue: true,
    );

    return Glow(
      child: Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        extendBody: true,
        bottomNavigationBar: isDesktop
            ? null
            : ResponsiveNavBar(
                isDesktop: false,
                currentIndex: _selectedTab,
                items: _profileNavItems,
              ),
        body: _ready
            ? _buildBody(context, isDesktop)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showCreateActivitySheet(BuildContext context) {
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
            discardTitle: 'Discard status?',
            discardMessage:
                'You have unsent text. Closing now will lose your status.',
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    Text(
                      "Create Status",
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
                          discardTitle: 'Discard status?',
                          discardMessage:
                              'You have unsent text. Closing now will lose your status.',
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
                    hintText: "What's on your mind?",
                    onSubmit: (text, {isPrivate = false}) async {
                      final anilistAuth = Get.find<AnilistAuth>();
                      try {
                        await anilistAuth.createActivity(text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status posted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _fetchActivities(); // refresh listt
                        }
                        return true;
                      } catch (e) {
                        if (context.mounted) {
                          String errorMessage = 'Failed to post status.';
                          final errStr = e.toString();
                          if (errStr.contains('validation')) {
                            errorMessage =
                                'Failed: ${errStr.split('"text":[').last.split(']').first.replaceAll('"', '')}';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: context.theme.colorScheme.error,
                            ),
                          );
                        }
                        return false;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
          userId: int.tryParse(
                  Get.find<ServiceHandler>().profileData.value.id?.toString() ??
                      '0') ??
              0,
          onCountsFetched: (followingCount, followersCount) {
            final profile = Get.find<ServiceHandler>().profileData.value;
            profile.following = followingCount;
            profile.followers = followersCount;
          },
        );
        break;
      case 1:
        return _buildActivitySlivers(context);
      default:
        content = _buildOverviewTab(context, user);
    }
    final isDesktop = getResponsiveValue(
      context,
      mobileValue: false,
      desktopValue: true,
    );
    final maxW = (isDesktop && _selectedTab == 0) ? 1400.0 : 900.0;
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: content,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildActivitySlivers(BuildContext context) {
    if (_activitiesLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ];
    }

    // Header + filter button
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionHeader(
              title: "Recent Activity", icon: Icons.forum_outlined),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateActivitySheet(context),
                tooltip: "Create Activity",
                style: IconButton.styleFrom(
                  backgroundColor: context.theme.colorScheme.primaryContainer,
                  foregroundColor: context.theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(IconlyLight.filter),
                onPressed: () => _showFilterSheet(context),
                tooltip: "Filter Activities",
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
                  const PlaceholderTab(
                    title: 'Activity',
                    subtitle: 'No recent activity found for selected filters',
                    icon: IconlyLight.activity,
                  ),
                ],
              ),
            ),
          ),
        ),
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final activity = _activities[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: ActivityCard(
                  activity: activity,
                  onDeleted: () => _handleActivityDeleted(activity),
                  onTap: () {
                    if (activity.type == 'ANIME_LIST') {
                      final media = Media(
                        id: activity.mediaId!.toString(),
                        title: activity.mediaTitle ?? '',
                        poster: activity.mediaCoverUrl ?? '',
                        serviceType: ServicesType.anilist,
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
        }, childCount: _activities.length),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No more activities',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
      const SnackBar(
        content: Text('Activity deleted'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, Profile user) {
    final isDesktop = getResponsiveValue(
      context,
      mobileValue: false,
      desktopValue: true,
    );

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

      final auth = Get.find<AnilistAuth>();
      final animeStatuses =
          ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'].map((
        status,
      ) {
        return TypeStat(
          type: status,
          count: auth.animeList
              .where((e) => e.watchingStatus?.toUpperCase() == status)
              .length,
          meanScore: 0,
          amount: 0,
        );
      }).toList();

      final mangaStatuses =
          ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'].map((
        status,
      ) {
        return TypeStat(
          type: status,
          count: auth.mangaList
              .where((e) => e.watchingStatus?.toUpperCase() == status)
              .length,
          meanScore: 0,
          amount: 0,
        );
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: const SectionHeader(
              title: 'Activity',
              icon: IconlyLight.activity,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: needsPadding
                ? const EdgeInsets.symmetric(horizontal: 20.0)
                : EdgeInsets.zero,
            child: ActivityHeatmap(history: user.activityHistory!),
          ),
          if (animeStatuses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: needsPadding
                  ? EdgeInsets.symmetric(horizontal: isDesktop ? 20.0 : 26.0)
                  : EdgeInsets.zero,
              child: buildListStatusCard(
                context,
                title: "ANIME LIST",
                statuses: animeStatuses,
                userId: int.tryParse(user.id?.toString() ?? '0') ?? 0,
                userName: user.name ?? "User",
                isAnime: true,
              ),
            ),
          ],
          if (mangaStatuses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: needsPadding
                  ? EdgeInsets.symmetric(horizontal: isDesktop ? 20.0 : 26.0)
                  : EdgeInsets.zero,
              child: buildListStatusCard(
                context,
                title: "MANGA LIST",
                statuses: mangaStatuses,
                userId: int.tryParse(user.id?.toString() ?? '0') ?? 0,
                userName: user.name ?? "User",
                isAnime: false,
              ),
            ),
          ],
        ],
      );
    }

    Widget buildFavouritesSection({bool needsPadding = true}) {
      return FavoritesSection(user: user, needsPadding: needsPadding);
    }

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: About
            Expanded(flex: 6, child: buildAboutSection(needsPadding: false)),
            const SizedBox(width: 20),
            // Right column: Activity + Favourites
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mobile stats ui
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: SectionHeader(title: "Stats", icon: IconlyLight.chart),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.theme.colorScheme.outlineVariant.withOpacity(
                  0.3,
                ),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                StatRow(
                  label: "Episodes Watched",
                  value: user.stats?.animeStats?.episodesWatched?.toString() ??
                      '0',
                  icon: IconlyLight.play,
                  compact: true,
                ),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                  label: "Minutes Watched",
                  value:
                      user.stats?.animeStats?.minutesWatched?.toString() ?? '0',
                  icon: IconlyLight.time_circle,
                  compact: true,
                ),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                  label: "Chapters Read",
                  value:
                      user.stats?.mangaStats?.chaptersRead?.toString() ?? '0',
                  icon: IconlyLight.paper,
                  compact: true,
                ),
                const Divider(height: 16, thickness: 0.4),
                StatRow(
                  label: "Volumes Read",
                  value: user.stats?.mangaStats?.volumesRead?.toString() ?? '0',
                  icon: IconlyLight.bookmark,
                  compact: true,
                ),
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
                  label: "Anime Score",
                  value: user.stats?.animeStats?.meanScore?.toString() ?? '0',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScoreCard(
                  label: "Manga Score",
                  value: user.stats?.mangaStats?.meanScore?.toString() ?? '0',
                  compact: true,
                ),
              ),
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




  Widget _buildDesktopTabs(BuildContext context) {
    return ProfileDesktopTabs(
      labels: _profileNavItems.map((e) => e.label).toList(),
      selectedIndex: _selectedTab,
      onTabSelected: (i) => setState(() => _selectedTab = i),
    );
  }
}
