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
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/services.dart';

class MyLibrary extends StatefulWidget {
  const MyLibrary({super.key});

  @override
  State<MyLibrary> createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.put(LibraryController());
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight + 20;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: statusBarHeight + appBarHeight,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: LibrarySegmentedControl(controller: controller),
                ),
              ),
              SliverToBoxAdapter(
                child: ChipTabs(controller: controller),
              ),
              _LibraryContent(controller: controller),
            ],
          ),
          CustomAnimatedAppBar(
            isVisible: _isAppBarVisibleExternally,
            scrollController: _scrollController,
            headerContent: const Header(type: PageType.library),
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
  }
}

class _LibraryContent extends StatelessWidget {
  final LibraryController controller;

  const _LibraryContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedListIndex.value == -1) {
        return _buildHistoryView(context);
      } else {
        return _buildCustomListView(context);
      }
    });
  }

  Widget _buildCustomListView(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: controller.getCustomListNames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final listNames = snapshot.data!;
        if (listNames.isEmpty ||
            controller.selectedListIndex.value >= listNames.length) {
          return const SliverToBoxAdapter(child: EmptyLibrary());
        }

        final selectedListName = listNames[controller.selectedListIndex.value];

        return Obx(() {
          return StreamBuilder<List<OfflineMedia>>(
            stream: controller.getProcessedCustomListStream(
                selectedListName, controller.type.value),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              var items = snapshot.data!;

              if (items.isEmpty) {
                return const SliverToBoxAdapter(child: EmptyLibrary());
              }

              return _buildGridView(context, items);
            },
          );
        });
      },
    );
  }

  Widget _buildHistoryView(BuildContext context) {
    return Obx(() {
      return StreamBuilder<List<OfflineMedia>>(
        stream: controller.getHistoryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          var data = snapshot.data!;

          if (data.isEmpty) {
            return const SliverToBoxAdapter(child: EmptyLibrary());
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 130),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getResponsiveCrossAxisVal(
                  MediaQuery.of(context).size.width - 120,
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
                    cardStyle: HistoryCardStyle
                        .values[settingsController.historyCardStyle],
                  );
                },
                childCount: data.length,
              ),
            ),
          );
        },
      );
    });
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
                cardStyle: CardStyle.values[settingsController.cardStyle],
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
          MediaQuery.of(context).size.width - horizontalPadding;
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
        childAspectRatio: 2 / 3,
      );
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: math.max(1, controller.gridCount.value),
      crossAxisSpacing: 0,
      mainAxisSpacing: 10,
      childAspectRatio: 2 / 3,
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
      final source =
          sourceController.getNovelExtensionByName(item.season ?? '');
      if (source == null) {
        errorSnackBar('Install ${item.season} extension');
        return;
      }

      navigateWithAnimation(() => NovelDetailsPage(
          source: source,
          media: Media.fromOfflineMedia(items[index], ItemType.novel),
          tag: tag));
    }
  }
}
