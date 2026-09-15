import 'dart:math' as math;

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
// import 'package:anymex/screens/library/widgets/library_header.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';

import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:anymex/controllers/media_mode_controller.dart';

class MyLibrary extends StatefulWidget {
  final ItemType? type;
  const MyLibrary({super.key, this.type});

  @override
  State<MyLibrary> createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);
  late Worker _mediaModeWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final mediaModeController = Get.put(MediaModeController());
    final libraryController = Get.put(LibraryController());

    libraryController.switchCategory(mediaModeController.mode);
    _mediaModeWorker = ever(mediaModeController.rxMode, (ItemType type) {
      libraryController.switchCategory(type);
    });
  }

  @override
  void didUpdateWidget(MyLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != null && widget.type != oldWidget.type) {
      Get.find<LibraryController>().switchCategory(widget.type!);
    }
  }

  @override
  void dispose() {
    _mediaModeWorker.dispose();
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<LibraryController>();
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final settings = Get.find<Settings>();

    return Obx(() {
      final isLegacy = settings.useLegacyNavbar;
      final double extraHeight = isDesktop
          ? 100.0
          : (isLegacy ? 96.0 : 60.0);
      final double topOffset = statusBarHeight + appBarHeight + extraHeight;

      return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: topOffset,
                  ),
                ),
                _LibraryContent(controller: controller),
              ],
            ),
            CustomAnimatedAppBar(
              isVisible: _isAppBarVisibleExternally,
              scrollController: _scrollController,
              headerContent: Obx(
                () => Header(
                  title: 'Library',
                  subtitle: 'All your local shi',
                  isSearchActive: controller.isSearchActive.value,
                  searchBar: HeaderSearchBar(
                    controller: controller.searchController,
                    onChanged: controller.search,
                    onClose: controller.toggleSearch,
                    hintText: 'Search in Library...',
                  ),
                  actions: [
                    HeaderActionButton(
                      icon: IconlyLight.search,
                      onTap: controller.toggleSearch,
                    ),
                    2.width(),
                    HeaderActionButton(
                      icon: Icons.sort_rounded,
                      onTap: () => showLibrarySortSheet(context, controller),
                    ),
                  ],
                  bottom: isLegacy
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LibrarySegmentedControl(controller: controller),
                            const SizedBox(height: 2),
                            ChipTabs(controller: controller),
                          ],
                        )
                      : ChipTabs(controller: controller),
                ),
              ),
              visibleStatusBarStyle: SystemUiOverlayStyle(
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
                statusBarBrightness: Theme.of(context).brightness,
                statusBarColor: Colors.transparent,
              ),
              hiddenStatusBarStyle: SystemUiOverlayStyle(
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.light
                        : Brightness.dark,
                statusBarBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
                statusBarColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LibraryContent extends StatelessWidget {
  final LibraryController controller;

  const _LibraryContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.rawItems.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final data = controller.processedItems;
      if (data.isEmpty) {
        return const SliverToBoxAdapter(child: EmptyLibrary());
      }

      if (controller.selectedListIndex.value == -1) {
        return _buildHistoryView(context, data);
      } else {
        return _buildGridView(context, data);
      }
    });
  }

  Widget _buildHistoryView(BuildContext context, List<OfflineMedia> data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 130),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisVal(
            MediaQuery.sizeOf(context).width - 120,
            itemWidth: 400,
          ),
          crossAxisSpacing: 10,
          mainAxisSpacing: 0,
          mainAxisExtent: getHistoryCardHeight(
            HistoryCardStyle.values[settingsController.historyCardStyle],
            context,
          ),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final historyModel = HistoryModel.fromOfflineMedia(
              data[i],
              controller.type.value,
            );
            return HistoryCardGate(
              data: historyModel,
              cardStyle:
                  HistoryCardStyle.values[settingsController.historyCardStyle],
            );
          },
          childCount: data.length,
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<OfflineMedia> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      sliver: SliverGrid(
        gridDelegate: _getSliverDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            OfflineMedia item = items[i];
            final tag =
                '${item.mediaId ?? item.id}-library-grid-${controller.type.value.name}';
            return AnymexOnTap(
              margin: 0,
              scale: 1,
              onTap: () => _handleItemTap(context, item, items, i, tag),
              child: MediaCardGate(
                itemData: items[i],
                tag: tag,
                variant: DataVariant.library,
                type: controller.type.value,
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _getSliverDelegate(
      BuildContext context) {
    if (controller.gridCount.value == 0) {
      const horizontalPadding = 32.0;
      const crossAxisSpacing = 10.0;
      final availableWidth =
          MediaQuery.sizeOf(context).width - horizontalPadding;
      final isDesktop = getPlatform(context);
      final itemWidth = isDesktop ? 170.0 : 140.0;

      final crossAxisCount = math.max(
        1,
        ((availableWidth + crossAxisSpacing) / (itemWidth + crossAxisSpacing))
            .floor(),
      );

      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: 20,
        childAspectRatio: getGridCardAspectRatio(
          context: context,
          crossAxisCount: crossAxisCount,
          spacing: crossAxisSpacing,
          padding: horizontalPadding,
        ),
      );
    }

    final crossCount = math.max(1, controller.gridCount.value);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      crossAxisSpacing: 0,
      mainAxisSpacing: 10,
      childAspectRatio: getGridCardAspectRatio(
        context: context,
        crossAxisCount: crossCount,
        spacing: 0,
        padding: 32.0,
      ),
    );
  }

  void _handleItemTap(BuildContext context, OfflineMedia item,
      List<OfflineMedia> items, int index, String tag) {
    if (controller.type.value.isAnime) {
      navigateWithAnimation(() => AnimeDetailsPage(
          media: Media.fromOfflineMedia(item, ItemType.anime), tag: tag));
    } else if (controller.type.value.isManga) {
      navigateWithAnimation(() => MangaDetailsPage(
          media: Media.fromOfflineMedia(item, ItemType.manga), tag: tag));
    } else {
      final sourceName = item.season ?? '';
      final source = sourceName.isNotEmpty
          ? sourceController.getNovelExtensionByName(sourceName)
          : null;

      navigateWithAnimation(() => NovelDetailsPage(
          source: source,
          media: Media.fromOfflineMedia(items[index], ItemType.novel),
          tag: tag));
    }
  }
}
