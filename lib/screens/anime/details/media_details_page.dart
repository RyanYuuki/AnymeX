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
  late final RxString _posterColor;
  bool _isRouteAnimating = true;

  static final Map<String, ColorScheme> _posterSchemeCache = {};
  static ColorScheme? _getPosterScheme(Color? seed, Brightness brightness) {
    if (seed == null) return null;
    final key = '${seed.value}_${brightness.name}';
    return _posterSchemeCache.putIfAbsent(
      key,
      () => ColorScheme.fromSeed(brightness: brightness, seedColor: seed),
    );
  }

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

  String? _lastExtractedUrl;
  Worker? _mediaColorWorker;

  void _resolveDynamicColor(Media media, {bool allowExtract = false}) {
    final usePoster = settingsController.usePosterForBlur;
    final targetUrl = usePoster
        ? media.poster
        : (media.cover?.isNotEmpty == true ? media.cover! : '');

    if (usePoster && _posterColor.value.isEmpty && media.color.isNotEmpty) {
      _posterColor.value = media.color;
    }

    if (targetUrl.isEmpty) {
      if (!usePoster && _posterColor.value.isNotEmpty) {
        _posterColor.value = '';
      }
      return;
    }

    final cached = ImageColorExtractor.getCachedColor(targetUrl);
    if (cached != null) {
      final hex = '#${cached.value.toRadixString(16).padLeft(8, '0')}';
      if (_posterColor.value != hex) {
        _posterColor.value = hex;
      }
      _lastExtractedUrl = targetUrl;
      return;
    }

    if (!allowExtract || _isRouteAnimating || _lastExtractedUrl == targetUrl) {
      return;
    }

    _lastExtractedUrl = targetUrl;
    ImageColorExtractor.extractColor(targetUrl).then((c) {
      if (c != null && mounted) {
        _posterColor.value = '#${c.value.toRadixString(16).padLeft(8, '0')}';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final usePoster = settingsController.usePosterForBlur;
    _posterColor = (usePoster && widget.media.color.isNotEmpty
            ? widget.media.color
            : '')
        .obs;
    _resolveDynamicColor(widget.media, allowExtract: false);
    final initialPage = widget.scrollToCommentId != null
        ? 2
        : widget.initialTabIndex;
    controller = Get.put(
      MediaDetailsController(
        initialMedia: widget.media,
        tag: widget.tag,
        initialSource: widget.source,
        initialTabIndex: initialPage,
      ),
      tag: widget.tag,
    );
    _mediaColorWorker = ever(controller.media, (m) {
      if (!_isRouteAnimating) {
        _resolveDynamicColor(m, allowExtract: true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          _isRouteAnimating = false;
          _resolveDynamicColor(controller.media.value, allowExtract: true);
          if (mounted) setState(() {});
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _isRouteAnimating = false);
              _resolveDynamicColor(controller.media.value, allowExtract: true);
            }
          });
        }
      } else {
        _isRouteAnimating = false;
        _resolveDynamicColor(controller.media.value, allowExtract: true);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _mediaColorWorker?.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentMedia = controller.media.value;
      if (!_isRouteAnimating && _lastExtractedUrl == null) {
        _resolveDynamicColor(currentMedia, allowExtract: true);
      }

      final activeColor = _posterColor.value.isNotEmpty
          ? _posterColor.value
          : (settingsController.usePosterForBlur ? currentMedia.color : '');
      final posterSeed =
          (activeColor.isNotEmpty && settingsController.usePosterColor)
              ? AnymeXScaffold.parseColor(activeColor)
              : null;
      final posterScheme = posterSeed != null
          ? _getPosterScheme(posterSeed, Theme.of(context).brightness)
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
                (media.cover?.isNotEmpty == true ? media.cover! : '');
            final usePoster = settingsController.usePosterForBlur;
            final blurSourceUrl = usePoster ? posterUrl : coverUrl;
            final blurFallbackUrl = usePoster ? posterUrl : '';
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
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
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
                    Obx(() {
                      final selected = controller.selectedPage.value;
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverVisibility(
                            visible: selected == 0,
                            maintainState: true,
                            sliver: _buildOverviewTab(themedContext),
                          ),
                          SliverVisibility(
                            visible: selected == 1,
                            maintainState: true,
                            sliver: _buildContentTab(themedContext),
                          ),
                          SliverVisibility(
                            visible: selected == 2,
                            maintainState: true,
                            sliver: _buildCommentsTab(themedContext),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );

            Widget buildBlurredImage({double? height}) {
              if (blurSourceUrl.isEmpty || _isRouteAnimating) {
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

            if (blurScope == 0) {
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: selected == 1
                ? _buildContinueButton(context)
                : const SizedBox.shrink(),
          ),
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

      return SliverMainAxisGroup(
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
                      key: const ValueKey('media_stats'),
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
      return SliverMainAxisGroup(
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

    return SliverMainAxisGroup(
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

    return SliverMainAxisGroup(
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
