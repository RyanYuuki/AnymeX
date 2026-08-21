import 'package:anymex/utils/media_share.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/screens/anime/details/widgets/media_stats_section.dart';
import 'package:anymex/screens/anime/details/widgets/media_characters_section.dart';
import 'package:anymex/screens/anime/details/widgets/media_quick_actions.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/anime/widgets/episode_section.dart';
import 'package:anymex/screens/manga/widgets/chapter_section.dart';
import 'package:anymex/screens/anime/widgets/voice_actor.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/ui_extensions/sizing.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/screens/manga/widgets/track_dialog.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/anime/media_header.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaDetailsPage extends StatefulWidget {
  final Media media;
  final String tag;
  final Source? source;
  final int initialTabIndex;

  const MediaDetailsPage({
    super.key,
    required this.media,
    required this.tag,
    this.source,
    this.initialTabIndex = 0,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  late final MediaDetailsController controller;
  late final PageController pageController;
  bool _isAnimatingPage = false;
  bool _isContinueExpanded = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialTabIndex);
    controller = Get.put(
      MediaDetailsController(
        initialMedia: widget.media,
        tag: widget.tag,
        initialSource: widget.source,
        initialTabIndex: widget.initialTabIndex,
      ),
      tag: widget.tag,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    Get.delete<MediaDetailsController>(tag: widget.tag);
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (controller.selectedPage.value == index) return;
    controller.selectedPage.value = index;
    _isAnimatingPage = true;
    pageController
        .animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    )
        .then((_) {
      _isAnimatingPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      extendBody: true,
      bottomNavigationBar: buildBottomNavBar(context),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Align(
          alignment: Alignment.topCenter,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Obx(() => MediaHeader(
                      tag: widget.tag,
                      data: controller.media.value,
                      posterUrl: controller.media.value.poster,
                      userStatus: controller.mediaStatus.value,
                      userProgress: '${controller.mediaProgress.value}',
                      onShare: () => MediaShare.showOptions(
                        context: context,
                        baseMedia: controller.media.value,
                        hydratedMedia: controller.media.value,
                        isManga: controller.isManga || controller.isNovel,
                      ),
                    )),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      buildMediaQuickActions(context, controller),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
            body: PageView(
              controller: pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (!_isAnimatingPage) {
                  controller.selectedPage.value = index;
                }
              },
              children: [
                _buildOverviewTab(context),
                _buildContentTab(context),
                _buildCommentsTab(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavBar(BuildContext context) {
    final isAnime = controller.isAnime;
    final navItems = [
      NavItem(
        selectedIcon: Iconsax.info_circle5,
        unselectedIcon: Iconsax.info_circle,
        label: 'Info',
        onTap: (index) => _onTabSelected(index),
      ),
      NavItem(
        selectedIcon: isAnime ? Iconsax.play5 : Icons.menu_book_rounded,
        unselectedIcon: isAnime ? Iconsax.play : Icons.menu_book_outlined,
        label: isAnime ? 'Watch' : 'Read',
        onTap: (index) => _onTabSelected(index),
      ),
      NavItem(
        selectedIcon: HugeIcons.strokeRoundedComment01,
        unselectedIcon: HugeIcons.strokeRoundedComment02,
        label: 'Comments',
        onTap: (index) => _onTabSelected(index),
      ),
    ];

    return Obx(() {
      final selected = controller.selectedPage.value;
      final isDesktop =
          getResponsiveValue(context, mobileValue: false, desktopValue: true);
      final child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContinueButton(context),
          SafeArea(
            child: ResponsiveNavBar(
              isDesktop: false,
              currentIndex: selected,
              margin: EdgeInsets.fromLTRB(32, 0, 32, isDesktop ? 32 : 10),
              items: navItems,
            ),
          ),
        ],
      );
      if (isDesktop) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: child,
          ),
        );
      }
      return child;
    });
  }

  Widget _buildShimmerCarousel(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor:
          colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true),
      highlightColor:
          colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      width: 110,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor:
          colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true),
      highlightColor:
          colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ).bottomSpacing(12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ).bottomSpacing(12),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return Obx(() {
      final mediaData = controller.media.value;

      final rels = (mediaData.relations ?? []);

      return CustomScrollView(
        key: const PageStorageKey<String>('Overview'),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildStatsShimmer(context).bottomSpacing(16);
                    }
                    return buildMediaStatsSection(context, controller)
                        .bottomSpacing(16);
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    return buildCharactersSection(context, mediaData);
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    if (rels.isEmpty) return const SizedBox.shrink();
                    return ReusableCarousel(
                      data: rels,
                      title: 'Relations',
                      variant: DataVariant.relation,
                    ).bottomSpacing(16);
                  }),
                  Obx(() {
                    if (controller.isSecondaryLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    if (mediaData.staff == null || mediaData.staff!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return StaffCarousel(staff: mediaData.staff!)
                        .bottomSpacing(16);
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    final recs = mediaData.recommendations;
                    if (recs.isEmpty) return const SizedBox.shrink();
                    return ReusableCarousel(
                      data: recs,
                      title: controller.isAnime
                          ? 'Recommended Anime'
                          : 'Recommended Manga',
                      variant: DataVariant.recommendation,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 250)),
        ],
      );
    });
  }

  Widget _buildContentTab(BuildContext context) {
    if (controller.isAnime) {
      return CustomScrollView(
        key: const PageStorageKey<String>('Content'),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          EpisodeSection(
            searchedTitle: controller.searchedTitle,
            anilistData: controller.media.value,
            episodeList: controller.episodeList,
            episodeError: controller.episodeError,
            isAnify: controller.isAnify,
            showAnify: controller.showAnify,
            disableAnifyForCurrentSource:
                controller.disableAnifyForCurrentSource,
            isSliverMode: true,
            mapToAnilist: () async {},
            getDetailsFromSource: (m) =>
                controller.fetchSourceDetailsFromMedia(m),
            tag: widget.tag,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 250)),
        ],
      );
    }

    return CustomScrollView(
      key: const PageStorageKey<String>('Content'),
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        ChapterSection(
          searchedTitle: controller.searchedTitle,
          anilistData: controller.media.value,
          chapterList: controller.chapterList,
          chapterError: controller.episodeError,
          tag: widget.tag,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 250)),
      ],
    );
  }

  Widget _buildCommentsTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: ExpressiveLoadingIndicator(),
          ),
        );
      }

      return CustomScrollView(
        key: const PageStorageKey<String>('Comments'),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: CommentSection(
                media: controller.media.value,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 250)),
        ],
      );
    });
  }

  Widget _buildContinueButton(BuildContext context) {
    return Obx(() {
      final selectedPage = controller.selectedPage.value;
      final isLoading = controller.isLoading.value;
      final isAnime = controller.isAnime;
      final count = isAnime
          ? controller.episodeList.length
          : controller.chapterList.length;

      final bool hasContent = count > 0 && !isLoading;
      final bool showButton = selectedPage == 1 && hasContent;

      if (!showButton) return const SizedBox.shrink();

      String titleText = '';
      String subtitleText = '';
      String imageUrl = '';
      double progressVal = 0.0;
      VoidCallback? onTap;

      if (isAnime) {
        final ep = controller.getContinueEpisode();
        if (ep == null) return const SizedBox.shrink();
        titleText =
            ep.title?.isNotEmpty == true ? ep.title! : 'Episode ${ep.number}';
        subtitleText = 'Episode ${ep.number}';
        imageUrl = ep.thumbnail?.isNotEmpty == true
            ? ep.thumbnail!
            : controller.media.value.poster;
        progressVal = controller.getEpisodeProgress(ep);
        onTap = () async {
          await EpisodeListBuilder.showServerSheet(
            context,
            episode: ep,
            episodeList: controller.episodeList,
            anilistData: controller.media.value,
          );
          controller.refreshProgress();
        };
      } else {
        final ch = controller.getContinueChapter();
        if (ch == null) return const SizedBox.shrink();
        titleText =
            ch.title?.isNotEmpty == true ? ch.title! : 'Chapter ${ch.number}';
        subtitleText = 'Chapter ${ch.number}';
        imageUrl = controller.media.value.poster;
        progressVal = controller.getChapterProgress(ch);
        onTap = () async {
          final activeSource = controller.activeSource.value;
          if (activeSource == null) return;
          if (controller.isNovel) {
            await navigate(() => NovelReader(
                  chapter: ch,
                  media: controller.media.value,
                  chapters: controller.chapterList,
                  source: activeSource,
                ));
            controller.refreshProgress();
          } else {
            final mediaData = controller.media.value;
            final dbId =
                '${mediaData.id}_${mediaData.serviceType.name}_${mediaData.type}';

            bool shouldTrackValue = false;
            final auth = Get.find<ServiceHandler>();
            final isLoggedInOnline = auth.isLoggedIn.value &&
                auth.serviceType.value != ServicesType.extensions;

            if (isLoggedInOnline) {
              final savedTracking =
                  DynamicKeys.trackingPermission.get<bool?>(dbId);
              if (savedTracking != null) {
                shouldTrackValue = savedTracking;
              } else if (General.shouldAskForTrack.get(true) == false) {
                shouldTrackValue = true;
              } else {
                final isExtension =
                    mediaData.serviceType == ServicesType.extensions;
                final hasTrackBinding =
                    Get.isRegistered<TrackBindingController>() &&
                        Get.find<TrackBindingController>()
                            .hasAnyBinding(mediaData.id);

                if (isExtension) {
                  shouldTrackValue = hasTrackBinding;
                } else {
                  final result = await showTrackingDialog(context, dbId: dbId);
                  shouldTrackValue = result ?? false;
                }
              }
            }

            await navigate(() => ReadingPage(
                  anilistData: mediaData,
                  chapterList: controller.chapterList,
                  currentChapter: ch,
                  shouldTrack: shouldTrackValue,
                ));
            controller.refreshProgress();
          }
        };
      }

      final clampedProgress = progressVal.clamp(0.0, 1.0);
      final hasLocalProgress = clampedProgress > 0;
      final isAddedToTracker =
          controller.isListedMedia.value || controller.mediaProgress.value > 0;
      final showContinue = hasLocalProgress || isAddedToTracker;

      final playButtonText = showContinue
          ? (isAnime ? 'Continue Watching' : 'Continue Reading')
          : (isAnime ? 'Start Watching' : 'Start Reading');

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.onSurface.opaque(0.12, iReallyMeanIt: true),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          isAnime
                              ? Icons.play_circle_fill_rounded
                              : Icons.menu_book_rounded,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isContinueExpanded = !_isContinueExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnymeXText(
                                playButtonText,
                                variant: TextVariant.bold,
                                size: 13,
                                color: context.colors.onSurface,
                              ),
                              const SizedBox(height: 1),
                              AnymeXText(
                                clampedProgress > 0
                                    ? '$subtitleText • ${(clampedProgress * 100).toInt()}% ${isAnime ? 'watched' : 'read'}'
                                    : subtitleText,
                                size: 11,
                                color: context.colors.onSurface
                                    .opaque(0.6, iReallyMeanIt: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _isContinueExpanded = !_isContinueExpanded;
                        });
                      },
                      icon: Icon(
                        _isContinueExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.colors.onSurface
                            .opaque(0.6, iReallyMeanIt: true),
                      ),
                    ),
                  ],
                ),
                if (_isContinueExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 48,
                          child: AnymeXImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymeXText(
                              titleText,
                              variant: TextVariant.bold,
                              size: 13,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                AnymeXText(
                                  subtitleText,
                                  size: 11,
                                  color: context.colors.onSurface
                                      .opaque(0.6, iReallyMeanIt: true),
                                ),
                                if (clampedProgress > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.colors.onSurface
                                          .opaque(0.4, iReallyMeanIt: true),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AnymeXText(
                                    '${(clampedProgress * 100).toInt()}% ${isAnime ? 'watched' : 'read'}',
                                    size: 11,
                                    color: context.colors.primary,
                                    variant: TextVariant.semiBold,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnymexOnTap(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return Stack(
                            children: [
                              if (clampedProgress > 0)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: width * clampedProgress,
                                  child: Container(
                                    color: context.colors.primary
                                        .withValues(alpha: 0.22),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isAnime
                                          ? Icons.play_arrow_rounded
                                          : Icons.menu_book_rounded,
                                      size: 18,
                                      color: context.colors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    AnymeXText(
                                      playButtonText,
                                      variant: TextVariant.bold,
                                      size: 13,
                                      color: context.colors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
