import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/library/widgets/anime_card.dart';
import 'package:anymex/screens/library/widgets/common_widgets.dart';
import 'package:anymex/screens/library/widgets/manga_card.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/anymex_segmented_button.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class MyLibrary extends StatefulWidget {
  const MyLibrary({super.key});

  @override
  State<MyLibrary> createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary> {
  final TextEditingController controller = TextEditingController();
  final offlineStorage = Get.find<OfflineStorageController>();

  // Anime data
  RxList<CustomListData> customListData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredData = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyData = <OfflineMedia>[].obs;

  // Manga data
  RxList<CustomListData> customListDataManga = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredDataManga = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyDataManga = <OfflineMedia>[].obs;

  RxString searchQuery = ''.obs;
  RxInt selectedListIndex = 0.obs;
  RxBool isAnimeSelected = true.obs;

  final cardType = 0.obs;

  @override
  void initState() {
    super.initState();
    final handler = Get.find<ServiceHandler>();

    // Initialize anime data
    customListData.value = offlineStorage.animeCustomListData
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData
                  .where((item) =>
                      item.serviceIndex == handler.serviceType.value.index)
                  .toList(),
            ))
        .toList();

    historyData.value = offlineStorage.animeLibrary
        .where((e) =>
            e.currentEpisode?.currentTrack != null &&
            e.serviceIndex == handler.serviceType.value.index)
        .toList();

    customListDataManga.value = offlineStorage.mangaCustomListData
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData
                  .where((item) =>
                      item.serviceIndex == handler.serviceType.value.index)
                  .toList(),
            ))
        .toList();

    historyDataManga.value = offlineStorage.mangaLibrary
        .where((e) =>
            e.currentChapter?.currentOffset != null &&
            e.serviceIndex == handler.serviceType.value.index)
        .toList();
  }

  void _search(String val) {
    searchQuery.value = val;
    final currentIndex = selectedListIndex.value;

    if (isAnimeSelected.value) {
      final initialData = customListData[currentIndex].listData;
      filteredData.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else {
      final initialData = customListDataManga[currentIndex].listData;
      filteredDataManga.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    }
  }

  void _switchCategory(bool isAnime) {
    if (isAnimeSelected.value != isAnime) {
      isAnimeSelected.value = isAnime;
      selectedListIndex.value = 0;

      if (searchQuery.isNotEmpty) {
        controller.clear();
        searchQuery.value = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Glow(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        // CustomSearchBar(
                        //   onSubmitted: (val) {},
                        //   onChanged: _search,
                        //   controller: controller,
                        //   disableIcons: true,
                        //   suffixWidget: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //         horizontal: 10, vertical: 3),
                        //     decoration: BoxDecoration(
                        //       color: Theme.of(context).colorScheme.primary,
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //     child: AnymexText(
                        //         text: isSimkl ? "SERIES" : "MANGA",
                        //         variant: TextVariant.bold,
                        //         color: Theme.of(context).colorScheme.onPrimary),
                        //   ),
                        // ),

                        _buildHeader(),

                        // List Chips
                        _buildChipTabs(),

                        // Content Grid
                        _buildTabsBody(),
                      ],
                    ),
                  ),

                  // Only for desktop
                  getResponsiveValueWithTablet(context,
                      tabletValue: const SizedBox.shrink(),
                      mobileValue: const SizedBox.shrink(),
                      desktopValue: Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        padding: const EdgeInsets.only(top: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_outlined,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'History',
                                    style: TextStyle(
                                      fontFamily: "Poppins-Bold",
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Expanded(
                              child: Obx(() {
                                final historyItems = isAnimeSelected.value
                                    ? historyData
                                    : historyDataManga;

                                return historyItems.isEmpty
                                    ? const EmptyLibrary(
                                        isHistory: true,
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount: historyItems.length,
                                        itemBuilder: (context, index) =>
                                            isAnimeSelected.value
                                                ? AnimeHistoryCard(
                                                    data: historyItems[index],
                                                  )
                                                : MangaHistoryCard(
                                                    data: historyItems[index]));
                              }),
                            ),
                          ],
                        ),
                      ))
                ],
              ),
            ),
          ),
        ));
  }

  int getGridCount() {
    switch (cardType.value) {
      case 0:
        return 2;
      case 1:
        return 3;
      default:
        return 3;
    }
  }

  double getCardHeight() {
    switch (cardType.value) {
      case 0:
        return 280;
      case 1:
        return 210;
      default:
        return 190;
    }
  }

  Expanded _buildTabsBody() {
    return Expanded(
      child: Obx(() {
        final currentIndex = selectedListIndex.value;
        final lists =
            isAnimeSelected.value ? customListData : customListDataManga;

        final isEmpty = lists.isEmpty || lists[currentIndex].listData.isEmpty;

        final items = searchQuery.isNotEmpty
            ? (isAnimeSelected.value ? filteredData : filteredDataManga)
            : (lists.isEmpty ? [] : lists[currentIndex].listData);
        final cardHeight = getResponsiveSize(context,
            mobileSize: getCardHeight(), dektopSize: 290);
        final gridCount = getResponsiveValue(context,
            mobileValue: getGridCount(),
            desktopValue: getResponsiveCrossAxisVal(
                MediaQuery.of(context).size.width,
                itemWidth: 220));

        return isEmpty
            ? const EmptyLibrary()
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: cardHeight),
                itemBuilder: (context, i) {
                  return MediaCard(
                    cardType: cardType,
                    isManga: !isAnimeSelected.value,
                    data: items[i],
                  );
                },
                itemCount: items.length,
              );
      }),
    );
  }

  Padding _buildChipTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final lists =
              isAnimeSelected.value ? customListData : customListDataManga;

          return Row(
            children: List.generate(
              lists.length,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnymexChip(
                  label: lists[index].listName,
                  isSelected: selectedListIndex.value == index,
                  onSelected: (selected) {
                    if (selected) {
                      selectedListIndex.value = index;
                      if (searchQuery.isNotEmpty) {
                        controller.clear();
                        searchQuery.value = '';
                      }
                    }
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Container _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnymexText(
                    text: 'Library',
                    size: 28,
                    variant: TextVariant.bold,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your personal collection of stories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.sort,
                    ),
                  ),
                  IconButton(
                    onPressed: showSettings,
                    icon: const Icon(
                      Icons.settings_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _switchCategory(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isAnimeSelected.value
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAnimeSelected.value
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            color: isAnimeSelected.value
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Anime',
                            style: TextStyle(
                              fontFamily: "Poppins-Bold",
                              fontSize: 16,
                              color: isAnimeSelected.value
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _switchCategory(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isAnimeSelected.value
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isAnimeSelected.value
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            color: !isAnimeSelected.value
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Manga',
                            style: TextStyle(
                              fontFamily: "Poppins-Bold",
                              fontSize: 16,
                              color: !isAnimeSelected.value
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSettings() => AnymexSheet.show(
      context: context,
      title: 'Settings',
      contentWidget: Column(
        children: [
          const CustomTile(
              icon: Icons.grid_view_rounded,
              title: "Grid Items/Row",
              postFix: SizedBox.shrink(),
              description: 'Increase/decrease grid items count'),
          10.height(),
          Obx(() {
            return Row(
              children: [
                AnymexSegmentedButton(
                  isSelected: cardType.value == 0,
                  onTap: () {
                    cardType.value = 0;
                  },
                  title: '2',
                  icon: HugeIcons.strokeRoundedGrid,
                ),
                5.width(),
                AnymexSegmentedButton(
                  isSelected: cardType.value == 1,
                  title: '3',
                  icon: HugeIcons.strokeRoundedGrid,
                  onTap: () {
                    cardType.value = 1;
                  },
                ),
              ],
            );
          }),
          20.height()
        ],
      ));
}
