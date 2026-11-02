import 'dart:ui';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/media_share.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/screens/anime/details/widgets/media_stats_section.dart';
import 'package:anymex/screens/anime/details/widgets/media_characters_section.dart';
import 'package:anymex/screens/anime/details/widgets/media_quick_actions.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/comment_input_bar.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/leaderboard_sheet.dart';
import 'package:anymex/widgets/common/policy_sheet.dart';
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
import 'package:anymex/utils/color_extractor.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/anime/media_header.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/helper/keep_alive_wrapper.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
import 'package:anymex/widgets/animation/widget_animations.dart';

class MediaDetailsPage extends StatefulWidget {
  final Media media;
  final String tag;
  final Source? source;
  final int initialTabIndex;
  final String? scrollToCommentId;

  const MediaDetailsPage({
    super.key,
    required this.media,
    required this.tag,
    this.source,
    this.initialTabIndex = 0,
    this.scrollToCommentId,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  late final MediaDetailsController controller;
  late final PageController pageController;
  late final RxString _posterColor;
  bool _isAnimatingPage = false;

  CommentSectionController get _commentController {
    final media = widget.media;
    final tag = media.uniqueId;
    if (Get.isRegistered<CommentSectionController>(tag: tag)) {
      return Get.find<CommentSectionController>(tag: tag);
    }
    final preloaded = CommentPreloader.to.getPreloadedController(tag);
    if (preloaded != null) {
      preloaded.updateProgress(controller.mediaProgress.value);
      return preloaded;
    }
    return Get.put(
      CommentSectionController(
        media: media,
        initialProgress: controller.mediaProgress.value,
      ),
      tag: tag,
    );
  }

  void _resolvePosterColor(Media media) {
    if (media.color.isNotEmpty) {
      if (_posterColor.value != media.color) {
        _posterColor.value = media.color;
      }
      return;
    }
    final poster = media.poster;
    if (poster.isEmpty) return;
    final cached = ImageColorExtractor.getCachedColor(poster);
    if (cached != null) {
      _posterColor.value = '#${cached.value.toRadixString(16).padLeft(8, '0')}';
      return;
    }
    ImageColorExtractor.extractColor(poster).then((c) {
      if (c != null && mounted) {
        _posterColor.value = '#${c.value.toRadixString(16).padLeft(8, '0')}';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _posterColor =
        (widget.media.color.isNotEmpty ? widget.media.color : '').obs;
    _resolvePosterColor(widget.media);
    final initialPage = widget.scrollToCommentId != null
        ? 2
        : widget.initialTabIndex;
    pageController = PageController(initialPage: initialPage);
    controller = Get.put(
      MediaDetailsController(
        initialMedia: widget.media,
        tag: widget.tag,
        initialSource: widget.source,
        initialTabIndex: initialPage,
      ),
      tag: widget.tag,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    Get.delete<MediaDetailsController>(tag: widget.tag);
    final isPreloaded = CommentPreloader.to.isPreloaded(widget.media.uniqueId);
    if (!isPreloaded &&
        Get.isRegistered<CommentSectionController>(
            tag: widget.media.uniqueId)) {
      Get.delete<CommentSectionController>(tag: widget.media.uniqueId);
    }
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
    return Obx(() {
      final currentMedia = controller.media.value;
      if (currentMedia.color.isNotEmpty &&
          _posterColor.value != currentMedia.color) {
        _posterColor.value = currentMedia.color;
      } else if (_posterColor.value.isEmpty && currentMedia.poster.isNotEmpty) {
        _resolvePosterColor(currentMedia);
      }

      final activeColor = currentMedia.color.isNotEmpty
          ? currentMedia.color
          : _posterColor.value;
      final posterSeed =
          (activeColor.isNotEmpty && settingsController.usePosterColor)
              ? AnymeXScaffold.parseColor(activeColor)
              : null;
      final posterScheme = posterSeed != null
          ? ColorScheme.fromSeed(
              brightness: Theme.of(context).brightness,
              seedColor: posterSeed,
            )
          : null;

      Widget buildScaffold(BuildContext themedContext) {
        return AnymeXScaffold(
          color: _posterColor.value,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: buildBottomNavBar(themedContext),
          body: Obx(() {
            final blurScope = settingsController.detailsBlurScope;
            final isMesh = settingsController.detailsBlurStyle == 1;
            final isBaked = isMesh || settingsController.useComputedBlur;
            final blurAmount =
                UISettingsKeys.detailsBlurAmount.get<double>(20.0);
            final brightness =
                UISettingsKeys.detailsBackdropBrightness.get<double>(1.0);
            final media = controller.media.value;
            final posterUrl = media.poster;
            final coverUrl =
                (media.cover?.isNotEmpty == true ? media.cover! : posterUrl);
            final usePoster = settingsController.usePosterForBlur;
            final blurSourceUrl = usePoster ? posterUrl : coverUrl;
            final initialPoster = widget.media.poster;
            final blurFallbackUrl = initialPoster.isNotEmpty
                ? initialPoster
                : (usePoster ? coverUrl : posterUrl);
            final tintBlur = settingsController.tintBlur;
            final colors = themedContext.colors;
            final blurColor = tintBlur ? colors.primary.opaque(0.4) : null;
            final isDark =
                Theme.of(themedContext).brightness == Brightness.dark;
            final baseArtworkColor = tintBlur
                ? colors.primary
                : (AnymeXScaffold.parseColor(_posterColor.value) ??
                    colors.primary);
            final gradientBgColor = Color.alphaBlend(
              baseArtworkColor.withValues(alpha: isDark ? 0.20 : 0.12),
              colors.surface,
            );

            final scrollView = ScrollConfiguration(
              behavior: ScrollConfiguration.of(themedContext)
                  .copyWith(scrollbars: false),
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
                              context: themedContext,
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
                            buildMediaQuickActions(themedContext, controller)
                                .animateSpring(
                                    delay: const Duration(milliseconds: 100)),
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
                      KeepAliveWrapper(child: _buildOverviewTab(themedContext)),
                      KeepAliveWrapper(child: _buildContentTab(themedContext)),
                      KeepAliveWrapper(child: _buildCommentsTab(themedContext)),
                    ],
                  ),
                ),
              ),
            );

            Widget buildBlurredImage({double? height}) {
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

            if (blurScope == 0 || coverUrl.isEmpty) {
              return scrollView;
            }

            if (blurScope == 2) {
              final washHeight = (MediaQuery.sizeOf(themedContext).height * 0.48)
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
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.transparent, width: 2.0),
                        ),
                      ),
                      child: RepaintBoundary(
                        child: buildBlurredImage(height: washHeight),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: washHeight + 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: const Border(
                          bottom: BorderSide(
                              color: Colors.transparent, width: 2.0),
                        ),
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
                  scrollView,
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
                scrollView,
              ],
            );
          }),
        );
      }

      if (posterScheme != null) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: posterScheme),
          child: Builder(builder: (ctx) => buildScaffold(ctx)),
        );
      }
      return buildScaffold(context);
    });
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
          if (selected == 1) _buildContinueButton(context),
          SafeArea(
            child: ResponsiveNavBar(
              isDesktop: false,
              currentIndex: selected,
              margin: EdgeInsets.fromLTRB(
                  32, 0, 32, settingsController.bottomNavBarMargin),
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
                    return KeyedSubtree(
                      key: ValueKey('media_stats_${controller.selectedPage.value}'),
                      child: buildMediaStatsSection(context, controller)
                          .bottomSpacing(16)
                          .animateSection(onScroll: false),
                    );
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    return KeyedSubtree(
                      key: const ValueKey('media_characters'),
                      child: buildCharactersSection(context, mediaData),
                    );
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    if (rels.isEmpty) return const SizedBox.shrink();
                    return KeyedSubtree(
                      key: const ValueKey('media_relations'),
                      child: ReusableCarousel(
                        data: rels,
                        title: 'Relations',
                        variant: DataVariant.relation,
                      ).bottomSpacing(16),
                    );
                  }),
                  Obx(() {
                    if (controller.isSecondaryLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    if (mediaData.staff == null || mediaData.staff!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return KeyedSubtree(
                      key: const ValueKey('media_staff'),
                      child: StaffCarousel(staff: mediaData.staff!)
                          .bottomSpacing(16),
                    );
                  }),
                  Obx(() {
                    if (controller.isAnilistLoading.value) {
                      return _buildShimmerCarousel(context);
                    }
                    final recs = mediaData.recommendations;
                    if (recs.isEmpty) return const SizedBox.shrink();
                    return KeyedSubtree(
                      key: const ValueKey('media_recommendations'),
                      child: ReusableCarousel(
                        data: recs,
                        title: controller.isNovel
                            ? 'Recommended Novels'
                            : (controller.isAnime
                                ? 'Recommended Anime'
                                : 'Recommended Manga'),
                        variant: DataVariant.recommendation,
                        type: controller.isNovel
                            ? ItemType.novel
                            : (controller.isAnime
                                ? ItemType.anime
                                : ItemType.manga),
                      ),
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
    final commentCtrl = _commentController;
    final colorScheme = Theme.of(context).colorScheme;
    final media = controller.media.value;

    final String formatName;
    switch (media.mediaType) {
      case ItemType.anime:
        formatName = 'Anime';
        break;
      case ItemType.novel:
        formatName = 'Novel';
        break;
      default:
        formatName = 'Manga';
        break;
    }

    return CustomScrollView(
      key: const PageStorageKey<String>('Comments'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .opaque(0.25, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (media.poster.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnymeXImage(
                        imageUrl: media.poster,
                        width: 34,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    AnymeXContainer(
                      width: 34,
                      height: 46,
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.forum_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          media.displayTitle.isNotEmpty ? media.displayTitle : 'Comments',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          size: 15,
                          variant: TextVariant.bold,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            AnymeXContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              child: AnymeXText(
                                formatName,
                                size: 10,
                                variant: TextVariant.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final count = commentCtrl.commentCount.value;
                              return AnymeXText(
                                '$count ${count == 1 ? 'comment' : 'comments'}',
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (sort) => commentCtrl.setSort(sort),
                    icon: Icon(
                      Icons.sort_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Sort comments',
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'top',
                        child: Row(
                          children: [
                            if (commentCtrl.currentSort.value == 'top')
                              Icon(Icons.check_rounded,
                                  size: 18, color: colorScheme.primary)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            const AnymeXText('Top comments', maxLines: null),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'newest',
                        child: Row(
                          children: [
                            if (commentCtrl.currentSort.value == 'newest')
                              Icon(Icons.check_rounded,
                                  size: 18, color: colorScheme.primary)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            const AnymeXText('Newest first', maxLines: null),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'oldest',
                        child: Row(
                          children: [
                            if (commentCtrl.currentSort.value == 'oldest')
                              Icon(Icons.check_rounded,
                                  size: 18, color: colorScheme.primary)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            const AnymeXText('Oldest first', maxLines: null),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined, size: 21),
                    onPressed: () => LeaderboardSheet.show(context),
                    tooltip: 'Leaderboard',
                  ),
                  IconButton(
                    icon: const Icon(Icons.assignment_outlined, size: 20),
                    onPressed: () =>
                        showPolicySheet(context, PolicyType.commentRules),
                    tooltip: 'Comment Rules',
                  ),
                  Obx(() => IconButton(
                        icon: commentCtrl.isRefreshing.value
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: commentCtrl.isRefreshing.value
                            ? null
                            : () => commentCtrl.forceRefresh(),
                        tooltip: 'Refresh comments',
                      )),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Obx(() {
            if (!serviceHandler.isLoggedIn.value) {
              return _buildLoginToCommentCard(context);
            }
            return CommentInputBar(
              controller: commentCtrl,
              focusNode: commentCtrl.commentFocusNode,
            );
          }),
        ),
        SliverToBoxAdapter(
          child: CommentSection(
            media: media,
            scrollToCommentId: widget.scrollToCommentId,
            showInlineInput: false,
            showHeader: false,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildLoginToCommentCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AnymeXContainer(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: colorScheme.surfaceContainerHighest.opaque(0.25, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
        width: 1,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnymeXText(
              'Log in to join the conversation and comment.',
              size: 13,
              color: colorScheme.onSurfaceVariant,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => serviceHandler.login(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnymeXText(
                'Log In',
                size: 13,
                variant: TextVariant.semiBold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
      String imageUrl = '';
      double progressVal = 0.0;
      VoidCallback? onTap;

      if (isAnime) {
        final ep = controller.getContinueEpisode();
        if (ep == null) return const SizedBox.shrink();
        final matchedEp = controller.episodeList.firstWhereOrNull((e) =>
            (e.link != null && e.link!.isNotEmpty && e.link == ep.link) ||
            e.isSameEpisode(ep));
        final episodeNumber =
            formatEpisodeNumberLabel(ep.number, title: ep.title);
        final rawEpTitle = (matchedEp?.title?.trim().isNotEmpty == true)
            ? matchedEp!.title!.trim()
            : (ep.title?.trim() ?? '');
        final hasSpecificTitle = rawEpTitle.isNotEmpty &&
            !rawEpTitle.toLowerCase().startsWith('episode');
        titleText = hasSpecificTitle
            ? 'EP $episodeNumber - $rawEpTitle'
            : 'Episode $episodeNumber';
        imageUrl = ep.thumbnail?.isNotEmpty == true
            ? ep.thumbnail!
            : controller.media.value.poster;
        progressVal = controller.getEpisodeProgress(ep);
        onTap = () async {
          HapticFeedback.lightImpact();
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
        final matchedCh = controller.chapterList.firstWhereOrNull((c) =>
            (c.link != null && c.link!.isNotEmpty && c.link == ch.link) ||
            (c.number != null && c.number == ch.number));
        final rawChTitle = (matchedCh?.title?.trim().isNotEmpty == true)
            ? matchedCh!.title!.trim()
            : (ch.title?.trim() ?? '');
        final hasSpecificTitle = rawChTitle.isNotEmpty &&
            !rawChTitle.toLowerCase().startsWith('chapter');
        titleText = hasSpecificTitle
            ? 'CH ${ch.number} - $rawChTitle'
            : 'Chapter ${ch.number}';
        imageUrl = controller.media.value.poster;
        progressVal = controller.getChapterProgress(ch);
        onTap = () async {
          HapticFeedback.lightImpact();
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

            final filteredChapters = controller.currentScanlatorChapters;

            await navigate(() => ReadingPage(
                  anilistData: mediaData,
                  chapterList: filteredChapters,
                  currentChapter: ch,
                  shouldTrack: shouldTrackValue,
                ));
            controller.refreshProgress();
          }
        };
      }

      final clampedProgress = progressVal.clamp(0.0, 1.0);
      final theme = Theme.of(context);

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 52,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer
                    .opaque(0.4, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(24.multiplyRadius()),
                border: Border.all(
                  color: theme.colorScheme.outline
                      .opaque(0.12, iReallyMeanIt: true),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.opaque(0.12, iReallyMeanIt: true),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 38,
                      child: AnymeXImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        radius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          titleText,
                          size: 11.5,
                          variant: TextVariant.semiBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          isMarquee: true,
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: AnymeXLinearIndicator(
                            value: clampedProgress > 0 ? clampedProgress : 0.05,
                            minHeight: 8,
                            color: theme.colorScheme.primary,
                            backgroundColor:
                                theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.opaque(0.9),
                        borderRadius:
                            BorderRadius.circular(32.multiplyRadius()),
                      ),
                      child: Icon(
                        isAnime
                            ? Icons.play_arrow_rounded
                            : Icons.menu_book_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
