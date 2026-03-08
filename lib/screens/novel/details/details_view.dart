import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/novel/details/controller/details_controller.dart';
import 'package:anymex/screens/novel/details/widgets/chapters_section.dart';
import 'package:anymex/screens/novel/details/widgets/novel_stats.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/gradient_image.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class NovelDetailsPage extends StatefulWidget {
  final Media media;
  final Source source;
  final String tag;
  const NovelDetailsPage(
      {super.key,
      required this.media,
      required this.source,
      required this.tag});

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage> {
  late NovelDetailsController controller;
  late final PageController pageController;
  final RxInt selectedPage = 0.obs;

  void _onPageSelected(int index) {
    selectedPage.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  initState() {
    super.initState();
    pageController = PageController();
    controller = Get.put(NovelDetailsController(
        source: widget.source, initialMedia: widget.media));

    final novel =
        controller.offlineStorage.getNovelById(controller.initialMedia.id);
    if (novel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.offlineMedia.value = novel;
        controller.offlineMedia.refresh();
      });
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    controller.dispose();
    Get.delete<NovelDetailsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuilder(
      androidBuilder: _buildAndroidLayout(context),
      desktopBuilder: _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopNav(),
            Expanded(child: _commonLayout(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidLayout(BuildContext context) {
    return Glow(
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: _buildMobiledNav(),
        body: _commonLayout(context),
      ),
    );
  }

  Widget _commonLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GradientPoster(
            data: widget.media,
            tag: widget.tag,
            posterUrl: widget.media.poster,
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: 400,
                child: Center(child: AnymexProgressIndicator()),
              ),
            );
          }

          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildAddToLibraryButton(context),
                ),
              ),
              if (controller.offlineMedia.value != null &&
                  controller.offlineMedia.value?.currentChapter != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _buildContinueButton(context),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: _buildProgressContainer(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: 10.height()),
              SliverToBoxAdapter(child: _buildTabContent(context)),
              SliverToBoxAdapter(child: 150.height()),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Obx(() {
      return ExpandablePageView(
        controller: pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          selectedPage.value = index;
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
            child: NovelStats(data: controller.media.value),
          ),
          ChapterSliverSection(controller: controller),
          CommentSection(
            media: controller.media.value,
          ),
        ],
      );
    });
  }

  Widget _buildDesktopNav() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(20),
          width: 85,
          height: 300,
          child: Column(
            children: [
              Container(
                width: 70,
                height: 65,
                padding: const EdgeInsets.all(0),
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 0,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.onSurface.opaque(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(
                      20.multiplyRadius(),
                    )),
                child: NavBarItem(
                    isSelected: false,
                    isVertical: true,
                    onTap: () {
                      Get.back();
                    },
                    selectedIcon: Iconsax.back_square,
                    unselectedIcon: IconlyBold.arrow_left,
                    label: "Back"),
              ),
              const SizedBox(height: 10),
              ResponsiveNavBar(
                  isDesktop: true,
                  currentIndex: selectedPage.value,
                  borderRadius: BorderRadius.circular(20),
                  items: [
                    NavItem(
                        onTap: _onPageSelected,
                        selectedIcon: Iconsax.info_circle5,
                        unselectedIcon: Iconsax.info_circle,
                        label: "Info"),
                    NavItem(
                        onTap: _onPageSelected,
                        selectedIcon: Iconsax.book,
                        unselectedIcon: Iconsax.book,
                        label: "Read"),
                    NavItem(
                        onTap: _onPageSelected,
                        selectedIcon: HugeIcons.strokeRoundedComment01,
                        unselectedIcon: HugeIcons.strokeRoundedComment02,
                        label: "Comments"),
                  ]),
            ],
          ),
        ));
  }

  Widget _buildMobiledNav() {
    return Obx(() => ResponsiveNavBar(
            isDesktop: false,
            currentIndex: selectedPage.value,
            margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            items: [
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: Iconsax.info_circle5,
                  unselectedIcon: Iconsax.info_circle,
                  label: "Info"),
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: Iconsax.book,
                  unselectedIcon: Iconsax.book,
                  label: "Read"),
              NavItem(
                  onTap: _onPageSelected,
                  selectedIcon: HugeIcons.strokeRoundedComment01,
                  unselectedIcon: HugeIcons.strokeRoundedComment02,
                  label: "Comments"),
            ]));
  }

  Widget _buildAddToLibraryButton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colors.outline.opaque(0.2),
              ),
              color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showCustomListDialog(context, controller.media.value);
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedLibrary,
                      color: context.colors.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Library',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String formatProgress({
    required dynamic currentChapter,
    required dynamic totalChapters,
    required dynamic altLength,
  }) {
    num parseNum(dynamic value) {
      if (value == null) return 1;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 1;
      return 1;
    }

    final num current = parseNum(currentChapter);
    final num total = parseNum(totalChapters) != 1
        ? parseNum(totalChapters)
        : parseNum(altLength);

    final num safeTotal = total.clamp(1, double.infinity);
    final progress = (current / safeTotal) * 100;
    if (progress.toString().length > 5) return progress.toStringAsFixed(3);
    return progress.toStringAsFixed(2);
  }

  Widget _buildProgressContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colors.surfaceContainer.opaque(0.3),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.book_1,
            color: context.colors.onSurface.opaque(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnymexTextSpans(
              fontSize: 14,
              spans: [
                AnymexTextSpan(
                  text: "Chapter ",
                  color: context.colors.onSurface.opaque(0.7),
                ),
                AnymexTextSpan(
                  text: controller.offlineMedia.value?.currentChapter?.number
                          .toString() ??
                      '1',
                  variant: TextVariant.bold,
                  color: context.colors.primary,
                ),
                AnymexTextSpan(
                  text: ' of ',
                  color: context.colors.onSurface.opaque(0.7),
                ),
                AnymexTextSpan(
                  text: controller.media.value.totalChapters ??
                      controller.media.value.totalEpisodes,
                  variant: TextVariant.bold,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.colors.primary.opaque(0.1),
            ),
            child: Text(
              '${formatProgress(currentChapter: controller.offlineMedia.value?.currentChapter?.number ?? 1, totalChapters: controller.offlineMedia.value?.totalChapters, altLength: controller.media.value.altMediaContent?.length)}%',
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Obx(() {
      final progress = _calculateProgress();
      final currentChapter =
          controller.offlineMedia.value?.currentChapter?.number ?? 1;
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.outline.opaque(0.2),
          ),
          color: context.colors.primary.opaque(0.5),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.opaque(0.1),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.opaque(0.2),
                      Colors.white.opaque(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.goToReader(
                      controller.offlineMedia.value!.currentChapter!);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.play,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continue Reading',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chapter $currentChapter',
                              style: TextStyle(
                                color: Colors.white.opaque(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  double _calculateProgress() {
    final savedChapter = controller.offlineMedia.value?.currentChapter;
    if (savedChapter?.currentOffset == null ||
        savedChapter?.maxOffset == null) {
      return 0;
    }
    final progress = savedChapter!.currentOffset! / savedChapter.maxOffset!;
    return progress;
  }
}
